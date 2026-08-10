<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MbtiPaymentOrder extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'package_id',
        'order_code',
        'payment_link_id',
        'amount',
        'status',
        'checkout_url',
        'qr_code',
        'provider_raw',
        'paid_at',
    ];

    protected $casts = [
        'amount' => 'integer',
        'provider_raw' => 'array',
        'paid_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function package(): BelongsTo
    {
        return $this->belongsTo(TestPackage::class, 'package_id');
    }
}
