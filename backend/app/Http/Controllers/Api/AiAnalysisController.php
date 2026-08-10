<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class AiAnalysisController extends Controller
{
    public function topAbilities(Request $request)
    {
        $data = $request->validate([
            'mbti_type' => ['nullable', 'string'],
            'mbti_title' => ['nullable', 'string'],
            'interest_group_scores' => ['nullable', 'array'],
            'interest_top_groups' => ['nullable', 'array'],
            'ability_scores' => ['nullable', 'array'],
            'combined_chart_data' => ['nullable', 'array'],
        ]);

        $apiKey = config('services.gemini.api_key');
        $model = config('services.gemini.model', 'gemini-2.5-flash');

        if (!$apiKey) {
            return response()->json([
                'message' => 'Gemini API key chưa được cấu hình.',
                'top_abilities' => [],
            ], 500);
        }

        $prompt = "
Bạn là chuyên gia hướng nghiệp cho học sinh, sinh viên Việt Nam.

Dựa trên dữ liệu MBTI, sở thích, năng lực và biểu đồ tổng hợp bên dưới, hãy chọn ra đúng 3 năng lực nổi trội nhất.

Yêu cầu:
- Trả về JSON thuần, không markdown, không giải thích thêm.
- title là tên năng lực ngắn gọn bằng tiếng Việt.
- percent là số từ 0 đến 100.
- description viết tự nhiên, cá nhân hóa theo dữ liệu, 1-2 câu ngắn.
- Không dùng emoji.

Định dạng bắt buộc:
{
  \"top_abilities\": [
    {
      \"title\": \"\",
      \"percent\": 0,
      \"description\": \"\"
    }
  ]
}

Dữ liệu:
" . json_encode($data, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);

        try {
            $response = Http::timeout(30)
                ->withHeaders([
                    'x-goog-api-key' => $apiKey,
                    'Content-Type' => 'application/json',
                ])
                ->post("https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent", [
                    'contents' => [
                        [
                            'parts' => [
                                ['text' => $prompt],
                            ],
                        ],
                    ],
                    'generationConfig' => [
                        'responseMimeType' => 'application/json',
                    ],
                ]);

            if (!$response->successful()) {
                Log::error('Gemini top abilities failed', [
                    'status' => $response->status(),
                    'body' => $response->body(),
                ]);

                return response()->json([
                    'message' => 'Gemini AI chưa thể tạo top năng lực.',
                    'top_abilities' => [],
                ], 500);
            }

            $text = trim((string) $response->json('candidates.0.content.parts.0.text'));
            $decoded = json_decode($text, true);

            if (!is_array($decoded)) {
                return response()->json([
                    'message' => 'Gemini trả dữ liệu không hợp lệ.',
                    'top_abilities' => [],
                    'raw' => $text,
                ], 500);
            }

            return response()->json([
                'top_abilities' => array_slice($decoded['top_abilities'] ?? [], 0, 3),
            ]);
        } catch (\Throwable $e) {
            Log::error('Gemini top abilities exception', [
                'message' => $e->getMessage(),
            ]);

            return response()->json([
                'message' => 'Lỗi khi gọi Gemini AI.',
                'top_abilities' => [],
            ], 500);
        }
    }
}