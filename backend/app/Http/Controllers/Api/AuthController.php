<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\EmailOtp;
use App\Models\User;
use App\Services\EmailOtpService;
use App\Services\GoogleIdTokenVerifier;
use App\Support\Rules;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

/**
 * Accounts with Sanctum bearer tokens. Email ownership is proven with a
 * one-time code: to register, to sign in without a password, and to reset
 * a forgotten password.
 */
class AuthController extends Controller
{
    public function __construct(
        private readonly EmailOtpService $otps,
        private readonly GoogleIdTokenVerifier $google,
    ) {}

    /** Emails a one-time code for register / login / reset. */
    public function requestCode(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'string', 'email', 'max:254'],
            'purpose' => ['required', Rule::in(EmailOtp::PURPOSES)],
        ]);
        $email = Str::lower(trim($data['email']));
        $user = User::query()->where('email', $email)->first();

        if ($data['purpose'] === EmailOtp::PURPOSE_REGISTER && $user !== null) {
            abort(422, 'An account already exists for that email. Please sign in.');
        }
        if ($data['purpose'] === EmailOtp::PURPOSE_REGISTER) {
            // The app sends the rest of the form too, so mistakes show up
            // before the code is emailed rather than after.
            $request->validate([
                'name' => ['sometimes', ...Rules::displayName()],
                'password' => ['sometimes', 'string', 'min:6', 'max:128'],
                'phone' => ['sometimes', ...Rules::phone()],
                'district' => ['sometimes', ...Rules::district()],
                'city' => ['sometimes', ...Rules::city()],
            ], Rules::messages());
        }
        if ($data['purpose'] !== EmailOtp::PURPOSE_REGISTER && $user !== null && ! $user->isActive()) {
            abort(403, 'This account has been suspended.');
        }

        $body = [
            'message' => 'If that email can be used, a code is on its way. Check your inbox (and spam).',
            'expires_in' => config('shareloop.otp.lifetime_minutes') * 60,
            'resend_in' => config('shareloop.otp.resend_seconds'),
        ];
        // Sign-in and reset codes only go to existing accounts, without
        // telling the caller whether the account exists.
        if ($data['purpose'] === EmailOtp::PURPOSE_REGISTER || $user !== null) {
            $code = $this->otps->send($email, $data['purpose']);
            if (EmailOtpService::exposesCodes()) {
                $body['debug_code'] = $code; // no real mailer configured (local only)
            }
        }

        return response()->json($body);
    }

    /** Creates the account once the emailed code checks out. */
    public function register(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => Rules::displayName(),
            'email' => ['required', 'string', 'email', 'max:254', 'unique:users,email'],
            'password' => ['required', 'string', 'min:6', 'max:128'],
            'phone' => Rules::phone(),
            'district' => Rules::district(),
            'city' => Rules::city(),
            'code' => ['required', 'string'],
            'device_name' => ['nullable', 'string', 'max:100'],
        ], Rules::messages() + ['code.required' => 'Enter the code we emailed you.']);

        $email = Str::lower(trim($data['email']));
        $this->otps->verify($email, EmailOtp::PURPOSE_REGISTER, $data['code']);

        $user = User::create([
            'display_name' => trim($data['name']),
            'email' => $email,
            'password' => $data['password'],
            'phone' => trim($data['phone']),
            'district' => $data['district'],
            'city' => trim($data['city'] ?? ''),
        ]);
        $user->forceFill(['email_verified_at' => now()])->save();

        return $this->tokenResponse($request, $user, 201);
    }

    public function login(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'string', 'email'],
            'password' => ['required', 'string'],
            'device_name' => ['nullable', 'string', 'max:100'],
        ]);

        $user = User::query()->where('email', Str::lower(trim($data['email'])))->first();
        if ($user === null || ! Hash::check($data['password'], $user->password)) {
            return response()->json(['message' => 'Incorrect email or password.'], 401);
        }
        if (! $user->isActive()) {
            return response()->json(['message' => 'This account has been suspended.'], 403);
        }

        return $this->tokenResponse($request, $user);
    }

    /** Signs in with an emailed code instead of the password. */
    public function loginWithCode(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'string', 'email'],
            'code' => ['required', 'string'],
            'device_name' => ['nullable', 'string', 'max:100'],
        ]);
        $email = Str::lower(trim($data['email']));
        $this->otps->verify($email, EmailOtp::PURPOSE_LOGIN, $data['code']);

        $user = User::query()->where('email', $email)->first();
        if ($user === null) {
            abort(422, 'That code is no longer valid. Please request a new one.');
        }
        if (! $user->isActive()) {
            abort(403, 'This account has been suspended.');
        }
        if ($user->email_verified_at === null) {
            $user->forceFill(['email_verified_at' => now()])->save();
        }

        return $this->tokenResponse($request, $user);
    }

    /** Sets a new password with an emailed code and signs out every device. */
    public function resetPassword(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'string', 'email'],
            'code' => ['required', 'string'],
            'password' => ['required', 'string', 'min:6', 'max:128'],
        ]);
        $email = Str::lower(trim($data['email']));
        $this->otps->verify($email, EmailOtp::PURPOSE_RESET, $data['code']);

        $user = User::query()->where('email', $email)->first();
        if ($user === null) {
            abort(422, 'That code is no longer valid. Please request a new one.');
        }
        $user->forceFill(['password' => $data['password']])->save();
        $user->tokens()->delete();

        return response()->json(['message' => 'Your password has been changed. Sign in with the new one.']);
    }

    /**
     * "Sign in with Google" with the ID token the app got from Google.
     * Existing accounts (same Google account, or same verified email) are
     * signed in. A new person gets {needs_profile: true, ...} first, and the
     * app calls again with phone, district (and city) to create the account.
     */
    public function google(Request $request): JsonResponse
    {
        $data = $request->validate([
            'id_token' => ['required', 'string', 'max:4096'],
            'name' => ['sometimes', ...Rules::displayName()],
            'phone' => ['sometimes', ...Rules::phone()],
            'district' => ['sometimes', ...Rules::district()],
            'city' => ['sometimes', ...Rules::city()],
            'device_name' => ['nullable', 'string', 'max:100'],
        ], Rules::messages());
        $google = $this->google->verify($data['id_token']);

        $user = User::query()->where('google_id', $google['sub'])->first()
            ?? User::query()->where('email', $google['email'])->first();

        if ($user !== null) {
            if (! $user->isActive()) {
                abort(403, 'This account has been suspended.');
            }
            if ($user->google_id === null) {
                // Google has verified the email, so it's safe to link.
                $user->forceFill(['google_id' => $google['sub']]);
            }
            $user->email_verified_at ??= now();
            $user->save();

            return $this->tokenResponse($request, $user);
        }

        if (! isset($data['phone'], $data['district'])) {
            return response()->json([
                'needs_profile' => true,
                'email' => $google['email'],
                'name' => $google['name'],
            ]);
        }

        $user = User::create([
            'display_name' => trim($data['name'] ?? '') ?: ($google['name'] ?: strstr($google['email'], '@', true)),
            'email' => $google['email'],
            // No password yet; "Forgot password?" can set one later.
            'password' => Str::random(64),
            'phone' => trim($data['phone']),
            'district' => $data['district'],
            'city' => trim($data['city'] ?? ''),
        ]);
        $user->forceFill(['google_id' => $google['sub'], 'email_verified_at' => now()])->save();

        return $this->tokenResponse($request, $user, 201);
    }

    public function me(Request $request): UserResource
    {
        return new UserResource($request->user());
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()?->delete();

        return response()->json(['message' => 'Signed out.']);
    }

    private function tokenResponse(Request $request, User $user, int $status = 200): JsonResponse
    {
        $token = $user->createToken(
            $request->input('device_name') ?: 'shareloop-app',
            ['*'],
            now()->addDays(config('shareloop.token_lifetime_days')),
        );

        // The new token's owner is the viewer, so they see their own contacts.
        $request->setUserResolver(fn () => $user);

        return response()->json([
            'token' => $token->plainTextToken,
            'user' => (new UserResource($user->fresh()))->toArray($request),
        ], $status);
    }
}
