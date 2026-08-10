<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\MbtiQuestion;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class InterestQuestionController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $packageType = strtolower(trim((string) $request->get('package_type', 'plus')));

        // interest của bạn đang là plus
        if ($packageType !== 'plus') {
            $packageType = 'plus';
        }

        $questions = MbtiQuestion::query()
            ->where('package_type', $packageType)
            ->orderBy('order')
            ->orderBy('id')
            ->get()
            ->map(function (MbtiQuestion $q) {
                return [
                    'id' => $q->id,
                    'question' => $q->content,
                    'optionA' => $q->label_a,
                    'optionB' => $q->label_b,
                    'axis' => $q->axis,
                    'dirA' => $q->dir_a,
                    'dirB' => $q->dir_b,
                    'order' => $q->order,
                    'section' => 'interest',
                ];
            })
            ->values();

        return response()->json([
            'questions' => $questions,
        ]);
    }
}