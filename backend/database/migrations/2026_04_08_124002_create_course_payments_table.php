<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('course_payments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->unsignedBigInteger('course_id');
            $table->decimal('amount', 12, 2)->default(0);
            $table->string('status')->default('paid');
            $table->string('payment_method')->default('manual_qr');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('course_payments');
    }
};