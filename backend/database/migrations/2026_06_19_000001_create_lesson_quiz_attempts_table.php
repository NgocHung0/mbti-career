<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('lesson_quiz_attempts')) {
            return;
        }

        Schema::create('lesson_quiz_attempts', function (Blueprint $table) {
            $table->id();

            $table->foreignId('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->foreignId('lesson_id')
                ->constrained('package_lessons')
                ->cascadeOnDelete();

            $table->foreignId('quiz_id')
                ->constrained('lesson_quizzes')
                ->cascadeOnDelete();

            $table->string('selected_answer', 1);
            $table->string('correct_answer', 1);
            $table->boolean('is_correct')->default(false);
            $table->timestamp('answered_at')->nullable();

            $table->timestamps();

            $table->unique(['user_id', 'quiz_id']);
            $table->index(['user_id', 'lesson_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('lesson_quiz_attempts');
    }
};