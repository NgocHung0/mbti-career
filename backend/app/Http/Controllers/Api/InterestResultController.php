<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\MbtiQuestion;
use App\Models\InterestResult;
use Illuminate\Http\Request;

class InterestResultController extends Controller
{
    public function store(Request $request)
    {
        $data = $request->validate([
            'answers' => ['required', 'array']
        ]);

        $answers = $data['answers'];

        $questions = MbtiQuestion::whereIn('id', array_keys($answers))
            ->get()
            ->keyBy('id');

        $rawScores = [
            'TEAM' => 0,
            'INDIVIDUAL' => 0,
            'ART' => 0,
            'CREATIVE' => 0,
            'TECH' => 0,
            'HUMAN' => 0,
            'STRUCTURE' => 0,
            'FREEDOM' => 0,
        ];

        $dirMap = [
            'E' => 'TEAM',
            'I' => 'INDIVIDUAL',
            'S' => 'ART',
            'N' => 'CREATIVE',
            'T' => 'TECH',
            'F' => 'HUMAN',
            'J' => 'STRUCTURE',
            'P' => 'FREEDOM',
        ];

        foreach ($answers as $questionId => $answer) {
            $question = $questions->get((int) $questionId);

            if (!$question) continue;

            $answer = strtoupper((string) $answer);

            $axis = strtoupper((string) ($question->axis ?? ''));
            $parts = array_map('trim', explode('/', $axis));

            if (count($parts) !== 2) continue;

            $selectedDir = $answer === 'A' ? $parts[0] : $parts[1];
            $key = $dirMap[$selectedDir] ?? null;

            if ($key && isset($rawScores[$key])) {
                $rawScores[$key]++;
            }
        }

        $total = array_sum($rawScores);
        if ($total <= 0) {
            $total = 1;
        }

        $groupScores = [
            'creative' => (int) round((($rawScores['CREATIVE'] + $rawScores['ART'] + $rawScores['FREEDOM']) / $total) * 100),
            'analytic' => (int) round((($rawScores['TECH'] + $rawScores['INDIVIDUAL']) / $total) * 100),
            'social' => (int) round((($rawScores['HUMAN'] + $rawScores['TEAM']) / $total) * 100),
            'business' => (int) round((($rawScores['STRUCTURE']) / $total) * 100),
        ];

        $topGroups = collect($groupScores)
            ->map(fn ($v, $k) => [
                'key' => $k,
                'value' => $v
            ])
            ->sortByDesc('value')
            ->values()
            ->all();

        $result = InterestResult::create([
            'user_id' => $request->user()->id,
            'answers' => $answers,
            'raw_scores' => $rawScores,
            'group_scores' => $groupScores,
            'top_groups' => $topGroups
        ]);

        return response()->json([
            'message' => 'Interest result saved successfully',
            'data' => $result
        ]);
    }

    public function latest(Request $request)
    {
        $result = InterestResult::where('user_id',$request->user()->id)
            ->latest()
            ->first();

        return response()->json($result);
    }
}