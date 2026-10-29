<?php

namespace App\Services;

use App\Mail\OtpCodeMail;
use App\Models\EmailOtp;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;
use Throwable;

/**
 * Emails 6-digit one-time codes and checks them. Codes are stored hashed,
 * expire (config shareloop.otp.lifetime_minutes), allow a few wrong tries,
 * and are single-use. Sending a new code replaces any earlier one.
 */
class EmailOtpService
{
    /**
     * Emails a fresh code. Returns the plain code only so tests and local
     * development without a real mailer can use it; never send it to clients
     * when real email is configured.
     */
    public function send(string $email, string $purpose): string
    {
        $email = Str::lower(trim($email));
        $config = config('shareloop.otp');

        $latest = $this->latest($email, $purpose);
        if ($latest !== null && $latest->created_at->gt(now()->subSeconds($config['resend_seconds']))) {
            $wait = $config['resend_seconds'] - (int) $latest->created_at->diffInSeconds(now(), true);
            abort(429, 'Please wait '.max(1, $wait).' seconds before asking for another code.');
        }

        $code = str_pad((string) random_int(0, 10 ** $config['length'] - 1), $config['length'], '0', STR_PAD_LEFT);

        // Only the newest code counts.
        EmailOtp::query()->where('email', $email)->where('purpose', $purpose)
            ->whereNull('consumed_at')->update(['consumed_at' => now()]);
        $otp = EmailOtp::create([
            'email' => $email,
            'purpose' => $purpose,
            'code_hash' => Hash::make($code),
            'expires_at' => now()->addMinutes($config['lifetime_minutes']),
        ]);

        try {
            Mail::to($email)->send(new OtpCodeMail($code, $purpose, $config['lifetime_minutes']));
        } catch (Throwable $e) {
            $otp->delete();
            Log::error('ShareLoop: could not send OTP email', ['email' => $email, 'error' => $e->getMessage()]);
            abort(503, "We couldn't send the email right now. Please try again in a minute.");
        }

        return $code;
    }

    /** Checks [code] and uses it up. Aborts with a message the app can show. */
    public function verify(string $email, string $purpose, string $code): void
    {
        $email = Str::lower(trim($email));
        $otp = $this->latest($email, $purpose);

        if ($otp === null || $otp->consumed_at !== null) {
            abort(422, 'That code is no longer valid. Please request a new one.');
        }
        if ($otp->expires_at->isPast()) {
            abort(422, 'That code has expired. Please request a new one.');
        }
        $maxAttempts = config('shareloop.otp.max_attempts');
        if ($otp->attempts >= $maxAttempts) {
            abort(422, 'Too many wrong codes. Please request a new one.');
        }
        if (! Hash::check(trim($code), $otp->code_hash)) {
            $otp->increment('attempts');
            $left = $maxAttempts - $otp->attempts;
            abort(422, $left > 0
                ? "That code isn't right. {$left} ".($left === 1 ? 'try' : 'tries').' left.'
                : 'Too many wrong codes. Please request a new one.');
        }

        $otp->forceFill(['consumed_at' => now()])->save();
    }

    /** Whether codes can't really be emailed (log/array mailer), so the API may echo them. */
    public static function exposesCodes(): bool
    {
        return in_array(config('mail.default'), ['log', 'array'], true)
            && app()->environment(['local', 'testing']);
    }

    private function latest(string $email, string $purpose): ?EmailOtp
    {
        return EmailOtp::query()
            ->where('email', $email)
            ->where('purpose', $purpose)
            ->latest('id')
            ->first();
    }
}
