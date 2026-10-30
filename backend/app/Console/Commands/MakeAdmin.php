<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;

class MakeAdmin extends Command
{
    protected $signature = 'shareloop:make-admin {email : Email of an existing account} {--revoke : Remove admin rights instead}';

    protected $description = 'Give (or take away) admin rights for a ShareLoop account';

    public function handle(): int
    {
        $user = User::query()->where('email', strtolower($this->argument('email')))->first();
        if ($user === null) {
            $this->error('No account with that email. Register in the app first.');

            return self::FAILURE;
        }
        $user->forceFill(['is_admin' => ! $this->option('revoke')])->save();
        $this->info($user->email.($user->is_admin ? ' is now an admin.' : ' is no longer an admin.'));

        return self::SUCCESS;
    }
}
