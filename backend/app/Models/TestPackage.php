<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TestPackage extends Model
{
    protected $table = 'service_packages';

    protected $fillable = [
        'name',
        'slug',
        'category',
        'price',
        'short_description',
        'description',
        'badge_text',
        'theme',
        'sort_order',
        'is_active',
        'is_featured',
        'include_interest_test',
        'include_ability_test',
    ];

    protected $casts = [
        'price' => 'decimal:2',
        'sort_order' => 'integer',
        'is_active' => 'boolean',
        'is_featured' => 'boolean',
        'include_interest_test' => 'boolean',
        'include_ability_test' => 'boolean',
    ];
}