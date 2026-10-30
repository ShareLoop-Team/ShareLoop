<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/** Suspended accounts can't use the API, even with a token issued earlier. */
class EnsureUserIsActive
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();
        if ($user !== null && ! $user->isActive()) {
            return response()->json(['message' => 'This account has been suspended.'], 403);
        }

        return $next($request);
    }
}
