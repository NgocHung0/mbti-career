<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('mbti_results', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();

            $table->string('mbti_type', 4);

            $table->unsignedInteger('score_e')->default(0);
            $table->unsignedInteger('score_i')->default(0);
            $table->unsignedInteger('score_s')->default(0);
            $table->unsignedInteger('score_n')->default(0);
            $table->unsignedInteger('score_t')->default(0);
            $table->unsignedInteger('score_f')->default(0);
            $table->unsignedInteger('score_j')->default(0);
            $table->unsignedInteger('score_p')->default(0);

            $table->json('upgrades')->nullable();

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('mbti_results');
    }
};