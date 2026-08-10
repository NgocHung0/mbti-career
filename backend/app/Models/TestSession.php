<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TestSession extends Model
{
    protected $fillable = [
        'user_id',
        'device_id',
        'package',
        'status',
        'answers',
        'vector',
        'interest_tags',
        'mbti_type',
        'submitted_at',
    ];

    protected $casts = [
        'answers' => 'array',
        'vector' => 'array',
        'interest_tags' => 'array',
        'submitted_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}