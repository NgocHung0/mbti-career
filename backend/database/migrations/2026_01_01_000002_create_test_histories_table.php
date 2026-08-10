<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('test_histories', function (Blueprint $table) {

            $table->id();

            $table->foreignId('user_id')
                ->constrained()
                ->cascadeOnDelete();

            $table->string('test_session_id')->nullable()->index();

            $table->string('test_type')->default('mbti');

            $table->string('result_code')->nullable();

            $table->json('answers')->nullable();

            $table->json('questions')->nullable();

            $table->json('scores')->nullable();

            $table->json('result_payload')->nullable();

            $table->foreignId('package_id')
                ->nullable()
                ->constrained('service_packages')
                ->nullOnDelete();

            $table->string('package_name')->nullable();

            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('test_histories');
    }
};