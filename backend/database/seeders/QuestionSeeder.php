<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Question;

class QuestionSeeder extends Seeder
{
    public function run(): void
    {
        $fullPath = base_path('storage/app/seed/questions.csv');

        if (!file_exists($fullPath)) {
            $this->command?->error("Không tìm thấy file: $fullPath");
            return;
        }

        $csv = file_get_contents($fullPath);
        $lines = preg_split("/\r\n|\n|\r/", trim($csv));

        if (!$lines || count($lines) < 2) {
            $this->command?->error("CSV trống hoặc thiếu dữ liệu.");
            return;
        }

        $header = str_getcsv(array_shift($lines));
        $header = array_map('trim', $header);

        $count = 0;

        foreach ($lines as $line) {
            if (trim($line) === '') continue;

            $row = str_getcsv($line);
            if (count($row) !== count($header)) continue;

            $data = array_combine($header, $row);

            Question::updateOrCreate(
                ['code' => $data['code']],
                [
                    'axis' => $data['axis'],
                    'content' => $data['content'],
                    'a_label' => $data['a_label'],
                    'b_label' => $data['b_label'],
                    'a_score' => (int)$data['a_score'],
                    'b_score' => (int)$data['b_score'],
                    'is_active' => true,
                ]
            );

            $count++;
        }

        $this->command?->info("Imported $count questions.");
    }
}