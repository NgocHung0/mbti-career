<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class MajorUniversityProfileSeeder extends Seeder
{
    public function run(): void
    {
        $majors = DB::table('majors')->pluck('id', 'code');

        $rows = [];

        $add = function (
            string $majorCode,
            string $schoolName,
            string $city = 'TP.HCM',
            int $weight = 80,
            string $note = ''
        ) use (&$rows, $majors) {
            if (!isset($majors[$majorCode])) {
                return;
            }

            $rows[] = [
                'major_id' => (int) $majors[$majorCode],
                'school_name' => $schoolName,
                'city' => $city,
                'match_weight' => max(0, min(100, $weight)),
                'source' => 'Danh sách tuyển sinh và dữ liệu ngành hiện có trong hệ thống',
                'note' => $note,
                'created_at' => now(),
                'updated_at' => now(),
            ];
        };

        $add('CNTT', 'Đại học Công nghệ Thông tin - ĐHQG TP.HCM', 'TP.HCM', 100);
        $add('CNTT', 'Đại học Bách khoa - ĐHQG TP.HCM', 'TP.HCM', 95);
        $add('CNTT', 'Đại học FPT', 'TP.HCM', 90);
        $add('CNTT', 'Đại học Sư phạm Kỹ thuật TP.HCM', 'TP.HCM', 85);

        $add('TKDH', 'Đại học Văn Lang', 'TP.HCM', 95);
        $add('TKDH', 'Đại học Hoa Sen', 'TP.HCM', 90);
        $add('TKDH', 'Đại học FPT', 'TP.HCM', 85);
        $add('TKDH', 'Đại học Kiến trúc TP.HCM', 'TP.HCM', 85);

        $add('MKT', 'Đại học Kinh tế TP.HCM', 'TP.HCM', 95);
        $add('MKT', 'Đại học Tài chính - Marketing', 'TP.HCM', 95);
        $add('MKT', 'Đại học Hoa Sen', 'TP.HCM', 85);
        $add('MKT', 'Đại học Văn Lang', 'TP.HCM', 80);

        foreach ($rows as $row) {
            DB::table('major_university_profile')->updateOrInsert(
                [
                    'major_id' => $row['major_id'],
                    'school_name' => $row['school_name'],
                ],
                [
                    'city' => $row['city'],
                    'match_weight' => $row['match_weight'],
                    'source' => $row['source'],
                    'note' => $row['note'],
                    'updated_at' => now(),
                    'created_at' => $row['created_at'],
                ]
            );
        }
    }
}