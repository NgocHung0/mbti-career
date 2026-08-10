<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('package_lessons', function (Blueprint $table) {
            $table->text('video_url')->nullable()->change();
            $table->text('media_url')->nullable()->change();
            $table->string('duration')->nullable()->change();
            $table->text('description')->nullable()->change();
        });
    }

    public function down(): void
    {
        Schema::table('package_lessons', function (Blueprint $table) {
            $table->text('video_url')->nullable(false)->change();
            $table->text('media_url')->nullable(false)->change();
            $table->string('duration')->nullable(false)->change();
            $table->text('description')->nullable(false)->change();
        });
    }
};