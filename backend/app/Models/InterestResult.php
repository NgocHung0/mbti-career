<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class InterestResult extends Model
{
    protected $fillable = [
        'user_id',
        'answers',
        'raw_scores',
        'group_scores',
        'top_groups',
    ];

    protected $casts = [
        'answers' => 'array',
        'raw_scores' => 'array',
        'group_scores' => 'array',
        'top_groups' => 'array',
    ];
}