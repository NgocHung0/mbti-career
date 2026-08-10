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
        Schema::create('about_settings', function (Blueprint $table) {
            $table->id();

            $table->string('hero_title')->nullable();
            $table->text('short_description')->nullable();
            $table->longText('full_description')->nullable();

            $table->string('mission_title')->nullable();
            $table->text('mission_description')->nullable();

            $table->string('vision_title')->nullable();
            $table->text('vision_description')->nullable();

            $table->string('banner_image')->nullable();
            $table->string('secondary_image')->nullable();

            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('about_settings');
    }
};
