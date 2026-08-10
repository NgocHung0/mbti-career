<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MbtiQuestion extends Model
{
    use HasFactory;

    protected $table = 'mbti_questions';

    protected $fillable = [
        'content',
        'axis',
        'package_type',
        'dir_a',
        'dir_b',
        'label_a',
        'label_b',
        'order',
    ];
}