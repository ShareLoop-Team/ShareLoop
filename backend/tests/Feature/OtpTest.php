<?php

namespace Tests\Feature;

use App\Mail\OtpCodeMail;
use App\Models\User;
use Illuminate\Support\Facades\Mail;

class OtpTest extends ShareLoopTestCase
{
    /** Asks for a code through the API and returns the one that was emailed. */
    private function requestCode(string $email, string $purpose): string
    {
        Mail::fake();
        $this->postJson('/api/auth/code', ['email' => $email, 'purpose' => $purpose])->assertOk();
        $code = null;
        Mail::assertSent(OtpCodeMail::class, function (OtpCodeMail $mail) use (&$code, $email, $purpose) {
            $code = $mail->code;

            return $mail->hasTo(strtolower($email)) && $mail->purpose === $purpose;
        });

        return $code;
    }

    private function registration(string $code, array $overrides = []): array
    {
        return array_merge([
            'name' => 'Kavya', 'email' => 'kavya@example.com', 'password' => 'secret123',
            'phone' => '0712345678', 'district' => 'Kandy', 'city' => '', 'code' => $code,
        ], $overrides);
    }

    public function test_register_needs_the_emailed_code(): void
    {
        $code = $this->requestCode('Kavya@Example.com', 'register');
        $this->assertMatchesRegularExpression('/^\d{6}$/', $code);

        $this->postJson('/api/auth/register', $this->registration('', []))
            ->assertStatus(422)->assertJsonPath('message', 'Enter the code we emailed you.');
        $wrong = $code === '111111' ? '222222' : '111111';
        $this->postJson('/api/auth/register', $this->registration($wrong))
            ->assertStatus(422)->assertJsonPath('message', "That code isn't right. 4 tries left.");

        $this->postJson('/api/auth/register', $this->registration($code))
            ->assertCreated()->assertJsonPath('user.email', 'kavya@example.com');
        $this->assertNotNull(User::query()->where('email', 'kavya@example.com')->value('email_verified_at'));

        // Codes are single-use.
        $this->postJson('/api/auth/register', $this->registration($code, ['email' => 'kavya@example.com']))
            ->assertStatus(422);
    }

    public function test_a_code_for_one_email_or_purpose_does_not_work_for_another(): void
    {
        $code = $this->requestCode('a@example.com', 'register');

        $this->postJson('/api/auth/register', $this->registration($code, ['email' => 'b@example.com']))
            ->assertStatus(422);
        $this->makeUser(['email' => 'c@example.com']);
        $this->postJson('/api/auth/login-with-code', ['email' => 'a@example.com', 'code' => $code])
            ->assertStatus(422);
    }

    public function test_the_registration_form_is_checked_before_a_code_is_sent(): void
    {
        Mail::fake();

        $this->postJson('/api/auth/code', [
            'email' => 'new@example.com', 'purpose' => 'register',
            'name' => 'New', 'phone' => 'not a phone', 'district' => 'Kandy', 'password' => 'secret123',
        ])->assertStatus(422)->assertJsonValidationErrors('phone');
        Mail::assertNothingSent();
    }

    public function test_registering_an_existing_email_is_refused_before_sending(): void
    {
        Mail::fake();
        $this->makeUser(['email' => 'taken@example.com']);

        $this->postJson('/api/auth/code', ['email' => 'taken@example.com', 'purpose' => 'register'])
            ->assertStatus(422)
            ->assertJsonPath('message', 'An account already exists for that email. Please sign in.');
        Mail::assertNothingSent();
    }

    public function test_sign_in_with_a_code(): void
    {
        $user = $this->makeUser(['email' => 'nimal@example.com']);
        $code = $this->requestCode('nimal@example.com', 'login');

        $this->postJson('/api/auth/login-with-code', ['email' => 'NIMAL@example.com', 'code' => $code])
            ->assertOk()
            ->assertJsonStructure(['token', 'user'])
            ->assertJsonPath('user.id', $user->id);
    }

    public function test_login_and_reset_codes_do_not_reveal_whether_an_account_exists(): void
    {
        Mail::fake();

        $this->postJson('/api/auth/code', ['email' => 'ghost@example.com', 'purpose' => 'login'])
            ->assertOk()->assertJsonMissingPath('debug_code');
        $this->postJson('/api/auth/code', ['email' => 'ghost@example.com', 'purpose' => 'reset'])
            ->assertOk();
        Mail::assertNothingSent();
    }

