<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ServicePackage extends Model
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

        'course_major',
        'course_level',
        'thumbnail',
        'background_image',
        'preview_video_url',
    ];

    protected $casts = [
        'price' => 'decimal:2',
        'sort_order' => 'integer',
        'is_active' => 'boolean',
        'is_featured' => 'boolean',
        'include_interest_test' => 'boolean',
        'include_ability_test' => 'boolean',
    ];

    public function lessons(): HasMany
    {
        return $this->hasMany(PackageLesson::class, 'service_package_id')
            ->orderBy('sort_order')
            ->orderBy('id');
    }
}