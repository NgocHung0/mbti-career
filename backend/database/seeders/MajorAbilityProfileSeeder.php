<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class MajorAbilityProfileSeeder extends Seeder
{
    public function run(): void
    {
        $majors = DB::table('majors')->pluck('id', 'code');
        $rows = [];

        $add = function (string $majorCode, string $abilityKey, int $weight) use (&$rows, $majors) {
            if (!isset($majors[$majorCode])) {
                return;
            }

            $rows[] = [
                'major_id' => (int) $majors[$majorCode],
                'ability_key' => strtoupper($abilityKey),
                'weight' => max(0, min(100, $weight)),
                'created_at' => now(),
                'updated_at' => now(),
            ];
        };

        $add('CNTT', 'LOGIC', 100);
        $add('CNTT', 'TECH', 100);
        $add('CNTT', 'PRACTICAL', 75);
        $add('CNTT', 'STRATEGIC', 70);

        $add('SE', 'LOGIC', 100);
        $add('SE', 'TECH', 100);
        $add('SE', 'PRACTICAL', 80);

        $add('DS', 'LOGIC', 100);
        $add('DS', 'TECH', 90);
        $add('DS', 'STRATEGIC', 75);

        $add('TKDH', 'CREATIVE', 100);
        $add('TKDH', 'PRACTICAL', 70);
        $add('TKDH', 'ADAPT', 65);

        $add('GD', 'CREATIVE', 100);
        $add('GD', 'PRACTICAL', 75);
        $add('GD', 'ADAPT', 65);

        $add('MKT', 'CREATIVE', 85);
        $add('MKT', 'LANGUAGE', 85);
        $add('MKT', 'TEAMWORK', 75);
        $add('MKT', 'ADAPT', 70);

        $add('BA', 'LEADERSHIP', 95);
        $add('BA', 'STRATEGIC', 90);
        $add('BA', 'TEAMWORK', 75);

        $add('ACC', 'DETAIL', 100);
        $add('ACC', 'LOGIC', 85);
        $add('ACC', 'PRACTICAL', 70);

        $add('FIN', 'LOGIC', 90);
        $add('FIN', 'DETAIL', 80);
        $add('FIN', 'STRATEGIC', 75);

        $add('LAW', 'LANGUAGE', 95);
        $add('LAW', 'LOGIC', 85);
        $add('LAW', 'DETAIL', 75);

        $add('PSY', 'LANGUAGE', 80);
        $add('PSY', 'TEAMWORK', 90);
        $add('PSY', 'ADAPT', 70);

        $add('EDU', 'LANGUAGE', 90);
        $add('EDU', 'TEAMWORK', 85);
        $add('EDU', 'LEADERSHIP', 65);

        $add('NUR', 'TEAMWORK', 90);
        $add('NUR', 'DETAIL', 85);
        $add('NUR', 'PRACTICAL', 85);

        foreach ($rows as $row) {
            DB::table('major_ability_profile')->updateOrInsert(
                [
                    'major_id' => $row['major_id'],
                    'ability_key' => $row['ability_key'],
                ],
                [
                    'weight' => $row['weight'],
                    'created_at' => $row['created_at'],
                    'updated_at' => now(),
                ]
            );
        }
    }
}