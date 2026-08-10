<?php

namespace App\Services;

use App\Models\MbtiQuestion;

class MbtiService
{
    // answers: [{question_id: 1, choice: "A"|"B"}...]
    public function calculateVector(array $answers): array
    {
        $scores = ['E'=>0,'I'=>0,'S'=>0,'N'=>0,'T'=>0,'F'=>0,'J'=>0,'P'=>0];

        $ids = array_map(fn($a) => (int)($a['question_id'] ?? 0), $answers);
        $qMap = MbtiQuestion::whereIn('id', $ids)->get()->keyBy('id');

        foreach ($answers as $a) {
            $qid = (int)($a['question_id'] ?? 0);
            $choice = strtoupper((string)($a['choice'] ?? ''));
            if (!$qid || !isset($qMap[$qid]) || !in_array($choice, ['A','B'], true)) continue;

            $q = $qMap[$qid];
            $dir = $choice === 'A' ? $q->dir_a : $q->dir_b;
            if (isset($scores[$dir])) $scores[$dir]++;
        }

        return [
            'E' => $this->percent($scores['E'], $scores['E'] + $scores['I']),
            'S' => $this->percent($scores['S'], $scores['S'] + $scores['N']),
            'T' => $this->percent($scores['T'], $scores['T'] + $scores['F']),
            'J' => $this->percent($scores['J'], $scores['J'] + $scores['P']),
        ];
    }

    public function mbtiTypeFromVector(array $v): string
    {
        $E = ($v['E'] ?? 50) >= 50 ? 'E' : 'I';
        $S = ($v['S'] ?? 50) >= 50 ? 'S' : 'N';
        $T = ($v['T'] ?? 50) >= 50 ? 'T' : 'F';
        $J = ($v['J'] ?? 50) >= 50 ? 'J' : 'P';
        return $E.$S.$T.$J;
    }

    private function percent(int $a, int $total): int
    {
        return $total > 0 ? (int) round(($a / $total) * 100) : 50;
    }
}