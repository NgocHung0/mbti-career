<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Question extends Model
{
    protected $table = 'mbti_questions';

    protected $fillable = [
        'code', 'content', 'axis', 'a_label', 'b_label', 'a_score', 'b_score', 'is_active'
    ];
}