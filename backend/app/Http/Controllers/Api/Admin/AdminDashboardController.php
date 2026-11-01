<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Exchange;
use App\Models\Item;
use App\Models\ItemRequest;
use App\Models\Rating;
use App\Models\User;
use App\Services\AnalyticsService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminDashboardController extends Controller
{
    public function __construct(protected AnalyticsService $analytics) {}

    /**
     * Complete overview for the main dashboard widget grid.
     */
    public function overview(Request $request): JsonResponse
    {
        $kpis = $this->analytics->getOverviewKPIs();
        $trends = $this->analytics->getGrowthTrends(14);
        $districts = $this->analytics->getDistrictDistribution();
        $categories = $this->analytics->getCategoryStats();

        // Top Donors
        $topDonors = User::orderByDesc('donation_count')
            ->limit(5)
            ->get(['id', 'display_name', 'email', 'donation_count', 'badge', 'rating_avg', 'district']);

        // Most Requested Categories
        $topRequestedCategories = ItemRequest::selectRaw('category, count(*) as total_requests')
            ->groupBy('category')
            ->orderByDesc('total_requests')
            ->limit(5)
            ->get();

        // Recent Activity Stream
        $recentItems = Item::with('donor:id,display_name')
            ->latest()
            ->limit(5)
            ->get(['id', 'title', 'category', 'district', 'donor_id', 'moderation_status', 'created_at']);

        $recentExchanges = Exchange::with(['donor:id,display_name', 'requester:id,display_name'])
            ->latest()
            ->limit(5)
            ->get();

        return response()->json([
            'kpis' => $kpis,
            'trends' => $trends,
            'districts' => $districts,
            'categories' => $categories,
            'top_donors' => $topDonors,
            'top_requested_categories' => $topRequestedCategories,
            'recent_items' => $recentItems,
            'recent_exchanges' => $recentExchanges,
        ]);
    }
}
