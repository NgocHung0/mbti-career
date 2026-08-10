<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AbilityResult extends Model
{
    protected $fillable = [
        'user_id',
        'answers',
        'scores',
    ];

    protected $casts = [
        'answers' => 'array',
        'scores' => 'array',
    ];
}