    public function test_reset_password_with_a_code_signs_out_everywhere(): void
    {
        $user = $this->makeUser(['email' => 'reset@example.com', 'password' => 'old-password']);
        $user->createToken('phone');
        $code = $this->requestCode('reset@example.com', 'reset');

        $this->postJson('/api/auth/reset-password', [
            'email' => 'reset@example.com', 'code' => $code, 'password' => '123',
        ])->assertStatus(422)->assertJsonValidationErrors('password');

        $this->postJson('/api/auth/reset-password', [
            'email' => 'reset@example.com', 'code' => $code, 'password' => 'new-password',
        ])->assertOk();

        $this->assertSame(0, $user->tokens()->count());
        $this->postJson('/api/auth/login', ['email' => 'reset@example.com', 'password' => 'old-password'])
            ->assertStatus(401);
        $this->postJson('/api/auth/login', ['email' => 'reset@example.com', 'password' => 'new-password'])
            ->assertOk();
    }

    public function test_codes_expire(): void
    {
        $this->makeUser(['email' => 'late@example.com']);
        $code = $this->requestCode('late@example.com', 'login');

        $this->travel(11)->minutes();
        $this->postJson('/api/auth/login-with-code', ['email' => 'late@example.com', 'code' => $code])
            ->assertStatus(422)->assertJsonPath('message', 'That code has expired. Please request a new one.');
    }

    public function test_five_wrong_tries_burn_the_code(): void
    {
        $this->makeUser(['email' => 'guess@example.com']);
        $code = $this->requestCode('guess@example.com', 'login');
        $wrong = $code === '000000' ? '000001' : '000000';

        for ($i = 0; $i < 5; $i++) {
            $this->postJson('/api/auth/login-with-code', ['email' => 'guess@example.com', 'code' => $wrong])
                ->assertStatus(422);
        }
        $this->postJson('/api/auth/login-with-code', ['email' => 'guess@example.com', 'code' => $code])
            ->assertStatus(422)->assertJsonPath('message', 'Too many wrong codes. Please request a new one.');
    }

    public function test_a_new_code_replaces_the_old_one_and_resends_are_throttled(): void
    {
        $this->makeUser(['email' => 'twice@example.com']);
        $first = $this->requestCode('twice@example.com', 'login');

        $this->postJson('/api/auth/code', ['email' => 'twice@example.com', 'purpose' => 'login'])
            ->assertStatus(429);

        $this->travel(61)->seconds();
        $second = $this->requestCode('twice@example.com', 'login');
        if ($first !== $second) {
            $this->postJson('/api/auth/login-with-code', ['email' => 'twice@example.com', 'code' => $first])
                ->assertStatus(422);
        }
        $this->postJson('/api/auth/login-with-code', ['email' => 'twice@example.com', 'code' => $second])
            ->assertOk();
    }

    public function test_suspended_accounts_get_no_codes(): void
    {
        Mail::fake();
        $this->makeUser(['email' => 'banned@example.com', 'status' => 'suspended']);

        $this->postJson('/api/auth/code', ['email' => 'banned@example.com', 'purpose' => 'login'])
            ->assertForbidden();
        Mail::assertNothingSent();
    }

    public function test_the_email_shows_the_code(): void
    {
        $html = (new OtpCodeMail('482913', 'register', 10))->render();

        $this->assertStringContainsString('482913', $html);
        $this->assertStringContainsString('finish creating your ShareLoop account', $html);
        $this->assertStringContainsString('expires in 10 minutes', $html);
    }

    public function test_failed_delivery_gives_a_friendly_error_and_no_code(): void
    {
        Mail::shouldReceive('to')->andThrow(new \RuntimeException('SMTP down'));

        $this->postJson('/api/auth/code', ['email' => 'new@example.com', 'purpose' => 'register'])
            ->assertStatus(503)
            ->assertJsonPath('message', "We couldn't send the email right now. Please try again in a minute.");
        $this->assertDatabaseCount('email_otps', 0);
    }
}
