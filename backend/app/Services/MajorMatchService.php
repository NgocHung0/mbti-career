<?php

namespace App\Services;

use App\Models\Major;

class MajorMatchService
{
    public function topMajors(array $userVector, int $top = 3): array
    {
        $results = [];

        foreach (Major::all() as $major) {
            $mv = $major->vector ?? [];
            $breakdown = $this->axisBreakdown($userVector, $mv);
            $fit = (int) round(array_sum(array_column($breakdown, 'fit')) / 4);

            $results[] = [
                'id' => $major->id,
                'code' => $major->code,
                'name' => $major->name,
                'description' => $major->description,
                'fit' => $fit,
                'breakdown' => $breakdown,
            ];
        }

        usort($results, fn($a,$b) => $b['fit'] <=> $a['fit']);
        return array_slice($results, 0, $top);
    }

    private function axisBreakdown(array $u, array $m): array
    {
        $axes = ['E','S','T','J'];
        $out = [];

        foreach ($axes as $k) {
            $uv = (int)($u[$k] ?? 50);
            $mv = (int)($m[$k] ?? 50);
            $diff = abs($uv - $mv);
            $fitAxis = max(0, 100 - $diff);

            $out[$k] = [
                'user' => $uv,
                'major' => $mv,
                'diff' => $diff,
                'fit' => $fitAxis,
            ];
        }

        return $out;
    }
}