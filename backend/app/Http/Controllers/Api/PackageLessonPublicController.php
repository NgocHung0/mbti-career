<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PackageLesson;
use Illuminate\Http\JsonResponse;

class PackageLessonPublicController extends Controller
{
    public function index(): JsonResponse
    {
        $lessons = PackageLesson::query()
            ->orderBy('sort_order')
            ->orderBy('id')
            ->get([
                'id',
                'course_id',
                'title',
                'description',
                'video_url',
                'duration',
                'sort_order',
                'is_active',
            ]);

        return response()->json([
            'lessons' => $lessons,
        ]);
    }
}