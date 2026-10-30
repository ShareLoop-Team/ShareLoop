<?php

namespace Tests\Feature;

use App\Models\User;
use Firebase\JWT\JWT;
use Illuminate\Support\Facades\Http;

/**
 * "Sign in with Google". Tokens are signed with a throwaway test key whose
 * public half is served as Google's key set through Http::fake, so the real
 * verification code runs without network access.
 */
class GoogleAuthTest extends ShareLoopTestCase
{
    private const CLIENT_ID = 'test-client.apps.googleusercontent.com';
    private const KID = 'test-key-1';

    // Test-only RSA key (generated for this suite; not used anywhere else).
    private const PRIVATE_KEY = <<<'PEM'
-----BEGIN PRIVATE KEY-----
MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCd0Z6QOm950/17
6vBosP+eUvNoxUuSWia7YUGrj3e0VNc+4dXA7q4ubxWCy5EHbhv19JFDxI2lp83I
0oX+kVzxoZFWFzKTFyvKqCR4DOAVwh7OUAkl90w9mp3FTLBxn9GiBjjWThe7sH2j
/U8hACuuJJU0HKT9y9A6FM8ga628mhpeRUz0tiEVV6iHEw+wZZL9YMboaWGu5j4Y
SUH4h2Mi6yjImynm0wTvtRYqGqqWEBZMlW9wWasS8UpB/ZQGc6gZzB1T07VCSh6n
QQ/1ZRtgf+BjRgLpoxxnQ2RplWvFCK4kQIAKFj2MJKspQHHw5SsOwUm5DCWzyRIF
pNTEarftAgMBAAECggEAG1rLmKVAUEYR4Eo7LHJNhERNg4H7FN2CbCUx7Eo8TeoM
uw4K7luQnmTLvjWJqFeKCio/iZcGlEmPLjlrV1Ib4ZgHKHxx3DP+d6yIUbStnKfe
jhUqWMXSFbV4lkuyI6e3ftWEQYUcsQAo7uVHs2kjqRYXNIaohIMwzvhvZGe1oARy
HBW8277brBGE7RWkOIiNNc2CVX03SaKBKUUa5yLgBZAD8ZIPsNr3S2n26BQyrZpl
AR5LK8XOzPHBw8KSH5D8cZdm/e7p90CwilRTdGhSUedlTizmMlqdxRAnEklY+j0v
hKecl0IBMQuBE0eu30TcSNsIueXCEeNm7U/usifkMQKBgQDZU083iiRUkd5ulDGh
G4DmSVMXqJwxZAfDjhrfOjw8I4VxlqOZ4QjgnelFOBnCyUK0eGXIMrpUcHHcM4u+
binGqImHVBWpZGPckmVDkT+f3C+4ljHDTcHO+ep42ocdx/lTWx9rxAomKtTipCE/
Euqa3lbq/Ux/3IX7ADrQz5TCpQKBgQC5515nr2EChfK935Op9efNOfKGfhcoUWjD
8fz7gsTpcQBhpVRqyI4ix0tI9f12gPR9xgEQfpslINh/4daEeQRj2K6lKIYUeMxs
z0f0WpiagqP8RVPh4Ail2uuMhmdff0gg+P5BVnORRByRKijxMpu1B+wKoTwx44ie
R1MNBnUFqQKBgEUANn6j1bUkO0NQuhE08lArp74zQqRL5ksoq0+E5esSPCQ8d+U7
ld37RT08+rDlxdAXCfnuYUq+COipVQ05XPo+OKxG/jmyLiKyOISjcVgISP6KcXJZ
FdfpcZC9kXjbLUZSAD/vFmnX34+2HPgxwVs6jM4/bjKKid+PyxzRS6IhAoGAfDc6
fzFSMqtpzLDtK61hm2FSycbKlmf/Bp5UmYGBLTISPSyJQWiMgHSFu1SSbXIw6zE4
WNsfsylFP/2Ypp9t7YFFAJoZLOiiPzopK/605NjR1ahFKjHV1Wx340eTHt4fRdjZ
mrK3OaM3K0/uV2unWsjWUSv22qbcDFZACf38hzECgYBies6kmkMYjJ/i+QQa07J0
oAzj1yQku3uXhQ9sP2OUsa/ZjwP6VAEbTgCjLYr9a3kQS9z0X3nUnvSBhaBR4+3E
9JNuLxAZxeBqLazzfasx9j51yLJSw2Z7jCuR268lVIsPg2lhdVqyQBWF39dYVViN
mx4i0KL9mviTyoFxt/hWtw==
-----END PRIVATE KEY-----
PEM;

