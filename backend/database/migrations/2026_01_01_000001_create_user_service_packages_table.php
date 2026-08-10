<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('user_service_packages', function (Blueprint $table) {
            $table->id();

            $table->foreignId('user_id')
                ->constrained()
                ->cascadeOnDelete();

            $table->foreignId('package_id')
                ->constrained('service_packages')
                ->cascadeOnDelete();

            $table->string('status')
                ->default('active');

            $table->timestamp('started_at')
                ->nullable();

            $table->timestamp('expires_at')
                ->nullable();

            $table->timestamps();

            $table->unique(['user_id','package_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('user_service_packages');
    }
};