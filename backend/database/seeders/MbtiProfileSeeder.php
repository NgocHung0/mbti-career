<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\MbtiProfile;

class MbtiProfileSeeder extends Seeder
{
    public function run(): void
    {
        $items = [
            ['code' => 'INTJ', 'name' => 'Kiến trúc sư', 'description' => 'Tư duy chiến lược, độc lập và thích lập kế hoạch dài hạn.'],
            ['code' => 'INTP', 'name' => 'Nhà tư duy', 'description' => 'Yêu thích phân tích, logic và khám phá ý tưởng mới.'],
            ['code' => 'ENTJ', 'name' => 'Người chỉ huy', 'description' => 'Quyết đoán, có tố chất lãnh đạo và định hướng mục tiêu rõ ràng.'],
            ['code' => 'ENTP', 'name' => 'Người tranh biện', 'description' => 'Nhanh trí, thích thử cái mới và phản biện sắc bén.'],

            ['code' => 'INFJ', 'name' => 'Người cố vấn', 'description' => 'Sâu sắc, đồng cảm và có tầm nhìn định hướng cho người khác.'],
            ['code' => 'INFP', 'name' => 'Người hòa giải', 'description' => 'Lý tưởng, sáng tạo và sống theo giá trị cá nhân.'],
            ['code' => 'ENFJ', 'name' => 'Người dẫn dắt', 'description' => 'Truyền cảm hứng, quan tâm người khác và giao tiếp tốt.'],
            ['code' => 'ENFP', 'name' => 'Người truyền cảm hứng', 'description' => 'Nhiệt huyết, sáng tạo và giàu năng lượng tích cực.'],

            ['code' => 'ISTJ', 'name' => 'Người trách nhiệm', 'description' => 'Cẩn thận, thực tế và coi trọng sự ổn định.'],
            ['code' => 'ISFJ', 'name' => 'Người bảo vệ', 'description' => 'Chu đáo, tận tâm và luôn quan tâm đến tập thể.'],
            ['code' => 'ESTJ', 'name' => 'Người điều hành', 'description' => 'Tổ chức tốt, thực tế và thích quản lý công việc rõ ràng.'],
            ['code' => 'ESFJ', 'name' => 'Người quan tâm', 'description' => 'Hòa đồng, trách nhiệm và thích hỗ trợ mọi người.'],

            ['code' => 'ISTP', 'name' => 'Nhà thực nghiệm', 'description' => 'Linh hoạt, thích xử lý tình huống thực tế và công cụ kỹ thuật.'],
            ['code' => 'ISFP', 'name' => 'Người nghệ sĩ', 'description' => 'Nhạy cảm, yêu cái đẹp và sống thiên về trải nghiệm.'],
            ['code' => 'ESTP', 'name' => 'Người thực thi', 'description' => 'Năng động, thích hành động và xử lý nhanh tình huống.'],
            ['code' => 'ESFP', 'name' => 'Người trình diễn', 'description' => 'Vui vẻ, cởi mở và thích kết nối với mọi người.'],
        ];

        foreach ($items as $item) {
            MbtiProfile::updateOrCreate(
                ['code' => $item['code']],
                $item
            );
        }
    }
}