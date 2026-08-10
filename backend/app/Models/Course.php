<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Course extends Model
{
    protected $table = 'courses';

    protected $fillable = [
        'name',
        'slug',
        'short_description',
        'description',
        'course_major',
        'thumbnail',
        'is_active',
        'is_featured',
        'sort_order',
    ];

    protected $casts = [
        'sort_order' => 'integer',
        'is_active' => 'boolean',
        'is_featured' => 'boolean',
    ];

    public function lessons(): HasMany
    {
        return $this->hasMany(CourseLesson::class, 'course_id', 'id');
    }
}