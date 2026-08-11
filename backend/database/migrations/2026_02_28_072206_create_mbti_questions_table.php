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
        $table->string('code')->nullable();
        $table->text('content');
        $table->string('axis');
        $table->string('dir_a')->nullable();
        $table->string('dir_b')->nullable();
        $table->string('label_a')->nullable();
        $table->string('label_b')->nullable();
        $table->integer('order')->default(0);
        $table->boolean('is_active')->default(true);
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
