<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Exchange;
use App\Models\Item;
use App\Models\User;
use App\Services\AnalyticsService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\StreamedResponse;

class AdminAnalyticsController extends Controller
{
    public function __construct(protected AnalyticsService $analytics) {}

    public function index(Request $request): JsonResponse
    {
        $days = (int) $request->input('days', 30);
        $trends = $this->analytics->getGrowthTrends($days);
        $districts = $this->analytics->getDistrictDistribution();
        $categories = $this->analytics->getCategoryStats();

        // Monthly transaction volume
        $monthlyTransactions = [];
        for ($i = 5; $i >= 0; $i--) {
            $month = Carbon::now()->subMonths($i);
            $monthKey = $month->format('M Y');
            $count = Exchange::where('status', 'completed')
                ->whereMonth('completed_at', $month->month)
                ->whereYear('completed_at', $month->year)
                ->count();
            $monthlyTransactions[] = [
                'month' => $monthKey,
                'completed_exchanges' => $count,
            ];
        }

        // Retention metrics
        $totalUsers = max(1, User::count());
        $activeDonors = User::where('donation_count', '>', 0)->count();
        $repeatDonors = User::where('donation_count', '>=', 3)->count();

        $retention = [
            'donor_conversion_rate' => round(($activeDonors / $totalUsers) * 100, 1),
            'repeat_donor_rate' => round(($repeatDonors / max(1, $activeDonors)) * 100, 1),
            'avg_donations_per_active_user' => round(Item::count() / max(1, $activeDonors), 1),
        ];

        return response()->json([
            'growth_trends' => $trends,
            'district_activity' => $districts,
            'category_popularity' => $categories,
            'monthly_transactions' => $monthlyTransactions,
            'user_retention' => $retention,
        ]);
    }

    public function export(Request $request, string $type)
    {
        $entity = $request->input('entity', 'users'); // users, items, exchanges

        if ($type === 'csv') {
            $headers = [
                'Content-Type' => 'text/csv',
                'Content-Disposition' => "attachment; filename=\"shareloop-{$entity}-report.csv\"",
            ];

            return new StreamedResponse(function () use ($entity) {
                $handle = fopen('php://output', 'w');

                if ($entity === 'users') {
                    fputcsv($handle, ['ID', 'Name', 'Email', 'District', 'City', 'Donation Count', 'Status', 'Badge', 'Created At']);
                    User::chunk(200, function ($users) use ($handle) {
                        foreach ($users as $user) {
                            fputcsv($handle, [
                                $user->id, $user->display_name, $user->email, $user->district,
                                $user->city, $user->donation_count, $user->status, $user->badge,
                                $user->created_at->toIso8601String(),
                            ]);
                        }
                    });
                } elseif ($entity === 'items') {
                    fputcsv($handle, ['ID', 'Title', 'Category', 'Condition', 'District', 'City', 'Status', 'Moderation Status', 'Created At']);
                    Item::chunk(200, function ($items) use ($handle) {
                        foreach ($items as $item) {
                            fputcsv($handle, [
                                $item->id, $item->title, $item->category, $item->condition,
                                $item->district, $item->city, $item->status, $item->moderation_status,
                                $item->created_at->toIso8601String(),
                            ]);
                        }
                    });
                } else {
                    fputcsv($handle, ['ID', 'Item Title', 'Status', 'Donor ID', 'Requester ID', 'Completed At', 'Created At']);
                    Exchange::chunk(200, function ($exchanges) use ($handle) {
                        foreach ($exchanges as $ex) {
                            fputcsv($handle, [
                                $ex->id, $ex->item_title, $ex->status, $ex->donor_id,
                                $ex->requester_id, $ex->completed_at?->toIso8601String(),
                                $ex->created_at->toIso8601String(),
                            ]);
                        }
                    });
                }

                fclose($handle);
            }, 200, $headers);
        }

        return response()->json(['message' => 'Supported export formats: csv']);
    }
}
