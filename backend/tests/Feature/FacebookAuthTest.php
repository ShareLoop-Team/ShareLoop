<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Http\Client\Request;
use Illuminate\Support\Facades\Http;

/**
 * "Continue with Facebook". The Graph API is faked with Http::fake, so the
 * real verification code (debug_token + /me) runs without network access.
 */
class FacebookAuthTest extends ShareLoopTestCase
{
    private const APP_ID = '1234567890';
    private const SECRET = 'test-app-secret';
    private const TOKEN = 'EAAtestUserAccessToken';
    private const FB_USER = '10223344556677';

    private array $debug;
    private array $me;

    protected function setUp(): void
    {
        parent::setUp();
        config([
            'shareloop.facebook.app_id' => self::APP_ID,
            'shareloop.facebook.app_secret' => self::SECRET,
        ]);
        $this->debug = ['data' => ['app_id' => self::APP_ID, 'is_valid' => true, 'user_id' => self::FB_USER]];
        $this->me = ['id' => self::FB_USER, 'name' => 'Kavya Facebook', 'email' => 'Kavya.FB@example.com'];
        Http::fake(function (Request $request) {
            $url = $request->url();
            if (str_contains($url, '/debug_token')) {
                return Http::response($this->debug);
            }
            if (str_contains($url, '/me')) {
                return Http::response($this->me);
            }

            return Http::response([], 404);
        });
    }

    public function test_a_new_person_completes_their_profile_then_gets_an_account(): void
    {
        $this->postJson('/api/auth/facebook', ['access_token' => self::TOKEN])
            ->assertOk()
            ->assertExactJson(['needs_profile' => true, 'email' => 'kavya.fb@example.com', 'name' => 'Kavya Facebook']);
        $this->assertDatabaseCount('users', 0);

        $response = $this->postJson('/api/auth/facebook', [
            'access_token' => self::TOKEN, 'phone' => '0771234567', 'district' => 'Galle', 'city' => 'Unawatuna',
        ])->assertCreated()
            ->assertJsonPath('user.email', 'kavya.fb@example.com')
            ->assertJsonPath('user.display_name', 'Kavya Facebook');

        $user = User::query()->where('email', 'kavya.fb@example.com')->first();
        $this->assertSame(self::FB_USER, $user->facebook_id);
        $this->assertNotNull($user->email_verified_at);
        $this->assertArrayNotHasKey('facebook_id', $response->json('user'));
        $this->withToken($response->json('token'))->getJson('/api/auth/me')->assertOk();

        $this->postJson('/api/auth/facebook', ['access_token' => self::TOKEN])
            ->assertOk()->assertJsonStructure(['token', 'user'])
            ->assertJsonPath('user.id', $user->id);
    }

    public function test_it_checks_the_token_with_our_app_secret(): void
    {
        $this->postJson('/api/auth/facebook', ['access_token' => self::TOKEN])->assertOk();

        Http::assertSent(fn (Request $r) => str_contains($r->url(), '/debug_token')
            && $r['input_token'] === self::TOKEN
            && $r['access_token'] === self::APP_ID.'|'.self::SECRET);
        Http::assertSent(fn (Request $r) => str_contains($r->url(), '/me')
            && $r['appsecret_proof'] === hash_hmac('sha256', self::TOKEN, self::SECRET));
    }

    public function test_an_existing_email_account_is_linked_and_signed_in(): void
    {
        $user = $this->makeUser(['email' => 'kavya.fb@example.com']);

        $this->postJson('/api/auth/facebook', ['access_token' => self::TOKEN])
            ->assertOk()->assertJsonPath('user.id', $user->id);
        $this->assertSame(self::FB_USER, $user->fresh()->facebook_id);
    }

    public function test_tokens_for_another_app_or_invalid_tokens_are_rejected(): void
    {
        $this->debug = ['data' => ['app_id' => '999', 'is_valid' => true, 'user_id' => self::FB_USER]];
        $this->postJson('/api/auth/facebook', ['access_token' => self::TOKEN])->assertStatus(401);

        $this->debug = ['data' => ['app_id' => self::APP_ID, 'is_valid' => false, 'user_id' => self::FB_USER]];
        $this->postJson('/api/auth/facebook', ['access_token' => self::TOKEN])->assertStatus(401);

        $this->debug = ['data' => ['app_id' => self::APP_ID, 'is_valid' => true, 'user_id' => self::FB_USER]];
        $this->me['id'] = 'someone-else';
        $this->postJson('/api/auth/facebook', ['access_token' => self::TOKEN])->assertStatus(401);

        $this->assertDatabaseCount('users', 0);
    }

    public function test_an_account_without_email_is_told_to_use_email_sign_up(): void
    {
        unset($this->me['email']);

        $this->postJson('/api/auth/facebook', ['access_token' => self::TOKEN])
            ->assertStatus(422)
            ->assertJsonPath('message', 'Your Facebook account has no email address we can use. Please sign up with email instead.');
    }

    public function test_suspended_accounts_cannot_sign_in_with_facebook(): void
    {
        $this->makeUser(['email' => 'kavya.fb@example.com', 'status' => 'suspended']);

        $this->postJson('/api/auth/facebook', ['access_token' => self::TOKEN])->assertForbidden();
    }

    public function test_it_says_so_when_facebook_is_not_configured(): void
    {
        config(['shareloop.facebook.app_secret' => '']);

        $this->postJson('/api/auth/facebook', ['access_token' => self::TOKEN])
            ->assertStatus(503)->assertJsonPath('message', 'Facebook sign-in is not set up on the server yet.');
    }
}
