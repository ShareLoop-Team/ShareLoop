<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * ShareLoop data model (ported from the former Supabase schema).
 *
 * Item:     active -> pending_handover -> completed (back to active on cancel)
 * Request:  pending -> approved | rejected
 * Exchange: pending -> completed (both parties confirmed) | cancelled
 *
 * State changes that span several rows only happen in App\Services\ExchangeService.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('categories', function (Blueprint $table) {
            $table->string('id', 40)->primary();
            $table->string('name', 60)->unique();
            $table->string('icon_name', 40)->default('category');
            $table->integer('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('items', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('donor_id')->constrained('users')->cascadeOnDelete();
            $table->string('title', 120);
            $table->text('description');
            $table->string('condition', 10);
            $table->string('category', 60);
            $table->foreign('category')->references('name')->on('categories')->cascadeOnUpdate();
            $table->string('district', 40);
            $table->string('city', 80)->default('');
            $table->json('image_paths');
            $table->string('status', 20)->default('active');
            $table->uuid('selected_request_id')->nullable()->index();
            $table->boolean('is_hidden')->default(false);
            $table->string('hidden_reason', 500)->nullable();
            $table->timestamps();

            $table->index(['is_hidden', 'created_at']);
            $table->index(['donor_id', 'created_at']);
            $table->index(['category', 'created_at']);
            $table->index(['district', 'created_at']);
        });

        Schema::create('item_requests', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('requester_id')->constrained('users')->cascadeOnDelete();
            $table->foreignUuid('item_id')->nullable()->constrained('items')->cascadeOnDelete();
            $table->string('item_name', 120)->default('');
            $table->text('description');
            $table->text('reason');
            $table->text('notes');
            $table->string('category', 60);
            $table->foreign('category')->references('name')->on('categories')->cascadeOnUpdate();
            $table->string('district', 40);
            $table->string('city', 80)->default('');
            $table->string('status', 20)->default('pending');
            $table->boolean('is_hidden')->default(false);
            $table->timestamps();

            // One request per requester per give-away item (NULL item_id = standalone need).
            $table->unique(['requester_id', 'item_id'], 'item_requests_one_per_item');
            $table->index(['is_hidden', 'created_at']);
            $table->index(['item_id', 'created_at']);
        });

        Schema::table('items', function (Blueprint $table) {
            $table->foreign('selected_request_id')->references('id')->on('item_requests')->nullOnDelete();
        });

        // Kept (with a title snapshot) if the item or request is deleted later,
        // so donation counts and ratings keep their history.
        Schema::create('exchanges', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('item_id')->nullable()->constrained('items')->nullOnDelete();
            $table->foreignUuid('request_id')->nullable()->constrained('item_requests')->nullOnDelete();
            $table->string('item_title', 120);
            $table->foreignUuid('donor_id')->constrained('users')->cascadeOnDelete();
            $table->foreignUuid('requester_id')->constrained('users')->cascadeOnDelete();
            $table->string('status', 20)->default('pending');
            $table->timestamp('donor_confirmed_at')->nullable();
            $table->timestamp('requester_confirmed_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamp('cancelled_at')->nullable();
            $table->uuid('cancelled_by')->nullable();
            $table->timestamps();

            $table->index(['item_id', 'status']);
            $table->index(['donor_id', 'created_at']);
            $table->index(['requester_id', 'created_at']);
        });

        Schema::create('ratings', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('exchange_id')->constrained('exchanges')->cascadeOnDelete();
            $table->foreignUuid('item_id')->nullable()->constrained('items')->nullOnDelete();
            $table->foreignUuid('rater_id')->constrained('users')->cascadeOnDelete();
            $table->foreignUuid('ratee_id')->constrained('users')->cascadeOnDelete();
            $table->unsignedTinyInteger('stars');
            $table->text('comment');
            $table->timestamps();

            $table->unique(['exchange_id', 'rater_id']);
            $table->index(['ratee_id', 'created_at']);
        });

        Schema::create('reports', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('reporter_id')->constrained('users')->cascadeOnDelete();
            $table->foreignUuid('item_id')->nullable()->constrained('items')->cascadeOnDelete();
            $table->foreignUuid('request_id')->nullable()->constrained('item_requests')->cascadeOnDelete();
            $table->foreignUuid('reported_user_id')->nullable()->constrained('users')->cascadeOnDelete();
            $table->string('reason', 30);
            $table->text('details');
            $table->string('status', 20)->default('open');
            $table->foreignUuid('resolved_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('resolved_at')->nullable();
            $table->text('resolution_note')->nullable();
            $table->timestamps();

            $table->index(['status', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('reports');
        Schema::dropIfExists('ratings');
        Schema::dropIfExists('exchanges');
        Schema::table('items', function (Blueprint $table) {
            $table->dropForeign(['selected_request_id']);
        });
        Schema::dropIfExists('item_requests');
        Schema::dropIfExists('items');
        Schema::dropIfExists('categories');
    }
};
