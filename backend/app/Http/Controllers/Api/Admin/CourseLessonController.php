<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Course;
use App\Models\CourseLesson;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CourseLessonController extends Controller
{
    public function index(Course $course): JsonResponse
    {
        $lessons = CourseLesson::query()
            ->where('course_id', $course->id)
            ->orderBy('sort_order')
            ->orderBy('id')
            ->get();

        return response()->json([
            'course' => [
                'id' => $course->id,
                'name' => $course->name,
            ],
            'lessons' => $lessons,
        ]);
    }

    public function store(Request $request, Course $course): JsonResponse
    {
        $validated = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'video_url' => ['nullable', 'string', 'max:500'],
            'duration' => ['nullable', 'string', 'max:255'],
            'sort_order' => ['nullable', 'integer', 'min:1'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $lesson = CourseLesson::query()->create([
            'course_id' => $course->id,
            'title' => trim($validated['title']),
            'description' => $validated['description'] ?? null,
            'content_type' => 'video',
            'video_url' => $validated['video_url'] ?? null,
            'media_url' => null,
            'duration' => $validated['duration'] ?? null,
            'sort_order' => $validated['sort_order']
                ?? ((CourseLesson::query()
                    ->where('course_id', $course->id)
                    ->max('sort_order') ?? 0) + 1),
            'is_active' => $validated['is_active'] ?? true,
        ]);

        return response()->json([
            'message' => 'Tạo bài học thành công.',
            'lesson' => $lesson,
        ], 201);
    }

    public function update(Request $request, Course $course, CourseLesson $lesson): JsonResponse
    {
        if ((int) $lesson->course_id !== (int) $course->id) {
            return response()->json([
                'message' => 'Bài học không thuộc khóa học này.',
            ], 404);
        }

        $validated = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'video_url' => ['nullable', 'string', 'max:500'],
            'duration' => ['nullable', 'string', 'max:255'],
            'sort_order' => ['nullable', 'integer', 'min:1'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $lesson->update([
            'title' => trim($validated['title']),
            'description' => $validated['description'] ?? null,
            'video_url' => $validated['video_url'] ?? null,
            'duration' => $validated['duration'] ?? null,
            'sort_order' => $validated['sort_order'] ?? $lesson->sort_order,
            'is_active' => $validated['is_active'] ?? $lesson->is_active,
        ]);

        return response()->json([
            'message' => 'Cập nhật bài học thành công.',
            'lesson' => $lesson->fresh(),
        ]);
    }

    public function destroy(Course $course, CourseLesson $lesson): JsonResponse
    {
        if ((int) $lesson->course_id !== (int) $course->id) {
            return response()->json([
                'message' => 'Bài học không thuộc khóa học này.',
            ], 404);
        }

        $lesson->delete();

        return response()->json([
            'message' => 'Xóa bài học thành công.',
        ]);
    }
}