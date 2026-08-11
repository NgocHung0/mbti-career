<?php

namespace Database\Seeders;

use App\Models\Major;
use Illuminate\Database\Seeder;

class MajorSeeder extends Seeder
{
    public function run(): void
    {
        $items = [
            [
                'name' => 'Công nghệ thông tin',
                'code' => 'CNTT',
                'description' => 'Ngành đào tạo về lập trình, hệ thống phần mềm, dữ liệu và công nghệ số.',
                'career_prospects' => 'Lập trình viên, kiểm thử phần mềm, phân tích dữ liệu, kỹ sư hệ thống, AI engineer.',
                'skills' => 'Tư duy logic, giải quyết vấn đề, kiên trì, tự học, phân tích.',
                'suitable_mbti' => ['INTJ', 'INTP', 'ENTJ', 'ISTJ'],
                'top_schools' => ['Bách Khoa', 'CNTT - ĐHQG', 'FPT', 'UTE'],
                'status' => 'active',
                'vector_e' => 35,
                'vector_s' => 40,
                'vector_t' => 85,
                'vector_j' => 70,
            ],
            [
                'name' => 'Thiết kế đồ họa',
                'code' => 'TKDH',
                'description' => 'Ngành học về thiết kế hình ảnh, thương hiệu, truyền thông thị giác và sáng tạo nội dung.',
                'career_prospects' => 'Graphic designer, UI designer, branding designer, motion designer.',
                'skills' => 'Sáng tạo, thẩm mỹ, kể chuyện bằng hình ảnh, tư duy thị giác.',
                'suitable_mbti' => ['INFP', 'ISFP', 'ENFP', 'INFJ'],
                'top_schools' => ['Văn Lang', 'Hoa Sen', 'FPT', 'Kiến Trúc'],
                'status' => 'active',
                'vector_e' => 55,
                'vector_s' => 45,
                'vector_t' => 35,
                'vector_j' => 50,
            ],
            [
                'name' => 'Marketing',
                'code' => 'MKT',
                'description' => 'Ngành học về nghiên cứu thị trường, thương hiệu, truyền thông và chiến lược tiếp cận khách hàng.',
                'career_prospects' => 'Marketing executive, content marketer, brand executive, digital marketer.',
                'skills' => 'Giao tiếp, sáng tạo, phân tích khách hàng, bắt trend, lập kế hoạch.',
                'suitable_mbti' => ['ENFP', 'ENTP', 'ESFP', 'ENFJ'],
                'top_schools' => ['Kinh tế', 'Tài chính Marketing', 'Hoa Sen', 'UEH'],
                'status' => 'active',
                'vector_e' => 80,
                'vector_s' => 55,
                'vector_t' => 45,
                'vector_j' => 52,
            ],
        ];

        foreach ($items as $item) {
            // Tự động gom các chỉ số vector thành mảng JSON cho cột 'vector'
            $item['vector'] = [
                'e' => $item['vector_e'],
                's' => $item['vector_s'],
                't' => $item['vector_t'],
                'j' => $item['vector_j'],
            ];

            Major::updateOrCreate(
                ['code' => $item['code']],
                $item
            );
        }
    }
}