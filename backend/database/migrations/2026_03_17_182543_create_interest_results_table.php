<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('interest_results', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();

            $table->json('answers');
            $table->json('raw_scores');
            $table->json('group_scores');
            $table->json('top_groups');

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('interest_results');
    }
};