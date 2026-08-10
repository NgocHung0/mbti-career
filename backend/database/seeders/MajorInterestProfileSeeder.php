<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class MajorInterestProfileSeeder extends Seeder
{
    public function run(): void
    {
        $tags = DB::table('interest_tags')->pluck('id', 'slug'); // slug => id
        $majors = DB::table('majors')->pluck('id', 'code');      // code => id

        $rows = [];

        $add = function (string $majorCode, string $tagSlug, int $weight) use (&$rows, $majors, $tags) {
            if (!isset($majors[$majorCode])) return;
            if (!isset($tags[$tagSlug])) return;

            $rows[] = [
                'major_id' => (int)$majors[$majorCode],
                'tag_id' => (int)$tags[$tagSlug],
                'weight' => max(0, min(100, $weight)),
                'created_at' => now(),
                'updated_at' => now(),
            ];
        };

        // ====== CORE MAP (đảm bảo đổi tag đổi top3 rõ) ======

        // SE - Kỹ thuật phần mềm
        $add('SE', 'lap-trinh', 100);
        $add('SE', 'ky-thuat-may-moc', 70);
        $add('SE', 'thiet-ke', 30);

        // DS - Khoa học dữ liệu
        $add('DS', 'lap-trinh', 85);
        $add('DS', 'tai-chinh-ke-toan', 40);
        $add('DS', 'ky-thuat-may-moc', 50);

        // GD - Thiết kế đồ họa
        $add('GD', 'thiet-ke', 100);
        $add('GD', 'truyen-thong-marketing', 80);
        $add('GD', 'kinh-doanh', 40);

        // ARCH - Kiến trúc
        $add('ARCH', 'thiet-ke', 95);
        $add('ARCH', 'ky-thuat-may-moc', 85);
        $add('ARCH', 'kinh-doanh', 20);

        // MKT - Marketing
        $add('MKT', 'truyen-thong-marketing', 100);
        $add('MKT', 'kinh-doanh', 80);
        $add('MKT', 'thiet-ke', 55);

        // BA - Quản trị kinh doanh
        $add('BA', 'kinh-doanh', 100);
        $add('BA', 'tai-chinh-ke-toan', 65);
        $add('BA', 'luat-xa-hoi', 40);

        // PSY - Tâm lý học
        $add('PSY', 'tam-ly-tu-van', 100);
        $add('PSY', 'su-pham-giao-duc', 70);
        $add('PSY', 'y-te-suc-khoe', 50);

        // EDU - Sư phạm
        $add('EDU', 'su-pham-giao-duc', 100);
        $add('EDU', 'tam-ly-tu-van', 70);
        $add('EDU', 'luat-xa-hoi', 20);

        // LAW - Luật
        $add('LAW', 'luat-xa-hoi', 100);
        $add('LAW', 'kinh-doanh', 35);
        $add('LAW', 'tai-chinh-ke-toan', 25);

        // NUR - Điều dưỡng
        $add('NUR', 'y-te-suc-khoe', 100);
        $add('NUR', 'tam-ly-tu-van', 50);
        $add('NUR', 'su-pham-giao-duc', 20);

        // Nếu bạn có ACC / FIN (tài chính kế toán) thì thêm luôn:
        $add('ACC', 'tai-chinh-ke-toan', 100);
        $add('ACC', 'kinh-doanh', 50);

        $add('FIN', 'tai-chinh-ke-toan', 100);
        $add('FIN', 'kinh-doanh', 60);

        // ====== UPSERT để chạy lại không bị duplicate ======
        foreach ($rows as $r) {
            DB::table('major_interest_profile')->updateOrInsert(
                ['major_id' => $r['major_id'], 'tag_id' => $r['tag_id']],
                ['weight' => $r['weight'], 'updated_at' => now(), 'created_at' => $r['created_at']]
            );
        }
    }
}