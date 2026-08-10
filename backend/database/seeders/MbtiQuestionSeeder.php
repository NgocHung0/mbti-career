<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\MbtiQuestion;

class MbtiQuestionSeeder extends Seeder
{
    public function run(): void
    {
        MbtiQuestion::truncate();

        $questions = [

            // ===== EI (13 câu) =====
            ['Bạn thích làm việc theo nhóm đông người hơn là một mình.', 'EI','E','I'],
            ['Bạn cảm thấy có năng lượng hơn khi giao tiếp xã hội.', 'EI','E','I'],
            ['Bạn dễ bắt chuyện với người lạ.', 'EI','E','I'],
            ['Bạn thích tham gia hoạt động ngoại khóa đông người.', 'EI','E','I'],
            ['Bạn thường nói ra suy nghĩ ngay lập tức.', 'EI','E','I'],
            ['Bạn thích môi trường học tập sôi động.', 'EI','E','I'],
            ['Bạn hay chủ động tổ chức hoạt động.', 'EI','E','I'],
            ['Bạn cảm thấy thoải mái khi trình bày trước lớp.', 'EI','E','I'],
            ['Bạn thích đi chơi nhiều hơn ở nhà.', 'EI','E','I'],
            ['Bạn dễ làm quen bạn mới.', 'EI','E','I'],
            ['Bạn thường chia sẻ cảm xúc với người khác.', 'EI','E','I'],
            ['Bạn suy nghĩ thành lời hơn là suy nghĩ trong đầu.', 'EI','E','I'],
            ['Bạn thích tham gia các sự kiện xã hội.', 'EI','E','I'],

            // ===== SN (13 câu) =====
            ['Bạn tin vào kinh nghiệm thực tế hơn là linh cảm.', 'SN','S','N'],
            ['Bạn chú ý chi tiết nhỏ trong bài học.', 'SN','S','N'],
            ['Bạn thích học theo ví dụ cụ thể.', 'SN','S','N'],
            ['Bạn quan tâm đến hiện tại hơn tương lai xa.', 'SN','S','N'],
            ['Bạn làm việc theo hướng dẫn rõ ràng.', 'SN','S','N'],
            ['Bạn tin vào điều đã được chứng minh.', 'SN','S','N'],
            ['Bạn nhớ thông tin thực tế tốt hơn ý tưởng trừu tượng.', 'SN','S','N'],
            ['Bạn thích môn học có công thức rõ ràng.', 'SN','S','N'],
            ['Bạn tập trung vào những gì đang xảy ra.', 'SN','S','N'],
            ['Bạn học tốt khi có ví dụ minh họa.', 'SN','S','N'],
            ['Bạn thích công việc có quy trình cụ thể.', 'SN','S','N'],
            ['Bạn chú ý sự kiện thực tế hơn lý thuyết.', 'SN','S','N'],
            ['Bạn đánh giá cao kinh nghiệm hơn tưởng tượng.', 'SN','S','N'],

            // ===== TF (12 câu) =====
            ['Bạn đưa ra quyết định dựa trên lý trí.', 'TF','T','F'],
            ['Bạn ưu tiên sự công bằng hơn cảm xúc.', 'TF','T','F'],
            ['Bạn thích tranh luận logic.', 'TF','T','F'],
            ['Bạn giữ bình tĩnh khi người khác xúc động.', 'TF','T','F'],
            ['Bạn phân tích vấn đề trước khi đồng cảm.', 'TF','T','F'],
            ['Bạn thích làm việc dựa trên nguyên tắc.', 'TF','T','F'],
            ['Bạn thẳng thắn khi góp ý.', 'TF','T','F'],
            ['Bạn đặt hiệu quả lên hàng đầu.', 'TF','T','F'],
            ['Bạn quyết định dựa trên dữ kiện.', 'TF','T','F'],
            ['Bạn ít để cảm xúc chi phối.', 'TF','T','F'],
            ['Bạn thích đánh giá khách quan.', 'TF','T','F'],
            ['Bạn ưu tiên lý luận hơn tình cảm.', 'TF','T','F'],

            // ===== JP (12 câu) =====
            ['Bạn thích lên kế hoạch trước khi làm.', 'JP','J','P'],
            ['Bạn hoàn thành bài tập sớm.', 'JP','J','P'],
            ['Bạn thấy khó chịu khi kế hoạch bị thay đổi.', 'JP','J','P'],
            ['Bạn thích lịch trình rõ ràng.', 'JP','J','P'],
            ['Bạn làm việc theo deadline nghiêm túc.', 'JP','J','P'],
            ['Bạn thích môi trường có tổ chức.', 'JP','J','P'],
            ['Bạn sắp xếp thời gian hợp lý.', 'JP','J','P'],
            ['Bạn ưu tiên sự ổn định.', 'JP','J','P'],
            ['Bạn không thích trì hoãn.', 'JP','J','P'],
            ['Bạn lập danh sách công việc cần làm.', 'JP','J','P'],
            ['Bạn thích hoàn thành từng bước rõ ràng.', 'JP','J','P'],
            ['Bạn cảm thấy thoải mái khi mọi thứ theo kế hoạch.', 'JP','J','P'],
        ];

        $order = 1;

        foreach ($questions as $q) {
            MbtiQuestion::create([
                'content' => $q[0],
                'axis' => $q[1],
                'dir_a' => $q[2],
                'dir_b' => $q[3],
                'label_a' => 'Đúng với tôi',
                'label_b' => 'Không đúng với tôi',
                'order' => $order++
            ]);
        }
    }
}