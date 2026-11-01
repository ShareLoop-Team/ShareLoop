<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Item;
use App\Services\AuditLogger;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class AdminCategoryController extends Controller
{
    public function index(): JsonResponse
    {
        $categories = Category::orderBy('sort_order')->get();

        // Attach item counts
        $itemCounts = Item::selectRaw('category, count(*) as count')
            ->groupBy('category')
            ->pluck('count', 'category')
            ->toArray();

        $enriched = $categories->map(function ($cat) use ($itemCounts) {
            $catArray = $cat->toArray();
            $catArray['items_count'] = $itemCounts[$cat->name] ?? 0;
            return $catArray;
        });

        return response()->json($enriched);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'id' => ['nullable', 'string', 'regex:/^[a-z0-9_-]{1,40}$/', 'unique:categories,id'],
            'name' => ['required', 'string', 'max:60', 'not_regex:/^\s*$/'],
            'icon_name' => ['nullable', 'string', 'max:40'],
            'sort_order' => ['nullable', 'integer'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $name = trim($data['name']);

        $existing = Category::query()->where('name', $name)->first();
        if ($existing !== null) {
            if ($existing->is_active) {
                abort(409, 'That category already exists.');
            }
            $existing->forceFill([
                'is_active' => true,
                'icon_name' => $data['icon_name'] ?? $existing->icon_name,
            ])->save();

            AuditLogger::log(
                action: 'category.reactivate',
                entity: $existing,
                newValues: $existing->toArray(),
                description: "Reactivated category {$existing->name}"
            );

            return (new \App\Http\Resources\CategoryResource($existing))->additional([
                'message' => 'Category reactivated successfully.',
                'category' => $existing,
            ])->response()->setStatusCode(200);
        }

        $id = $data['id'] ?? (Str::slug($name, '_') ?: 'cat').'_'.Str::lower(Str::random(4));
        $category = Category::create([
            'id' => substr($id, 0, 40),
            'name' => $name,
            'icon_name' => $data['icon_name'] ?? 'category',
            'sort_order' => $data['sort_order'] ?? 1000,
            'is_active' => $data['is_active'] ?? true,
        ]);

        AuditLogger::log(
            action: 'category.create',
            entity: $category,
            newValues: $category->toArray(),
            description: "Created category {$category->name}"
        );

        return (new \App\Http\Resources\CategoryResource($category))->additional([
            'message' => 'Category created successfully.',
            'category' => $category,
        ])->response()->setStatusCode(201);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $category = Category::findOrFail($id);

        $data = $request->validate([
            'name' => ['required', 'string', 'max:60', 'unique:categories,name,' . $category->id . ',id'],
            'icon_name' => ['nullable', 'string', 'max:40'],
            'sort_order' => ['nullable', 'integer'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $old = $category->toArray();
        $category->update($data);

        AuditLogger::log(
            action: 'category.update',
            entity: $category,
            oldValues: $old,
            newValues: $category->toArray(),
            description: "Updated category {$category->name}"
        );

        return response()->json(['message' => 'Category updated successfully.', 'category' => $category]);
    }

    public function destroy(string $id): JsonResponse
    {
        $category = Category::findOrFail($id);

        $old = $category->toArray();
        $category->forceFill(['is_active' => false])->save();

        AuditLogger::log(
            action: 'category.retire',
            entity: $category,
            oldValues: $old,
            newValues: $category->toArray(),
            description: "Retired category {$category->name}"
        );

        return response()->json(['message' => 'Category removed.']);
    }
}
