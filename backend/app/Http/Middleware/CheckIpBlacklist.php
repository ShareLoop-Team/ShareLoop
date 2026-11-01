<?php

namespace App\Http\Middleware;

use App\Services\SecurityService;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CheckIpBlacklist
{
    public function __construct(protected SecurityService $security) {}

    public function handle(Request $request, Closure $next): Response
    {
        if ($this->security->isIpBlacklisted($request->ip())) {
            return response()->json([
                'message' => 'Access denied: Your IP address has been blocked due to security violations.',
            ], 403);
        }

        return $next($request);
    }
}
