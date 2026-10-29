<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\ExchangeResource;
use App\Http\Resources\ItemResource;
use App\Http\Resources\RatingResource;
use App\Models\Exchange;
use App\Models\Item;
use App\Services\ExchangeService;
use App\Services\PhotoStorage;
use App\Support\Rules;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Throwable;

/** "Give Away" posts, their photos, and the handover steps for each post. */
class ItemController extends Controller
{
    public function __construct(private readonly ExchangeService $exchanges) {}

    /**
     * Feed (newest first, paged with limit/offset; optional category,
     * district and q filters), or one donor's posts with ?donor_id=.
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        $request->validate([
            'limit' => ['nullable', 'integer', 'min:1', 'max:'.config('shareloop.max_page_size')],
            'offset' => ['nullable', 'integer', 'min:0'],
            'donor_id' => ['nullable', 'string'],
            'category' => ['nullable', 'string'],
            'district' => ['nullable', 'string'],
            'q' => ['nullable', 'string', 'max:100'],
        ]);
        $viewer = $request->user();
        $query = Item::query()->with(['donor', 'selectedRequest']);

        if ($request->filled('donor_id')) {
            $query->where('donor_id', $request->input('donor_id'))->visibleTo($viewer)->limit(100);
        } else {
            $query->where('is_hidden', false)
                ->offset((int) $request->input('offset', 0))
                ->limit((int) $request->input('limit', config('shareloop.page_size')));
        }
        if ($request->filled('category')) {
            $query->where('category', $request->input('category'));
        }
        if ($request->filled('district')) {
            $query->where('district', $request->input('district'));
        }
        if ($request->filled('q')) {
            $term = '%'.str_replace(['%', '_'], ['\%', '\_'], mb_strtolower($request->input('q'))).'%';
            $query->where(fn ($q) => $q->whereRaw('LOWER(title) LIKE ?', [$term])
                ->orWhereRaw('LOWER(description) LIKE ?', [$term]));
        }

        return ItemResource::collection($query->orderByDesc('created_at')->orderByDesc('id')->get());
    }

    public function show(Request $request, string $id): ItemResource
    {
        return new ItemResource($this->visibleItem($request, $id));
    }

    public function store(Request $request): JsonResponse
    {
        $photos = config('shareloop.photos');
        $data = $request->validate([
            'title' => ['required', 'string', 'max:120', 'not_regex:/^\s*$/'],
            'description' => ['required', 'string', 'max:2000', 'not_regex:/^\s*$/'],
            'condition' => ['required', 'string', Rule::in(config('shareloop.conditions'))],
            'category' => Rules::activeCategory(),
            'district' => Rules::district(),
            'city' => Rules::city(),
            'photos' => ['nullable', 'array', 'max:'.$photos['max_per_item']],
            'photos.*' => ['file', 'image', 'mimes:'.implode(',', $photos['mimes']), 'max:'.$photos['max_kilobytes']],
        ], Rules::messages());

        $me = $request->user();
        $stored = [];
        try {
            foreach ($request->file('photos', []) as $file) {
                $stored[] = PhotoStorage::store($file, $me->id);
            }
            $item = Item::create([
                'donor_id' => $me->id,
                'title' => trim($data['title']),
                'description' => trim($data['description']),
                'condition' => $data['condition'],
                'category' => $data['category'],
                'district' => $data['district'],
                'city' => trim($data['city'] ?? ''),
                'image_paths' => $stored,
            ]);
        } catch (Throwable $e) {
            // Don't leave orphaned photos behind when publishing fails.
            PhotoStorage::delete($stored);
            throw $e;
        }

        return (new ItemResource($item->fresh(['donor', 'selectedRequest'])))
            ->response()->setStatusCode(201);
    }

    /** Requests for the item go with it; not allowed while a handover is underway. */
    public function destroy(Request $request, string $id): JsonResponse
    {
        $me = $request->user();
        $paths = DB::transaction(function () use ($me, $id) {
            $item = Item::query()->lockForUpdate()->find($id);
            if ($item === null || ! $item->isVisibleTo($me)) {
                abort(404, 'Item not found.');
            }
            if (! $me->isAdmin()) {
                if ($item->donor_id !== $me->id) {
                    abort(403, 'You can only delete your own posts.');
                }
                if ($item->status === Item::STATUS_PENDING_HANDOVER) {
                    abort(409, "This post can't be deleted while a handover is in progress.");
                }
            }
            $paths = $item->image_paths ?? [];
            $item->forceFill(['selected_request_id' => null])->save();
            $item->requests()->delete();
            $item->delete();

            return $paths;
        });
        PhotoStorage::delete($paths);

        return response()->json(['message' => 'Post deleted.']);
    }

    /** The live exchange for the item, if the caller is part of it (else null). */
    public function exchange(Request $request, string $id): JsonResponse
    {
        $me = $request->user();
        $exchange = Exchange::query()
            ->where('item_id', $id)
            ->where('status', '!=', Exchange::STATUS_CANCELLED)
            ->latest()
            ->first();
        if ($exchange === null || (! $exchange->involves($me) && ! $me->isAdmin())) {
            return response()->json(['data' => null]);
        }

        return (new ExchangeResource($exchange))->response();
    }

    public function confirmHandover(Request $request, string $id): ExchangeResource
    {
        return new ExchangeResource($this->exchanges->confirmHandover($request->user(), $id));
    }

    public function cancelExchange(Request $request, string $id): ExchangeResource
    {
        return new ExchangeResource($this->exchanges->cancel($request->user(), $id));
    }

    public function rate(Request $request, string $id): JsonResponse
    {
        $data = $request->validate([
            'stars' => ['required', 'integer', 'min:1', 'max:5'],
            'comment' => ['nullable', 'string', 'max:1000'],
        ]);
        $rating = $this->exchanges->rate($request->user(), $id, (int) $data['stars'], $data['comment'] ?? '');

        return (new RatingResource($rating))->response()->setStatusCode(201);
    }

    private function visibleItem(Request $request, string $id): Item
    {
        $item = Item::query()->with(['donor', 'selectedRequest'])->find($id);
        if ($item === null || ! $item->isVisibleTo($request->user())) {
            abort(404, 'Item not found.');
        }

        return $item;
    }
}
