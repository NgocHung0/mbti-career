<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\MbtiQuestion;
use App\Models\MbtiResult;

class MbtiController extends Controller
{
    public function questions()
    {
        $questions = MbtiQuestion::query()
            ->orderBy('order')
            ->get([
                'id',
                'content',
                'axis',
                'dir_a',
                'dir_b',
                'label_a',
                'label_b',
                'order',
            ])
            ->map(function ($item) {
                return [
                    'id' => (int) $item->id,
                    'question' => $item->content,
                    'optionA' => $item->label_a,
                    'optionB' => $item->label_b,
                    'axis' => $this->normalizeAxis($item->axis),
                    'dirA' => strtoupper((string) $item->dir_a),
                    'dirB' => strtoupper((string) $item->dir_b),
                    'order' => (int) $item->order,
                    'section' => 'mbti',
                ];
            })
            ->values();

        return response()->json([
            'questions' => $questions,
        ]);
    }

    public function submit(Request $request)
    {
        $data = $request->validate([
            'answers' => ['required', 'array', 'min:1'],
            'answers.*.question_id' => ['required', 'integer', 'exists:mbti_questions,id'],
            'answers.*.choice' => ['required', 'in:a,b'],
        ]);

        $answers = $data['answers'];

        $scores = [
            'E' => 0, 'I' => 0,
            'S' => 0, 'N' => 0,
            'T' => 0, 'F' => 0,
            'J' => 0, 'P' => 0,
        ];

        $questionIds = collect($answers)->pluck('question_id')->all();

        $questions = MbtiQuestion::whereIn('id', $questionIds)
            ->get()
            ->keyBy('id');

        foreach ($answers as $answer) {
            $question = $questions[$answer['question_id']] ?? null;

            if (!$question) {
                continue;
            }

            $choice = strtolower((string) $answer['choice']);

            if ($choice === 'a') {
                $dir = strtoupper((string) $question->dir_a);
                $scores[$dir] = ($scores[$dir] ?? 0) + 1;
            } else {
                $dir = strtoupper((string) $question->dir_b);
                $scores[$dir] = ($scores[$dir] ?? 0) + 1;
            }
        }

        $type =
            (($scores['E'] ?? 0) >= ($scores['I'] ?? 0) ? 'E' : 'I') .
            (($scores['S'] ?? 0) >= ($scores['N'] ?? 0) ? 'S' : 'N') .
            (($scores['T'] ?? 0) >= ($scores['F'] ?? 0) ? 'T' : 'F') .
            (($scores['J'] ?? 0) >= ($scores['P'] ?? 0) ? 'J' : 'P');

        $descriptions = [
            'INTJ' => 'Người có tư duy chiến lược, độc lập và thích lập kế hoạch dài hạn.',
            'INTP' => 'Người thích phân tích, tò mò và yêu thích khám phá ý tưởng mới.',
            'ENTJ' => 'Người quyết đoán, có tố chất lãnh đạo và định hướng mục tiêu rõ ràng.',
            'ENTP' => 'Người sáng tạo, nhanh trí và thích tranh luận, đổi mới.',
            'INFJ' => 'Người sâu sắc, đồng cảm và có lý tưởng mạnh mẽ.',
            'INFP' => 'Người nhẹ nhàng, giàu cảm xúc và coi trọng giá trị cá nhân.',
            'ENFJ' => 'Người truyền cảm hứng, quan tâm người khác và giao tiếp tốt.',
            'ENFP' => 'Người nhiệt tình, giàu ý tưởng và thích trải nghiệm mới.',
            'ISTJ' => 'Người thực tế, trách nhiệm và làm việc có nguyên tắc.',
            'ISFJ' => 'Người tận tâm, chu đáo và luôn hỗ trợ người khác.',
            'ESTJ' => 'Người tổ chức tốt, rõ ràng và đề cao hiệu quả.',
            'ESFJ' => 'Người hòa đồng, biết quan tâm và thích tạo sự ổn định.',
            'ISTP' => 'Người linh hoạt, thực tế và giỏi xử lý tình huống.',
            'ISFP' => 'Người nhẹ nhàng, tinh tế và yêu thích sự tự do.',
            'ESTP' => 'Người năng động, thích hành động và phản ứng nhanh.',
            'ESFP' => 'Người vui vẻ, thân thiện và thích mang lại năng lượng tích cực.',
        ];

        $percentages = [
            'E' => $this->percent($scores['E'], $scores['E'] + $scores['I']),
            'I' => 100 - $this->percent($scores['E'], $scores['E'] + $scores['I']),
            'S' => $this->percent($scores['S'], $scores['S'] + $scores['N']),
            'N' => 100 - $this->percent($scores['S'], $scores['S'] + $scores['N']),
            'T' => $this->percent($scores['T'], $scores['T'] + $scores['F']),
            'F' => 100 - $this->percent($scores['T'], $scores['T'] + $scores['F']),
            'J' => $this->percent($scores['J'], $scores['J'] + $scores['P']),
            'P' => 100 - $this->percent($scores['J'], $scores['J'] + $scores['P']),
        ];

        if ($request->user()) {
            MbtiResult::create([
                'user_id' => $request->user()->id,
                'mbti_type' => $type,
                'score_e' => $scores['E'],
                'score_i' => $scores['I'],
                'score_s' => $scores['S'],
                'score_n' => $scores['N'],
                'score_t' => $scores['T'],
                'score_f' => $scores['F'],
                'score_j' => $scores['J'],
                'score_p' => $scores['P'],
                'upgrade_interest' => false,
                'upgrade_ability' => false,
                'answers' => $answers,
            ]);
        }

        return response()->json([
            'message' => 'Nộp bài thành công',
            'type' => $type,
            'description' => $descriptions[$type] ?? 'Chưa có mô tả cho nhóm tính cách này.',
            'scores' => $scores,
            'percentages' => $percentages,
            'result' => [
                'type' => $type,
                'description' => $descriptions[$type] ?? 'Chưa có mô tả cho nhóm tính cách này.',
                'scores' => $scores,
                'percentages' => $percentages,
            ],
            'can_use_interest' => false,
        ]);
    }

    private function percent(int $a, int $total): int
    {
        return $total > 0 ? (int) round(($a / $total) * 100) : 50;
    }

    private function normalizeAxis(?string $axis): string
    {
        $value = strtoupper(trim((string) $axis));

        return match ($value) {
            'EI', 'E/I' => 'E/I',
            'SN', 'S/N' => 'S/N',
            'TF', 'T/F' => 'T/F',
            'JP', 'J/P' => 'J/P',
            default => $value,
        };
    }
}