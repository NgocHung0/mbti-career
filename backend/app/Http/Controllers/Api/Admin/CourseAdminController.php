<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Course;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Throwable;

class CourseAdminController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        try {
            $keyword = trim((string) $request->query('q', ''));

            $courses = Course::query()
                ->when($keyword !== '', function ($query) use ($keyword) {
                    $query->where(function ($q) use ($keyword) {
                        $q->where('name', 'like', '%' . $keyword . '%')
                            ->orWhere('slug', 'like', '%' . $keyword . '%')
                            ->orWhere('short_description', 'like', '%' . $keyword . '%')
                            ->orWhere('description', 'like', '%' . $keyword . '%')
                            ->orWhere('course_major', 'like', '%' . $keyword . '%');
                    });
                })
                ->orderBy('sort_order')
                ->orderBy('id')
                ->get();

            return response()->json([
                'courses' => $courses,
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'message' => 'Không tải được danh sách khóa học.',
                'courses' => [],
                'debug_error' => config('app.debug') ? $e->getMessage() : null,
            ], 500);
        }
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'slug' => ['nullable', 'string', 'max:255', 'unique:courses,slug'],
            'short_description' => ['nullable', 'string'],
            'description' => ['nullable', 'string'],
            'course_major' => ['nullable', 'string', 'max:255'],
            'thumbnail' => ['nullable', 'string', 'max:255'],
            'sort_order' => ['nullable', 'integer', 'min:0'],
            'is_active' => ['nullable', 'boolean'],
            'is_featured' => ['nullable', 'boolean'],
        ]);

        $data['slug'] = $this->resolveSlug($data['slug'] ?? null, $data['name']);
        $data['sort_order'] = $data['sort_order'] ?? $this->nextSortOrder();
        $data['is_active'] = $data['is_active'] ?? true;
        $data['is_featured'] = $data['is_featured'] ?? false;

        $course = DB::transaction(function () use ($data) {
            return Course::create($data);
        });

        return response()->json([
            'message' => 'Tạo khóa học thành công.',
            'course' => $course,
        ], 201);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $course = Course::query()->findOrFail($id);

        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'slug' => [
                'nullable',
                'string',
                'max:255',
                Rule::unique('courses', 'slug')->ignore($course->id),
            ],
            'short_description' => ['nullable', 'string'],
            'description' => ['nullable', 'string'],
            'course_major' => ['nullable', 'string', 'max:255'],
            'thumbnail' => ['nullable', 'string', 'max:255'],
            'sort_order' => ['nullable', 'integer', 'min:0'],
            'is_active' => ['nullable', 'boolean'],
            'is_featured' => ['nullable', 'boolean'],
        ]);

        $data['slug'] = $this->resolveSlug($data['slug'] ?? null, $data['name'], $course->id);
        $data['sort_order'] = $data['sort_order'] ?? ($course->sort_order ?? 0);
        $data['is_active'] = $data['is_active'] ?? $course->is_active;
        $data['is_featured'] = $data['is_featured'] ?? $course->is_featured;

        $updated = DB::transaction(function () use ($course, $data) {
            $course->update($data);
            return $course->fresh();
        });

        return response()->json([
            'message' => 'Cập nhật khóa học thành công.',
            'course' => $updated,
        ]);
    }

    public function destroy(int $id): JsonResponse
    {
        $course = Course::query()->findOrFail($id);
        $course->delete();

        return response()->json([
            'message' => 'Xóa khóa học thành công.',
        ]);
    }

    private function resolveSlug(?string $slug, string $name, ?int $ignoreId = null): string
    {
        $base = Str::slug($slug ?: $name);

        if (!$base) {
            $base = 'course';
        }

        $finalSlug = $base;
        $counter = 1;

        while (
            Course::query()
                ->where('slug', $finalSlug)
                ->when($ignoreId, fn ($q) => $q->where('id', '!=', $ignoreId))
                ->exists()
        ) {
            $finalSlug = $base . '-' . $counter;
            $counter++;
        }

        return $finalSlug;
    }

    private function nextSortOrder(): int
    {
        return ((int) Course::query()->max('sort_order')) + 1;
    }
}