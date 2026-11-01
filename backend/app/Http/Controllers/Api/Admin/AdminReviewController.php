<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Rating;
use App\Models\User;
use App\Services\AuditLogger;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminReviewController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Rating::with([
            'rater:id,display_name,email',
            'ratee:id,display_name,email,rating_avg',
            'item:id,title',
        ]);

        if ($request->filled('search')) {
            $search = '%' . $request->input('search') . '%';
            $query->where('comment', 'like', $search);
        }

        if ($request->filled('stars')) {
            $query->where('stars', $request->input('stars'));
        }

        $query->orderBy('created_at', 'desc');
        $perPage = min(100, (int) $request->input('per_page', 15));

        $reviews = $query->paginate($perPage);

        // Summary stats
        $avgStars = round((float) Rating::avg('stars') ?: 5.0, 2);
        $totalCount = Rating::count();
        $starBreakdown = [
            5 => Rating::where('stars', 5)->count(),
            4 => Rating::where('stars', 4)->count(),
            3 => Rating::where('stars', 3)->count(),
            2 => Rating::where('stars', 2)->count(),
            1 => Rating::where('stars', 1)->count(),
        ];

        return response()->json([
            'reviews' => $reviews,
            'analytics' => [
                'average_rating' => $avgStars,
                'total_reviews' => $totalCount,
                'breakdown' => $starBreakdown,
            ],
        ]);
    }

    public function destroy(string $id): JsonResponse
    {
        $rating = Rating::findOrFail($id);
        $ratee = User::find($rating->ratee_id);

        AuditLogger::log(
            action: 'review.delete',
            entity: $rating,
            oldValues: ['stars' => $rating->stars, 'comment' => $rating->comment],
            description: "Review removed by administrator"
        );

        $rating->delete();

        // Refresh ratee average
        $ratee?->refreshRatingSummary();

        return response()->json(['message' => 'Review deleted and user rating score refreshed.']);
    }
}
