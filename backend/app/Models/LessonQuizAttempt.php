<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class LessonQuizAttempt extends Model
{
    protected $table = 'lesson_quiz_attempts';

    protected $fillable = [
        'user_id',
        'lesson_id',
        'quiz_id',
        'selected_answer',
        'correct_answer',
        'is_correct',
        'answered_at',
    ];

    protected $casts = [
        'is_correct' => 'boolean',
        'answered_at' => 'datetime',
    ];

    public function lesson(): BelongsTo
    {
        return $this->belongsTo(CourseLesson::class, 'lesson_id');
    }

    public function quiz(): BelongsTo
    {
        return $this->belongsTo(LessonQuiz::class, 'quiz_id');
    }
}