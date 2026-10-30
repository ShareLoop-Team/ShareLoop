<?php

namespace App\Services;

use Firebase\JWT\JWK;
use Firebase\JWT\JWT;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Throwable;

/**
 * Checks a Google ID token (from "Sign in with Google") the way Google's
 * docs describe: RS256 signature against Google's published keys, issuer,
 * audience = one of our OAuth client IDs, not expired, email verified.
 */
class GoogleIdTokenVerifier
{
    private const ISSUERS = ['accounts.google.com', 'https://accounts.google.com'];

    /**
     * @return array{sub: string, email: string, name: string}
     */
    public function verify(string $idToken): array
    {
        $clientIds = config('shareloop.google.client_ids');
        if ($clientIds === []) {
            abort(503, 'Google sign-in is not set up on the server yet.');
        }

        try {
            $claims = (array) JWT::decode($idToken, JWK::parseKeySet($this->keys()));
        } catch (Throwable $e) {
            Log::info('ShareLoop: rejected Google ID token', ['error' => $e->getMessage()]);
            abort(401, 'Google sign-in failed. Please try again.');
        }

        if (! in_array($claims['iss'] ?? null, self::ISSUERS, true)
            || ! in_array($claims['aud'] ?? null, $clientIds, true)) {
            abort(401, 'Google sign-in failed. Please try again.');
        }
        if (empty($claims['email']) || ! filter_var($claims['email_verified'] ?? false, FILTER_VALIDATE_BOOL)) {
            abort(401, 'Your Google account has no verified email address.');
        }

        return [
            'sub' => (string) $claims['sub'],
            'email' => strtolower((string) $claims['email']),
            'name' => trim((string) ($claims['name'] ?? '')),
        ];
    }

    /** Google's signing keys (JWKS), cached for an hour. */
    private function keys(): array
    {
        return Cache::remember('shareloop.google.jwks', 3600, function () {
            $response = Http::timeout(10)->get(config('shareloop.google.certs_url'));
            if (! $response->successful() || ! is_array($response->json('keys'))) {
                abort(503, "Couldn't reach Google right now. Please try again.");
            }

            return $response->json();
        });
    }
}
