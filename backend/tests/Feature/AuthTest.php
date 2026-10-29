<?php

namespace Tests\Feature;

use App\Models\User;
use App\Services\EmailOtpService;

class AuthTest extends ShareLoopTestCase
{
    private function registration(array $overrides = []): array
    {
        $email = strtolower($overrides['email'] ?? 'nimal@example.com');
        $code = User::query()->where('email', $email)->exists()
            ? '000000'
            : app(EmailOtpService::class)->send($email, 'register');
        $this->travel(61)->seconds(); // past the resend cooldown for the next call

        return array_merge([
            'code' => $code,
            'name' => 'Nimal Perera',
            'email' => 'Nimal@Example.com',
            'password' => 'secret123',
            'phone' => '0771234567',
            'district' => 'Kandy',
            'city' => 'Peradeniya',
        ], $overrides);
    }

    public function test_register_returns_a_token_and_the_full_profile(): void
    {
        $response = $this->postJson('/api/auth/register', $this->registration());

        $response->assertCreated()
            ->assertJsonStructure(['token', 'user' => ['id', 'display_name', 'email', 'phone']])
            ->assertJsonPath('user.email', 'nimal@example.com')
            ->assertJsonPath('user.phone', '0771234567')
            ->assertJsonPath('user.is_admin', false)
            ->assertJsonPath('user.status', 'active');

        $this->withToken($response->json('token'))
            ->getJson('/api/auth/me')
            ->assertOk()
            ->assertJsonPath('data.display_name', 'Nimal Perera');
    }

    public function test_register_rejects_duplicate_email_with_a_friendly_message(): void
    {
        $this->postJson('/api/auth/register', $this->registration())->assertCreated();

        $this->postJson('/api/auth/register', $this->registration(['email' => 'nimal@example.com']))
            ->assertStatus(422)
            ->assertJsonPath('message', 'An account already exists for that email. Please sign in.');
    }

    public function test_register_validates_district_phone_and_password(): void
    {
        $this->postJson('/api/auth/register', $this->registration([
            'district' => 'Atlantis', 'phone' => 'call me', 'password' => '123',
        ]))->assertStatus(422)->assertJsonValidationErrors(['district', 'phone', 'password']);
    }

    public function test_login_checks_the_password(): void
    {
        $this->makeUser(['email' => 'kavya@example.com', 'password' => 'right-password']);

        $this->postJson('/api/auth/login', ['email' => 'kavya@example.com', 'password' => 'wrong'])
            ->assertStatus(401)
            ->assertJsonPath('message', 'Incorrect email or password.');

        $this->postJson('/api/auth/login', ['email' => 'KAVYA@example.com', 'password' => 'right-password'])
            ->assertOk()
            ->assertJsonStructure(['token', 'user']);
    }

    public function test_suspended_accounts_cannot_log_in_or_use_old_tokens(): void
    {
        $user = $this->makeUser(['email' => 'x@example.com', 'password' => 'secret123']);
        $token = $user->createToken('t')->plainTextToken;
        $user->forceFill(['status' => User::STATUS_SUSPENDED])->save();

        $this->postJson('/api/auth/login', ['email' => 'x@example.com', 'password' => 'secret123'])
            ->assertStatus(403)
            ->assertJsonPath('message', 'This account has been suspended.');
        $this->withToken($token)->getJson('/api/items')->assertStatus(403);
    }

    public function test_protected_routes_need_a_token(): void
    {
        $this->getJson('/api/items')
            ->assertStatus(401)
            ->assertJsonPath('message', 'Your session has expired. Please sign in again.');
        $this->withToken('not-a-real-token')->getJson('/api/auth/me')->assertStatus(401);
    }

    public function test_logout_revokes_the_token(): void
    {
        $user = $this->makeUser();
        $token = $user->createToken('t')->plainTextToken;

        $this->withToken($token)->postJson('/api/auth/logout')->assertOk();
        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_profile_update_changes_only_editable_fields(): void
    {
        $user = $this->makeUser();

        $this->actingAsUser($user)->patchJson('/api/me', [
            'name' => 'New Name', 'phone' => '+94 77 123 4567', 'district' => 'Galle', 'city' => 'Unawatuna',
            'is_admin' => true, 'donation_count' => 99,
        ])->assertOk()
            ->assertJsonPath('data.display_name', 'New Name')
            ->assertJsonPath('data.district', 'Galle')
            ->assertJsonPath('data.is_admin', false)
            ->assertJsonPath('data.donation_count', 0);

        $this->actingAsUser($user)->patchJson('/api/me', ['district' => 'Nowhere'])->assertStatus(422);
    }
}
