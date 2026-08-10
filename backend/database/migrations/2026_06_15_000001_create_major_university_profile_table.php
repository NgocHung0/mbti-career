<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('major_university_profile')) {
            Schema::create('major_university_profile', function (Blueprint $table) {
                $table->id();
                $table->foreignId('major_id')->constrained('majors')->cascadeOnDelete();

                $table->string('school_name');
                $table->string('city')->nullable();

                $table->unsignedTinyInteger('match_weight')->default(80);
                $table->string('source')->nullable();
                $table->text('note')->nullable();

                $table->timestamps();

                $table->unique(['major_id', 'school_name']);
                $table->index('school_name');
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('major_university_profile');
    }
};