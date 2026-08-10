<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('major_ability_profile')) {
            Schema::create('major_ability_profile', function (Blueprint $table) {
                $table->id();
                $table->foreignId('major_id')->constrained('majors')->cascadeOnDelete();
                $table->string('ability_key', 50);
                $table->unsignedTinyInteger('weight');
                $table->timestamps();

                $table->unique(['major_id', 'ability_key']);
                $table->index('ability_key');
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('major_ability_profile');
    }
};