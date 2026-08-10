<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('mbti_payment_orders', function (Blueprint $table) {
            if (!Schema::hasColumn('mbti_payment_orders', 'payment_link_id')) {
                $table->string('payment_link_id')->nullable()->after('order_code');
            }

            if (!Schema::hasColumn('mbti_payment_orders', 'checkout_url')) {
                $table->text('checkout_url')->nullable()->after('status');
            }

            if (!Schema::hasColumn('mbti_payment_orders', 'qr_code')) {
                $table->longText('qr_code')->nullable()->after('checkout_url');
            }

            if (!Schema::hasColumn('mbti_payment_orders', 'provider_raw')) {
                $table->json('provider_raw')->nullable()->after('qr_code');
            }

            if (!Schema::hasColumn('mbti_payment_orders', 'paid_at')) {
                $table->timestamp('paid_at')->nullable()->after('provider_raw');
            }
        });
    }

    public function down(): void
    {
        Schema::table('mbti_payment_orders', function (Blueprint $table) {
            $dropColumns = [];

            foreach ([
                'payment_link_id',
                'checkout_url',
                'qr_code',
                'provider_raw',
                'paid_at',
            ] as $column) {
                if (Schema::hasColumn('mbti_payment_orders', $column)) {
                    $dropColumns[] = $column;
                }
            }

            if (!empty($dropColumns)) {
                $table->dropColumn($dropColumns);
            }
        });
    }
};