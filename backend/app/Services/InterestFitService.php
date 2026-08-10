<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;

class InterestFitService
{
    /**
     * @param int[] $tagIds
     * @return array major_id => fit_interest (0-100)
     */
    public function calcByTags(array $tagIds): array
    {
        $tagIds = array_values(array_unique(array_map('intval', $tagIds)));
        $k = count($tagIds);
        if ($k === 0) return [];

        // Lấy mapping weights theo major cho các tag user chọn
        $rows = DB::table('major_interest_profile')
            ->select('major_id', 'tag_id', 'weight')
            ->whereIn('tag_id', $tagIds)
            ->get();

        // Group theo major
        $byMajor = [];
        foreach ($rows as $r) {
            $byMajor[$r->major_id][$r->tag_id] = (int)$r->weight;
        }

        // Tính average (tag không có mapping = 0)
        $result = [];
        foreach ($byMajor as $majorId => $map) {
            $sum = 0;
            foreach ($tagIds as $tid) {
                $sum += $map[$tid] ?? 0;
            }
            $result[$majorId] = (int) round($sum / $k);
        }

        return $result;
    }
}