<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\CourseLesson;
use App\Models\LessonQuiz;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LessonQuizController extends Controller
{
    public function index(CourseLesson $lesson): JsonResponse
    {
        return response()->json([
            'lesson' => [
                'id' => $lesson->id,
                'title' => $lesson->title,
            ],
            'quizzes' => $lesson->quizzes()
                ->orderBy('sort_order')
                ->orderBy('id')
                ->get(),
        ]);
    }

    public function store(Request $request, CourseLesson $lesson): JsonResponse
    {
        $validated = $request->validate([
            'question' => ['required', 'string'],
            'option_a' => ['required', 'string'],
            'option_b' => ['required', 'string'],
            'option_c' => ['nullable', 'string'],
            'option_d' => ['nullable', 'string'],
            'correct_answer' => ['required', 'in:A,B,C,D'],
            'sort_order' => ['nullable', 'integer', 'min:1'],
        ]);

        $quiz = $lesson->quizzes()->create([
            'question' => trim($validated['question']),
            'option_a' => trim($validated['option_a']),
            'option_b' => trim($validated['option_b']),
            'option_c' => isset($validated['option_c']) && trim($validated['option_c']) !== '' ? trim($validated['option_c']) : null,
            'option_d' => isset($validated['option_d']) && trim($validated['option_d']) !== '' ? trim($validated['option_d']) : null,
            'correct_answer' => $validated['correct_answer'],
            'sort_order' => $validated['sort_order'] ?? (($lesson->quizzes()->max('sort_order') ?? 0) + 1),
        ]);

        return response()->json([
            'message' => 'Tạo câu hỏi thành công.',
            'quiz' => $quiz,
        ], 201);
    }

    public function update(Request $request, CourseLesson $lesson, LessonQuiz $quiz): JsonResponse
    {
        if ((int) $quiz->lesson_id !== (int) $lesson->id) {
            return response()->json([
                'message' => 'Câu hỏi không thuộc bài học này.',
            ], 404);
        }

        $validated = $request->validate([
            'question' => ['required', 'string'],
            'option_a' => ['required', 'string'],
            'option_b' => ['required', 'string'],
            'option_c' => ['nullable', 'string'],
            'option_d' => ['nullable', 'string'],
            'correct_answer' => ['required', 'in:A,B,C,D'],
            'sort_order' => ['nullable', 'integer', 'min:1'],
        ]);

        $quiz->update([
            'question' => trim($validated['question']),
            'option_a' => trim($validated['option_a']),
            'option_b' => trim($validated['option_b']),
            'option_c' => isset($validated['option_c']) && trim($validated['option_c']) !== '' ? trim($validated['option_c']) : null,
            'option_d' => isset($validated['option_d']) && trim($validated['option_d']) !== '' ? trim($validated['option_d']) : null,
            'correct_answer' => $validated['correct_answer'],
            'sort_order' => $validated['sort_order'] ?? $quiz->sort_order,
        ]);

        return response()->json([
            'message' => 'Cập nhật câu hỏi thành công.',
            'quiz' => $quiz->fresh(),
        ]);
    }

    public function destroy(CourseLesson $lesson, LessonQuiz $quiz): JsonResponse
    {
        if ((int) $quiz->lesson_id !== (int) $lesson->id) {
            return response()->json([
                'message' => 'Câu hỏi không thuộc bài học này.',
            ], 404);
        }

        $quiz->delete();

        return response()->json([
            'message' => 'Xóa câu hỏi thành công.',
        ]);
    }
}