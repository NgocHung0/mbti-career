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
    Schema::create('test_sessions', function (Blueprint $table) {
        $table->id();
        $table->string('device_id', 64);
        $table->string('package', 20)->default('basic');
        $table->string('status', 20)->default('draft'); // draft/submitted
        $table->json('answers')->nullable();            // user answers
        $table->json('vector')->nullable();             // {E:70,S:40,T:80,J:65}
        $table->string('mbti_type', 4)->nullable();     // ENTJ
        $table->timestamp('submitted_at')->nullable();
        $table->timestamps();

        $table->index(['device_id', 'status']);
    });
}

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('test_sessions');
    }
};
