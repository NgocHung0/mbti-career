<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Course;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Throwable;

class CoursePublicController extends Controller
{
    public function index(): JsonResponse
    {
        try {
            $userId = Auth::id();
            $hasFullAccess = $this->userHasFullCourseAccess($userId);

            $courses = Course::query()
                ->where('is_active', true)
                ->orderBy('sort_order')
                ->orderByDesc('id')
                ->get([
                    'id',
                    'name',
                    'slug',
                    'short_description',
                    'description',
                    'course_major',
                    'thumbnail',
                    'is_active',
                    'is_featured',
                    'sort_order',
                    'created_at',
                    'updated_at',
                ]);

            $courses = $courses->map(function ($course) use ($hasFullAccess) {
                return [
                    'id' => $course->id,
                    'name' => $course->name,
                    'slug' => $course->slug,
                    'short_description' => $course->short_description,
                    'description' => $course->description,
                    'course_major' => $course->course_major,
                    'thumbnail' => $course->thumbnail,
                    'is_active' => (bool) $course->is_active,
                    'is_featured' => (bool) $course->is_featured,
                    'sort_order' => $course->sort_order,
                    'created_at' => $course->created_at,
                    'updated_at' => $course->updated_at,
                    'is_purchased' => $hasFullAccess,
                    'is_locked' => !$hasFullAccess,
                ];
            })->values();

            return response()->json([
                'courses' => $courses,
                'has_full_course_access' => $hasFullAccess,
            ]);
        } catch (Throwable $e) {
            Log::error('CoursePublicController@index failed', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            return response()->json([
                'message' => 'Không tải được danh sách khóa học từ hệ thống.',
                'courses' => [],
                'has_full_course_access' => false,
                'debug_error' => config('app.debug') ? $e->getMessage() : null,
            ], 500);
        }
    }

    public function show(int $id): JsonResponse
    {
        try {
            $userId = Auth::id();
            $hasFullAccess = $this->userHasFullCourseAccess($userId);

            $course = Course::query()
                ->where('is_active', true)
                ->findOrFail($id, [
                    'id',
                    'name',
                    'slug',
                    'short_description',
                    'description',
                    'course_major',
                    'thumbnail',
                    'is_active',
                    'is_featured',
                    'sort_order',
                    'created_at',
                    'updated_at',
                ]);

            return response()->json([
                'course' => [
                    'id' => $course->id,
                    'name' => $course->name,
                    'slug' => $course->slug,
                    'short_description' => $course->short_description,
                    'description' => $course->description,
                    'course_major' => $course->course_major,
                    'thumbnail' => $course->thumbnail,
                    'is_active' => (bool) $course->is_active,
                    'is_featured' => (bool) $course->is_featured,
                    'sort_order' => $course->sort_order,
                    'created_at' => $course->created_at,
                    'updated_at' => $course->updated_at,
                    'is_purchased' => $hasFullAccess,
                    'is_locked' => !$hasFullAccess,
                ],
                'has_full_course_access' => $hasFullAccess,
            ]);
        } catch (Throwable $e) {
            Log::error('CoursePublicController@show failed', [
                'course_id' => $id,
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            return response()->json([
                'message' => 'Không tải được thông tin khóa học.',
                'debug_error' => config('app.debug') ? $e->getMessage() : null,
            ], 500);
        }
    }

    private function userHasFullCourseAccess(?int $userId): bool
    {
        if (!$userId) {
            return false;
        }

        try {
            $role = DB::table('users')
                ->where('id', $userId)
                ->value('role');

            $role = strtolower(trim((string) $role));

            return $role === 'premium';
        } catch (Throwable $e) {
            Log::warning('userHasFullCourseAccess fallback false', [
                'user_id' => $userId,
                'message' => $e->getMessage(),
            ]);

            return false;
        }
    }
}