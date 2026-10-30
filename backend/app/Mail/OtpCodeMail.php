<?php

namespace App\Mail;

use App\Models\EmailOtp;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Address;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

/** The email carrying a one-time code. */
class OtpCodeMail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(
        public readonly string $code,
        public readonly string $purpose,
        public readonly int $minutes,
    ) {}

    public function envelope(): Envelope
    {
        return new Envelope(
            // Falls back while MAIL_FROM_ADDRESS is still blank in .env.
            from: new Address(
                config('mail.from.address') ?: 'no-reply@shareloop.test',
                config('mail.from.name') ?: 'ShareLoop',
            ),
            subject: $this->code.' is your ShareLoop code',
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'mail.otp-code',
            text: 'mail.otp-code-text',
            with: ['intro' => $this->intro()],
        );
    }

    private function intro(): string
    {
        return match ($this->purpose) {
            EmailOtp::PURPOSE_REGISTER => 'Use this code to confirm your email and finish creating your ShareLoop account.',
            EmailOtp::PURPOSE_LOGIN => 'Use this code to sign in to ShareLoop.',
            default => 'Use this code to reset your ShareLoop password.',
        };
    }
}
