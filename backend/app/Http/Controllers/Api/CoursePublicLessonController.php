<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Course;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class CoursePublicLessonController extends Controller
{
    public function index(int $course): JsonResponse {
        if (!$this->userHasFullCourseAccess(Auth::id())) {
            return response()->json([
                'message' => 'Bạn chưa có quyền truy cập khóa học premium.',
                'lessons' => [],
            ], 403);
        }

        $courseModel = Course::query()
            ->where('is_active', 1)
            ->findOrFail($course);

        $lessons = $courseModel->lessons()
            ->with(['quizzes'])
            ->where('is_active', 1)
            ->orderBy('sort_order')
            ->orderBy('id')
            ->get();

        return response()->json([
            'course' => [
                'id' => $courseModel->id,
                'name' => $courseModel->name,
            ],

            'lessons' => $lessons->map(function ($lesson) {
                return [
                    'id' => $lesson->id,
                    'course_id' => $lesson->course_id,
                    'title' => $lesson->title,
                    'description' => $lesson->description,
                    'content_type' => $lesson->content_type,
                    'video_url' => $lesson->video_url,
                    'media_url' => $lesson->media_url,
                    'duration' => $lesson->duration,
                    'sort_order' => $lesson->sort_order,
                    'is_active' => (bool) $lesson->is_active,

                    'questions' => $lesson->quizzes->map(function ($quiz) {
                        return [
                            'id' => $quiz->id,
                            'question' => $quiz->question,
                            'explanation' => null,
                            'options' => [
                                [
                                    'content' => $quiz->option_a,
                                    'is_correct' => $quiz->correct_answer === 'A',
                                ],
                                [
                                    'content' => $quiz->option_b,
                                    'is_correct' => $quiz->correct_answer === 'B',
                                ],
                                [
                                    'content' => $quiz->option_c,
                                    'is_correct' => $quiz->correct_answer === 'C',
                                ],
                                [
                                    'content' => $quiz->option_d,
                                    'is_correct' => $quiz->correct_answer === 'D',
                                ],
                            ],
                        ];
                    })->values(),
                ];
            })->values(),
        ]);
    }

    private function userHasFullCourseAccess(?int $userId): bool
    {
        if (!$userId) {
            return false;
        }

        $role = DB::table('users')
            ->where('id', $userId)
            ->value('role');

        $role = strtolower(trim((string) $role));

        return $role === 'premium';
    }
}