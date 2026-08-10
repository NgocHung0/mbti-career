<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class InterestQuestion extends Model
{
    protected $fillable = [
        'question',
        'optionA',
        'optionB',
        'axis',
        'order',
        'section',
        'package_type',
        'is_active',
    ];
}