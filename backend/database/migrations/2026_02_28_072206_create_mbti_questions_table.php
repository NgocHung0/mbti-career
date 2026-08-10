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
Schema::create('mbti_questions', function (Blueprint $table) {
    $table->id();
    $table->string('content');
    $table->string('axis', 2);
    $table->char('dir_a', 1);
    $table->char('dir_b', 1);
    $table->string('label_a');
    $table->string('label_b');
    $table->unsignedInteger('order')->default(0);
    $table->timestamps();
});
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('mbti_questions');
    }
};
