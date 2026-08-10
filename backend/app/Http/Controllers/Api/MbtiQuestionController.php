<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\MbtiQuestion;
use Illuminate\Http\Request;

class MbtiQuestionController extends Controller
{
    public function index(Request $request)
    {
        /*
         * Frontend gọi riêng:
         * package_type=free
         * package_type=plus
         * package_type=premium
         *
         * Vì vậy API chỉ trả đúng một nhóm được yêu cầu,
         * không cộng dồn các nhóm câu hỏi.
         */
        $packageType = strtolower(
            trim((string) $request->get('package_type', 'free'))
        );

        if (!in_array(
            $packageType,
            ['free', 'plus', 'premium'],
            true
        )) {
            $packageType = 'free';
        }

        $questions = MbtiQuestion::query()
            ->where('package_type', $packageType)
            ->orderBy('order', 'asc')
            ->orderBy('id', 'asc')
            ->get()
            ->map(function (MbtiQuestion $question) {
                $dirA = strtoupper(
                    trim((string) $question->dir_a)
                );

                $dirB = strtoupper(
                    trim((string) $question->dir_b)
                );

                return [
                    'id' => (int) $question->id,

                    // Số thứ tự chính thức trong bộ 86 câu.
                    'order' => (int) $question->order,

                    'question' => (string) $question->content,
                    'optionA' => (string) $question->label_a,
                    'optionB' => (string) $question->label_b,

                    /*
                     * axis dùng mã chuẩn để frontend tính điểm:
                     * E/I, CREATIVE/ANALYTIC,
                     * LANGUAGE/STRATEGIC...
                     */
                    'axis' => $dirA . '/' . $dirB,

                    /*
                     * axisLabel dùng tên tiếng Việt để hiển thị:
                     * Hướng ngoại / Hướng nội...
                     */
                    'axisLabel' => (string) $question->axis,

                    'dirA' => $dirA,
                    'dirB' => $dirB,

                    'package_type' =>
                        (string) $question->package_type,

                    'section' =>
                        (string) $question->package_type,
                ];
            })
            ->values();

        return response()->json([
            'package_type' => $packageType,
            'question_count' => $questions->count(),
            'questions' => $questions,
        ]);
    }
}