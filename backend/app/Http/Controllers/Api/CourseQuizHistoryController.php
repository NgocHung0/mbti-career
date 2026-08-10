<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CourseLesson;
use App\Models\LessonQuiz;
use App\Models\LessonQuizAttempt;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Auth;

class CourseQuizHistoryController extends Controller
{
    public function index(): JsonResponse
    {
        $userId = Auth::id();

        $attempts = LessonQuizAttempt::query()
            ->with(['quiz'])
            ->where('user_id', $userId)
            ->orderByDesc('answered_at')
            ->get();

        if ($attempts->isEmpty()) {
            return response()->json([
                'histories' => [],
            ]);
        }

        $lessonIds = $attempts->pluck('lesson_id')->unique()->values();

        $lessons = CourseLesson::query()
            ->with(['course', 'quizzes'])
            ->whereIn('id', $lessonIds)
            ->get()
            ->keyBy('id');

        $histories = $attempts
            ->groupBy('lesson_id')
            ->map(function (Collection $lessonAttempts, $lessonId) use ($lessons) {
                $lesson = $lessons->get((int) $lessonId);

                return $this->formatLessonHistory($lesson, $lessonAttempts);
            })
            ->values();

        return response()->json([
            'histories' => $histories,
        ]);
    }

    public function show(int $lessonId): JsonResponse
    {
        $userId = Auth::id();

        $lesson = CourseLesson::query()
            ->with(['course', 'quizzes'])
            ->findOrFail($lessonId);

        $attempts = LessonQuizAttempt::query()
            ->with(['quiz'])
            ->where('user_id', $userId)
            ->where('lesson_id', $lessonId)
            ->get();

        if ($attempts->isEmpty()) {
            return response()->json([
                'message' => 'Chưa có lịch sử làm bài cho bài học này.',
            ], 404);
        }

        return response()->json([
            'history' => $this->formatLessonHistory($lesson, $attempts),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'lesson_id' => ['required', 'integer', 'exists:course_lessons,id'],
            'quiz_id' => ['required', 'integer', 'exists:lesson_quizzes,id'],
            'selected_answer' => ['required', 'string', 'in:A,B,C,D'],
        ]);

        $userId = Auth::id();

        $quiz = LessonQuiz::query()
            ->where('lesson_id', $data['lesson_id'])
            ->findOrFail($data['quiz_id']);

        $selectedAnswer = strtoupper($data['selected_answer']);
        $correctAnswer = strtoupper($quiz->correct_answer);
        $isCorrect = $selectedAnswer === $correctAnswer;

        $attempt = LessonQuizAttempt::updateOrCreate(
            [
                'user_id' => $userId,
                'quiz_id' => $quiz->id,
            ],
            [
                'lesson_id' => $data['lesson_id'],
                'selected_answer' => $selectedAnswer,
                'correct_answer' => $correctAnswer,
                'is_correct' => $isCorrect,
                'answered_at' => now(),
            ]
        );

        return response()->json([
            'message' => 'Đã lưu câu trả lời.',
            'attempt' => $attempt,
        ]);
    }

    private function formatLessonHistory(?CourseLesson $lesson, Collection $attempts): array
    {
        $attempts = $attempts
            ->sortBy(function (LessonQuizAttempt $attempt) {
                $sortOrder = $attempt->quiz?->sort_order ?? 999999;
                $quizId = $attempt->quiz?->id ?? 999999;

                return sprintf('%010d-%010d', $sortOrder, $quizId);
            })
            ->values();

        $answeredCount = $attempts->count();
        $correctCount = $attempts->where('is_correct', true)->count();
        $wrongCount = $answeredCount - $correctCount;

        $totalQuestions = $lesson?->quizzes?->count() ?? $answeredCount;

        $lastAttempt = $attempts
            ->sortByDesc('answered_at')
            ->first();

        return [
            'lesson_id' => $lesson?->id ?? (int) ($attempts->first()?->lesson_id ?? 0),
            'lesson_title' => $lesson?->title ?? 'Bài học',
            'course_name' => $lesson?->course?->name ?? 'Khóa học',
            'updated_at' => $lastAttempt?->answered_at
                ? $lastAttempt->answered_at->format('Y-m-d H:i:s')
                : now()->format('Y-m-d H:i:s'),

            'total_questions' => $totalQuestions,
            'correct_count' => $correctCount,
            'wrong_count' => $wrongCount,
            'completed' => $totalQuestions > 0 && $answeredCount >= $totalQuestions,

            'questions' => $attempts->map(function (LessonQuizAttempt $attempt) {
                $quiz = $attempt->quiz;

                return [
                    'question_id' => (string) $attempt->quiz_id,
                    'question' => $quiz?->question ?? 'Câu hỏi',

                    'selected_label' => $attempt->selected_answer,
                    'selected_option_index' => $this->answerIndex($attempt->selected_answer),
                    'selected_option_content' => $this->optionContent($quiz, $attempt->selected_answer),

                    'is_correct' => (bool) $attempt->is_correct,
                    'answered_at' => $attempt->answered_at
                        ? $attempt->answered_at->format('Y-m-d H:i:s')
                        : null,

                    'options' => $this->optionList($quiz),
                ];
            })->values(),
        ];
    }

    private function optionList(?LessonQuiz $quiz): array
    {
        if (!$quiz) return [];

        return [
            [
                'label' => 'A',
                'content' => $quiz->option_a ?? '',
                'is_correct' => strtoupper($quiz->correct_answer) === 'A',
            ],
            [
                'label' => 'B',
                'content' => $quiz->option_b ?? '',
                'is_correct' => strtoupper($quiz->correct_answer) === 'B',
            ],
            [
                'label' => 'C',
                'content' => $quiz->option_c ?? '',
                'is_correct' => strtoupper($quiz->correct_answer) === 'C',
            ],
            [
                'label' => 'D',
                'content' => $quiz->option_d ?? '',
                'is_correct' => strtoupper($quiz->correct_answer) === 'D',
            ],
        ];
    }

    private function optionContent(?LessonQuiz $quiz, ?string $answer): string
    {
        if (!$quiz || !$answer) return '';

        return match (strtoupper($answer)) {
            'A' => $quiz->option_a ?? '',
            'B' => $quiz->option_b ?? '',
            'C' => $quiz->option_c ?? '',
            'D' => $quiz->option_d ?? '',
            default => '',
        };
    }

    private function answerIndex(?string $answer): int
    {
        return match (strtoupper((string) $answer)) {
            'A' => 0,
            'B' => 1,
            'C' => 2,
            'D' => 3,
            default => 0,
        };
    }
}