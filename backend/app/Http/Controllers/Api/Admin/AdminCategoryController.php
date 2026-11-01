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
            'name' => ['required', 'string', 'max:60', 'unique:categories,name'],
            'icon_name' => ['nullable', 'string', 'max:40'],
            'sort_order' => ['nullable', 'integer'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $id = Str::slug($data['name']);
        $category = Category::create([
            'id' => $id,
            'name' => $data['name'],
            'icon_name' => $data['icon_name'] ?? 'category',
            'sort_order' => $data['sort_order'] ?? 0,
            'is_active' => $data['is_active'] ?? true,
        ]);

        AuditLogger::log(
            action: 'category.create',
            entity: $category,
            newValues: $category->toArray(),
            description: "Created category {$category->name}"
        );

        return response()->json(['message' => 'Category created successfully.', 'category' => $category], 201);
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

        if (Item::where('category', $category->name)->exists()) {
            return response()->json([
                'message' => 'Cannot delete category that still has items associated with it. Disable it instead.',
            ], 422);
        }

        AuditLogger::log(
            action: 'category.delete',
            entity: $category,
            oldValues: $category->toArray(),
            description: "Deleted category {$category->name}"
        );

        $category->delete();

        return response()->json(['message' => 'Category deleted successfully.']);
    }
}
