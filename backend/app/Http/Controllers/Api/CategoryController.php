<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\CategoryResource;
use App\Models\Category;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Str;

/** Reference data anyone may read; only admins change it. */
class CategoryController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $query = Category::query()->orderBy('sort_order')->orderBy('name');
        $wantsAll = $request->boolean('all') && $request->user('sanctum')?->isAdmin();
        if (! $wantsAll) {
            $query->where('is_active', true);
        }

        return CategoryResource::collection($query->get());
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'id' => ['nullable', 'string', 'regex:/^[a-z0-9_-]{1,40}$/', 'unique:categories,id'],
            'name' => ['required', 'string', 'max:60', 'not_regex:/^\s*$/'],
            'icon_name' => ['nullable', 'string', 'max:40'],
            'sort_order' => ['nullable', 'integer'],
        ]);
        $name = trim($data['name']);

        // Re-adding a retired category brings it back.
        $existing = Category::query()->where('name', $name)->first();
        if ($existing !== null) {
            if ($existing->is_active) {
                abort(409, 'That category already exists.');
            }
            $existing->forceFill([
                'is_active' => true,
                'icon_name' => $data['icon_name'] ?? $existing->icon_name,
            ])->save();

            return (new CategoryResource($existing))->response()->setStatusCode(200);
        }

        $id = $data['id'] ?? (Str::slug($name, '_') ?: 'cat').'_'.Str::lower(Str::random(4));
        $category = Category::create([
            'id' => substr($id, 0, 40),
            'name' => $name,
            'icon_name' => $data['icon_name'] ?? 'category',
            'sort_order' => $data['sort_order'] ?? 1000,
        ]);

        return (new CategoryResource($category))->response()->setStatusCode(201);
    }

    /** Retires the category; posts already using it keep it. */
    public function destroy(string $id): JsonResponse
    {
        $category = Category::query()->findOrFail($id);
        $category->forceFill(['is_active' => false])->save();

        return response()->json(['message' => 'Category removed.']);
    }
}
