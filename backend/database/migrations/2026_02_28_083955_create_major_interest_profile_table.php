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
        Schema::create('major_interest_profile', function (Blueprint $table) {
        $table->id();
        $table->foreignId('major_id')->constrained('majors')->cascadeOnDelete();
        $table->foreignId('tag_id')->constrained('interest_tags')->cascadeOnDelete();
        $table->unsignedTinyInteger('weight'); // 0-100
        $table->timestamps();

        $table->unique(['major_id', 'tag_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('major_interest_profile');
    }
};
