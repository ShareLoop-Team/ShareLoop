<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Item;
use App\Models\ItemRequest;
use App\Services\AnalyticsService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminLocationController extends Controller
{
    public function __construct(protected AnalyticsService $analytics) {}

    public function index(): JsonResponse
    {
        $districts = $this->analytics->getDistrictDistribution();

        // City level hotspots
        $topCities = Item::selectRaw('city, district, count(*) as donation_count')
            ->where('city', '!=', '')
            ->groupBy('city', 'district')
            ->orderByDesc('donation_count')
            ->limit(10)
            ->get();

        return response()->json([
            'districts' => $districts,
            'top_cities' => $topCities,
            'coverage_summary' => [
                'total_districts' => 25,
                'active_districts_count' => count(array_filter($districts, fn ($d) => $d['activity_index'] > 0)),
            ],
        ]);
    }
}
