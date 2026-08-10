<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CourseLesson;
use App\Models\CourseProgress;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class CourseProgressController extends Controller
{
    public function show(int $lessonId): JsonResponse
    {
        $userId = Auth::id();

        $lesson = CourseLesson::query()
            ->where('is_active', 1)
            ->findOrFail($lessonId);

        $progress = CourseProgress::query()
            ->where('user_id', $userId)
            ->where('lesson_id', $lesson->id)
            ->first();

        return response()->json([
            'progress' => [
                'lesson_id' => $lesson->id,
                'course_id' => $lesson->course_id,
                'video_progress' => $progress?->video_progress ?? 0,
                'completed' => (bool) ($progress?->completed ?? false),
                'last_watched_at' => $progress?->last_watched_at,
            ],
        ]);
    }

    public function save(Request $request): JsonResponse
    {
        $data = $request->validate([
            'lesson_id' => ['required', 'integer', 'exists:course_lessons,id'],
            'video_progress' => ['nullable', 'integer', 'min:0'],
            'completed' => ['nullable', 'boolean'],
        ]);

        $userId = Auth::id();

        $lesson = CourseLesson::query()
            ->where('is_active', 1)
            ->findOrFail($data['lesson_id']);

        $existing = CourseProgress::query()
            ->where('user_id', $userId)
            ->where('lesson_id', $lesson->id)
            ->first();

        $alreadyCompleted = (bool) ($existing?->completed ?? false);
        $newCompleted = $alreadyCompleted || (bool) ($data['completed'] ?? false);

        $progress = CourseProgress::updateOrCreate(
            [
                'user_id' => $userId,
                'lesson_id' => $lesson->id,
            ],
            [
                'course_id' => $lesson->course_id,
                'video_progress' => (int) ($data['video_progress'] ?? 0),
                'completed' => $newCompleted,
                'last_watched_at' => now(),
            ]
        );

        return response()->json([
            'message' => 'Đã lưu tiến độ bài học.',
            'progress' => $progress,
        ]);
    }

    public function history(): JsonResponse
    {
        $userId = Auth::id();

        $items = CourseProgress::query()
            ->with([
                'course:id,name,slug,short_description,thumbnail,course_major',
                'lesson:id,course_id,title,description,duration,sort_order,is_active',
            ])
            ->where('user_id', $userId)
            ->whereHas('lesson', function ($query) {
                $query->where('is_active', 1);
            })
            ->orderByDesc('last_watched_at')
            ->orderByDesc('updated_at')
            ->get();

        $histories = $items->map(function (CourseProgress $item) {
            return [
                'id' => $item->id,
                'course_id' => $item->course_id,
                'lesson_id' => $item->lesson_id,

                'course_name' => $item->course?->name ?? 'Khóa học',
                'course_major' => $item->course?->course_major,
                'course_thumbnail' => $item->course?->thumbnail,

                'lesson_title' => $item->lesson?->title ?? 'Bài học',
                'lesson_description' => $item->lesson?->description,
                'lesson_duration' => $item->lesson?->duration,

                'video_progress' => (int) ($item->video_progress ?? 0),
                'completed' => (bool) $item->completed,
                'last_watched_at' => $item->last_watched_at
                    ? $item->last_watched_at->format('Y-m-d H:i:s')
                    : null,
            ];
        })->values();

        return response()->json([
            'histories' => $histories,
            'stats' => [
                'total' => $histories->count(),
                'completed' => $histories->where('completed', true)->count(),
                'in_progress' => $histories->where('completed', false)->count(),
                'total_watch_seconds' => $histories->sum('video_progress'),
            ],
        ]);
    }
}