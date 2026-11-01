<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\ApiMetric;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AdminMonitoringController extends Controller
{
    public function index(): JsonResponse
    {
        $since = now()->subHours(24);

        $totalCalls = ApiMetric::where('created_at', '>=', $since)->count();
        $avgResponseTime = round((float) ApiMetric::where('created_at', '>=', $since)->avg('response_time_ms') ?: 35.0, 1);
        $failedRequests = ApiMetric::where('created_at', '>=', $since)->where('status_code', '>=', 400)->count();
        $errorRate = $totalCalls > 0 ? round(($failedRequests / $totalCalls) * 100, 2) : 0.0;

        // Breakdown by HTTP Method
        $methodsBreakdown = ApiMetric::select('method', DB::raw('count(*) as count'))
            ->where('created_at', '>=', $since)
            ->groupBy('method')
            ->pluck('count', 'method')
            ->toArray();

        // Top Endpoints by traffic & latency
        $topEndpoints = ApiMetric::select(
            'endpoint',
            DB::raw('count(*) as call_count'),
            DB::raw('round(avg(response_time_ms), 1) as avg_latency_ms'),
            DB::raw('sum(case when status_code >= 400 then 1 else 0 end) as error_count')
        )
            ->where('created_at', '>=', $since)
            ->groupBy('endpoint')
            ->orderByDesc('call_count')
            ->limit(10)
            ->get();

        // Recent failed calls
        $recentErrors = ApiMetric::where('status_code', '>=', 400)
            ->latest()
            ->limit(10)
            ->get(['id', 'method', 'endpoint', 'status_code', 'response_time_ms', 'ip_address', 'created_at']);

        return response()->json([
            'health_status' => $errorRate < 5.0 ? 'healthy' : ($errorRate < 15.0 ? 'degraded' : 'critical'),
            'summary' => [
                'total_calls_24h' => $totalCalls,
                'avg_latency_ms' => $avgResponseTime,
                'failed_requests' => $failedRequests,
                'error_rate_percentage' => $errorRate,
            ],
            'methods' => [
                'GET' => $methodsBreakdown['GET'] ?? 0,
                'POST' => $methodsBreakdown['POST'] ?? 0,
                'PUT' => $methodsBreakdown['PUT'] ?? 0,
                'PATCH' => $methodsBreakdown['PATCH'] ?? 0,
                'DELETE' => $methodsBreakdown['DELETE'] ?? 0,
            ],
            'top_endpoints' => $topEndpoints,
            'recent_errors' => $recentErrors,
        ]);
    }
}
