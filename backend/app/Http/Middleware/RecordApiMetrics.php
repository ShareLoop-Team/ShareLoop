<?php

namespace App\Http\Middleware;

use App\Models\ApiMetric;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class RecordApiMetrics
{
    public function handle(Request $request, Closure $next): Response
    {
        $startTime = microtime(true);

        $response = $next($request);

        $durationMs = round((microtime(true) - $startTime) * 1000, 2);

        // Record metrics for API endpoints (avoid overhead on asset files)
        if ($request->is('api/*')) {
            try {
                ApiMetric::create([
                    'method' => $request->method(),
                    'endpoint' => substr($request->path(), 0, 190),
                    'status_code' => $response->getStatusCode(),
                    'response_time_ms' => $durationMs,
                    'ip_address' => $request->ip(),
                ]);
            } catch (\Throwable $e) {
                // Silently bypass metric logging errors to never disrupt API responses
            }
        }

        return $response;
    }
}
