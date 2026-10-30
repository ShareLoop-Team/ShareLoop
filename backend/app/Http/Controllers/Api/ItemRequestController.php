<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\ExchangeResource;
use App\Http\Resources\ItemRequestResource;
use App\Models\Item;
use App\Models\ItemRequest;
use App\Services\ExchangeService;
use App\Support\Rules;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\DB;

/** Standalone needs and requests for specific give-away posts. */
class ItemRequestController extends Controller
{
    public function __construct(private readonly ExchangeService $exchanges) {}

    /** Requests the caller may see, newest first; filter with item_id / requester_id. */
    public function index(Request $request): AnonymousResourceCollection
    {
        $query = ItemRequest::query()
            ->with('requester')
            ->visibleTo($request->user())
            ->where('is_hidden', false);
        if ($request->filled('item_id')) {
            $query->where('item_id', $request->input('item_id'));
        }
        if ($request->filled('requester_id')) {
            $query->where('requester_id', $request->input('requester_id'));
        }

        return ItemRequestResource::collection(
            $query->orderByDesc('created_at')->orderByDesc('id')
                ->limit(config('shareloop.request_list_limit'))->get()
        );
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'item_id' => ['nullable', 'string'],
            'item_name' => ['required_without:item_id', 'nullable', 'string', 'max:120'],
            'description' => ['required', 'string', 'max:2000', 'not_regex:/^\s*$/'],
            'reason' => ['required', 'string', 'max:1000', 'not_regex:/^\s*$/'],
            'notes' => ['nullable', 'string', 'max:1000'],
            'category' => Rules::activeCategory(),
            'district' => Rules::district(),
            'city' => Rules::city(),
        ], Rules::messages() + ['item_name.required_without' => 'Say which item you need.']);
        $me = $request->user();

        $itemRequest = DB::transaction(function () use ($data, $me) {
            if (! empty($data['item_id'])) {
                $item = Item::query()->lockForUpdate()->find($data['item_id']);
                if ($item === null || $item->is_hidden) {
                    abort(404, 'Item not found.');
                }
                if ($item->donor_id === $me->id) {
                    abort(422, 'You cannot request your own item.');
                }
                if ($item->status !== Item::STATUS_ACTIVE) {
                    abort(409, 'This item is no longer available.');
                }
                $duplicate = ItemRequest::query()
                    ->where('item_id', $item->id)->where('requester_id', $me->id)->exists();
                if ($duplicate) {
                    abort(409, 'You have already requested this item.');
                }
            }

            try {
                return ItemRequest::create([
                    'requester_id' => $me->id,
                    'item_id' => $data['item_id'] ?? null,
                    'item_name' => trim($data['item_name'] ?? ''),
                    'description' => trim($data['description']),
                    'reason' => trim($data['reason']),
                    'notes' => trim($data['notes'] ?? ''),
                    'category' => $data['category'],
                    'district' => $data['district'],
                    'city' => trim($data['city'] ?? ''),
                ]);
            } catch (UniqueConstraintViolationException) {
                abort(409, 'You have already requested this item.');
            }
        });

        return (new ItemRequestResource($itemRequest->load('requester')))
            ->response()->setStatusCode(201);
    }

    /** The requester edits their own request while it is still pending. */
    public function update(Request $request, string $id): ItemRequestResource
    {
        $me = $request->user();
        $itemRequest = ItemRequest::query()->find($id);
        if ($itemRequest === null || ! $itemRequest->isVisibleTo($me)) {
            abort(404, 'Request not found.');
        }
        if ($itemRequest->requester_id !== $me->id) {
            abort(403, 'You can only edit your own requests.');
        }
        if ($itemRequest->status !== ItemRequest::STATUS_PENDING) {
            abort(409, 'This request can no longer be edited.');
        }
        $nameRule = $itemRequest->item_id === null
            ? ['required', 'string', 'max:120', 'not_regex:/^\s*$/']
            : ['nullable', 'string', 'max:120'];
        $data = $request->validate([
            'item_name' => $nameRule,
            'description' => ['required', 'string', 'max:2000', 'not_regex:/^\s*$/'],
            'reason' => ['required', 'string', 'max:1000', 'not_regex:/^\s*$/'],
            'notes' => ['nullable', 'string', 'max:1000'],
            'category' => Rules::activeCategory(),
            'district' => Rules::district(),
            'city' => Rules::city(),
        ], Rules::messages() + ['item_name.required' => 'Say which item you need.']);

        $itemRequest->update([
            'item_name' => trim($data['item_name'] ?? ''),
            'description' => trim($data['description']),
            'reason' => trim($data['reason']),
            'notes' => trim($data['notes'] ?? ''),
            'category' => $data['category'],
            'district' => $data['district'],
            'city' => trim($data['city'] ?? ''),
        ]);

        return new ItemRequestResource($itemRequest->load('requester'));
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $me = $request->user();
        $itemRequest = ItemRequest::query()->find($id);
        if ($itemRequest === null || ! $itemRequest->isVisibleTo($me)) {
            abort(404, 'Request not found.');
        }
        if (! $me->isAdmin()) {
            if ($itemRequest->requester_id !== $me->id) {
                abort(403, 'You can only delete your own requests.');
            }
            if ($itemRequest->status === ItemRequest::STATUS_APPROVED) {
                abort(409, "An approved request can't be deleted.");
            }
        }
        $itemRequest->delete();

        return response()->json(['message' => 'Request deleted.']);
    }

    /** The item's donor picks this request: starts the handover. */
    public function select(Request $request, string $id): JsonResponse
    {
        $exchange = $this->exchanges->selectRequester($request->user(), $id);

        return (new ExchangeResource($exchange))->response()->setStatusCode(201);
    }
}
