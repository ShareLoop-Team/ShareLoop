<?php

namespace App\Services;

use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Checks a Facebook user access token (from "Continue with Facebook") with
 * the Graph API: debug_token confirms it is valid and was issued to OUR app,
 * then /me gives the person's id, name and email.
 */
class FacebookTokenVerifier
{
    /**
     * @return array{id: string, email: string, name: string}
     */
    public function verify(string $accessToken): array
    {
        $appId = (string) config('shareloop.facebook.app_id');
        $secret = (string) config('shareloop.facebook.app_secret');
        if ($appId === '' || $secret === '') {
            abort(503, 'Facebook sign-in is not set up on the server yet.');
        }
        $graph = rtrim((string) config('shareloop.facebook.graph_url'), '/');

        $debug = $this->get($graph.'/debug_token', [
            'input_token' => $accessToken,
            'access_token' => $appId.'|'.$secret,
        ]);
        $info = is_array($debug['data'] ?? null) ? $debug['data'] : [];
        if (($info['is_valid'] ?? false) !== true
            || (string) ($info['app_id'] ?? '') !== $appId
            || empty($info['user_id'])) {
            Log::info('ShareLoop: rejected Facebook token', ['app_id' => $info['app_id'] ?? null]);
            abort(401, 'Facebook sign-in failed. Please try again.');
        }

        $me = $this->get($graph.'/me', [
            'fields' => 'id,name,email',
            'access_token' => $accessToken,
            'appsecret_proof' => hash_hmac('sha256', $accessToken, $secret),
        ]);
        if ((string) ($me['id'] ?? '') !== (string) $info['user_id']) {
            abort(401, 'Facebook sign-in failed. Please try again.');
        }
        $email = strtolower(trim((string) ($me['email'] ?? '')));
        if ($email === '' || ! filter_var($email, FILTER_VALIDATE_EMAIL)) {
            abort(422, 'Your Facebook account has no email address we can use. Please sign up with email instead.');
        }

        return [
            'id' => (string) $me['id'],
            'email' => $email,
            'name' => trim((string) ($me['name'] ?? '')),
        ];
    }

    private function get(string $url, array $query): array
    {
        try {
            $response = Http::timeout(10)->get($url, $query);
        } catch (ConnectionException) {
            abort(503, "Couldn't reach Facebook right now. Please try again.");
        }
        if ($response->serverError()) {
            abort(503, "Couldn't reach Facebook right now. Please try again.");
        }
        if (! $response->successful() || ! is_array($response->json())) {
            Log::info('ShareLoop: Facebook Graph API refused a token', ['status' => $response->status()]);
            abort(401, 'Facebook sign-in failed. Please try again.');
        }

        return $response->json();
    }
}