    private const MODULUS = 'ndGekDpvedP9e-rwaLD_nlLzaMVLklomu2FBq493tFTXPuHVwO6uLm8VgsuRB24b9fSRQ8SNpafNyNKF_pFc8aGRVhcykxcryqgkeAzgFcIezlAJJfdMPZqdxUywcZ_RogY41k4Xu7B9o_1PIQArriSVNByk_cvQOhTPIGutvJoaXkVM9LYhFVeohxMPsGWS_WDG6GlhruY-GElB-IdjIusoyJsp5tME77UWKhqqlhAWTJVvcFmrEvFKQf2UBnOoGcwdU9O1Qkoep0EP9WUbYH_gY0YC6aMcZ0NkaZVrxQiuJECAChY9jCSrKUBx8OUrDsFJuQwls8kSBaTUxGq37Q';

    protected function setUp(): void
    {
        parent::setUp();
        config(['shareloop.google.client_ids' => [self::CLIENT_ID]]);
        Http::fake([
            'https://www.googleapis.com/oauth2/v3/certs' => Http::response(['keys' => [[
                'kty' => 'RSA', 'alg' => 'RS256', 'use' => 'sig', 'kid' => self::KID,
                'n' => self::MODULUS, 'e' => 'AQAB',
            ]]]),
        ]);
    }

    private function idToken(array $overrides = [], string $key = self::PRIVATE_KEY): string
    {
        return JWT::encode(array_merge([
            'iss' => 'https://accounts.google.com',
            'aud' => self::CLIENT_ID,
            'sub' => '1098765432109876543',
            'email' => 'Nimal.Google@gmail.com',
            'email_verified' => true,
            'name' => 'Nimal Google',
            'iat' => time(),
            'exp' => time() + 3600,
        ], $overrides), $key, 'RS256', self::KID);
    }

    public function test_a_new_person_completes_their_profile_then_gets_an_account(): void
    {
        $this->postJson('/api/auth/google', ['id_token' => $this->idToken()])
            ->assertOk()
            ->assertExactJson(['needs_profile' => true, 'email' => 'nimal.google@gmail.com', 'name' => 'Nimal Google']);
        $this->assertDatabaseCount('users', 0);

        $this->postJson('/api/auth/google', [
            'id_token' => $this->idToken(), 'phone' => 'nope', 'district' => 'Kandy',
        ])->assertStatus(422)->assertJsonValidationErrors('phone');

        $response = $this->postJson('/api/auth/google', [
            'id_token' => $this->idToken(), 'phone' => '0771234567', 'district' => 'Kandy', 'city' => 'Peradeniya',
        ])->assertCreated()
            ->assertJsonPath('user.email', 'nimal.google@gmail.com')
            ->assertJsonPath('user.display_name', 'Nimal Google')
            ->assertJsonPath('user.phone', '0771234567');

        $user = User::query()->where('email', 'nimal.google@gmail.com')->first();
        $this->assertSame('1098765432109876543', $user->google_id);
        $this->assertNotNull($user->email_verified_at);
        $this->withToken($response->json('token'))->getJson('/api/auth/me')->assertOk();

        // Next time it's a straight sign-in.
        $this->postJson('/api/auth/google', ['id_token' => $this->idToken()])
            ->assertOk()->assertJsonStructure(['token', 'user'])
            ->assertJsonPath('user.id', $user->id);
    }

    public function test_an_existing_email_account_is_linked_and_signed_in(): void
    {
        $user = $this->makeUser(['email' => 'nimal.google@gmail.com']);

        $this->postJson('/api/auth/google', ['id_token' => $this->idToken()])
            ->assertOk()->assertJsonPath('user.id', $user->id);
        $this->assertSame('1098765432109876543', $user->fresh()->google_id);
    }

    public function test_tokens_that_are_not_from_google_for_this_app_are_rejected(): void
    {
        $cases = [
            'wrong audience' => $this->idToken(['aud' => 'someone-else.apps.googleusercontent.com']),
            'wrong issuer' => $this->idToken(['iss' => 'https://evil.example.com']),
            'expired' => $this->idToken(['exp' => time() - 7200, 'iat' => time() - 10800]),
            'tampered' => substr($this->idToken(), 0, -4).'AAAA',
            'garbage' => 'not.a.token',
        ];
        foreach ($cases as $label => $token) {
            $this->postJson('/api/auth/google', ['id_token' => $token])
                ->assertStatus(401, $label);
        }
        $this->postJson('/api/auth/google', ['id_token' => $this->idToken(['email_verified' => false])])
            ->assertStatus(401)->assertJsonPath('message', 'Your Google account has no verified email address.');
        $this->assertDatabaseCount('users', 0);
    }

    public function test_suspended_accounts_cannot_sign_in_with_google(): void
    {
        $this->makeUser(['email' => 'nimal.google@gmail.com', 'status' => 'suspended']);

        $this->postJson('/api/auth/google', ['id_token' => $this->idToken()])->assertForbidden();
    }

    public function test_it_says_so_when_google_is_not_configured(): void
    {
        config(['shareloop.google.client_ids' => []]);

        $this->postJson('/api/auth/google', ['id_token' => $this->idToken()])
            ->assertStatus(503)->assertJsonPath('message', 'Google sign-in is not set up on the server yet.');
    }
}
