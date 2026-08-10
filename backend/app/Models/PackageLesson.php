<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class PackageLesson extends Model
{
    protected $table = 'package_lessons';

    protected $fillable = [
        'service_package_id',
        'title',
        'description',
        'content_type',
        'video_url',
        'media_url',
        'duration',
        'sort_order',
        'is_active',
    ];

    protected $casts = [
        'sort_order' => 'integer',
        'is_active' => 'boolean',
    ];

    public function servicePackage(): BelongsTo
    {
        return $this->belongsTo(ServicePackage::class, 'service_package_id');
    }

    public function quizzes(): HasMany
    {
        return $this->hasMany(LessonQuiz::class, 'lesson_id')
            ->orderBy('sort_order')
            ->orderBy('id');
    }
}