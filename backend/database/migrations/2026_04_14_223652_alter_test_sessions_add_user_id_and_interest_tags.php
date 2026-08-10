<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('test_sessions', function (Blueprint $table) {
            if (!Schema::hasColumn('test_sessions', 'user_id')) {
                $table->foreignId('user_id')->nullable()->after('id')->constrained('users')->nullOnDelete();
            }

            if (!Schema::hasColumn('test_sessions', 'interest_tags')) {
                $table->json('interest_tags')->nullable()->after('vector');
            }

            $table->index(['user_id', 'status']);
            $table->index(['user_id', 'device_id']);
        });
    }

    public function down(): void
    {
        Schema::table('test_sessions', function (Blueprint $table) {
            if (Schema::hasColumn('test_sessions', 'user_id')) {
                $table->dropConstrainedForeignId('user_id');
            }

            if (Schema::hasColumn('test_sessions', 'interest_tags')) {
                $table->dropColumn('interest_tags');
            }
        });
    }
};