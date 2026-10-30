<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/** Links an account to a Facebook account ("Continue with Facebook"). */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('facebook_id', 64)->nullable()->unique()->after('google_id');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropUnique(['facebook_id']);
            $table->dropColumn('facebook_id');
        });
    }
};
