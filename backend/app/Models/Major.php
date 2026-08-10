<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Major extends Model
{
    protected $fillable = [
        'name',
        'code',
        'description',
        'image_url',
        'career_prospects',
        'skills',

        'suitable_mbti',
        'interest_profile',
        'ability_profile',
        'top_schools',

        'status',

        'vector',
        'vector_e',
        'vector_s',
        'vector_t',
        'vector_j',
    ];

    protected $casts = [
        'suitable_mbti' => 'array',
        'interest_profile' => 'array',
        'ability_profile' => 'array',
        'top_schools' => 'array',
        'vector' => 'array',

        'vector_e' => 'integer',
        'vector_s' => 'integer',
        'vector_t' => 'integer',
        'vector_j' => 'integer',
    ];
}