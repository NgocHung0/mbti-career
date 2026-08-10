<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class CourseLesson extends Model
{
    protected $table = 'course_lessons';

    protected $fillable = [
        'course_id',
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
        'course_id' => 'integer',
        'sort_order' => 'integer',
        'is_active' => 'boolean',
    ];

    public function course(): BelongsTo
    {
        return $this->belongsTo(Course::class, 'course_id');
    }

    public function quizzes(): HasMany
    {
        return $this->hasMany(LessonQuiz::class, 'lesson_id')
            ->orderBy('sort_order')
            ->orderBy('id');
    }
}