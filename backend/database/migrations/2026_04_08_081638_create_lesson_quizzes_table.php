<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('lesson_quizzes', function (Blueprint $table) {
            $table->id();

            $table->foreignId('lesson_id')
                ->constrained('package_lessons')
                ->cascadeOnDelete();

            $table->text('question');

            $table->text('option_a');
            $table->text('option_b');
            $table->text('option_c')->nullable();
            $table->text('option_d')->nullable();

            $table->string('correct_answer', 1);
            $table->unsignedInteger('sort_order')->default(1);

            $table->timestamps();

            $table->index(['lesson_id', 'sort_order']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('lesson_quizzes');
    }
};