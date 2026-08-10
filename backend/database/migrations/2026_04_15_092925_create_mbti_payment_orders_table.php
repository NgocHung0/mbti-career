<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('mbti_payment_orders', function (Blueprint $table) {
            $table->id();

            $table->foreignId('user_id')->constrained()->cascadeOnDelete();

            // dùng đúng bảng của project
            $table->foreignId('package_id')
                  ->constrained('service_packages')
                  ->cascadeOnDelete();

            $table->unsignedBigInteger('order_code')->unique();

            $table->string('payment_link_id')->nullable();

            $table->unsignedBigInteger('amount');

            $table->string('status')->default('PENDING');

            $table->json('provider_raw')->nullable();

            $table->timestamp('paid_at')->nullable();

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('mbti_payment_orders');
    }
};