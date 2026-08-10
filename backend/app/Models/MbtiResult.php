<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MbtiResult extends Model
{
    protected $fillable = [
        'user_id',
        'mbti_type',
        'score_e',
        'score_i',
        'score_s',
        'score_n',
        'score_t',
        'score_f',
        'score_j',
        'score_p',
        'upgrade_interest',
        'upgrade_ability',
        'answers',
    ];

    protected $casts = [
        'upgrade_interest' => 'boolean',
        'upgrade_ability' => 'boolean',
        'answers' => 'array',
    ];
}