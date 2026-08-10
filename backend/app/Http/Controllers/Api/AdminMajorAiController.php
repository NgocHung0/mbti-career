<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;

class AdminMajorAiController extends Controller
{
    public function suggest(Request $request)
    {
        $data = $request->validate([
            'name' => ['nullable', 'string', 'max:255'],
            'code' => ['nullable', 'string', 'max:100'],
            'description' => ['nullable', 'string'],
            'career_prospects' => ['nullable', 'string'],
            'skills' => ['nullable', 'string'],
        ]);

        $hasContent = collect([
            $data['name'] ?? '',
            $data['description'] ?? '',
            $data['career_prospects'] ?? '',
            $data['skills'] ?? '',
        ])->filter(fn ($v) => trim((string) $v) !== '')->isNotEmpty();

        if (! $hasContent) {
            return response()->json([
                'message' => 'Cần ít nhất tên ngành hoặc mô tả để AI phân tích.',
            ], 422);
        }

        try {
            if (config('services.openai.api_key')) {
                return response()->json($this->suggestWithOpenAi($data));
            }

            return response()->json($this->suggestWithFallback($data));
        } catch (\Throwable $e) {
            report($e);

            return response()->json($this->suggestWithFallback($data));
        }
    }

    protected function suggestWithOpenAi(array $data): array
    {
        $inputText = $this->buildPromptInput($data);

        $schema = [
            'name' => 'major_mbti_vector',
            'schema' => [
                'type' => 'object',
                'additionalProperties' => false,
                'properties' => [
                    'vector_e' => [
                        'type' => 'integer',
                        'minimum' => 0,
                        'maximum' => 100,
                    ],
                    'vector_s' => [
                        'type' => 'integer',
                        'minimum' => 0,
                        'maximum' => 100,
                    ],
                    'vector_t' => [
                        'type' => 'integer',
                        'minimum' => 0,
                        'maximum' => 100,
                    ],
                    'vector_j' => [
                        'type' => 'integer',
                        'minimum' => 0,
                        'maximum' => 100,
                    ],
                    'summary' => [
                        'type' => 'string',
                    ],
                    'top_schools' => [
                        'type' => 'array',
                        'items' => [
                            'type' => 'string',
                        ],
                        'minItems' => 3,
                        'maxItems' => 8,
                    ],
                    'explanation' => [
                        'type' => 'object',
                        'additionalProperties' => false,
                        'properties' => [
                            'E' => ['type' => 'string'],
                            'S' => ['type' => 'string'],
                            'T' => ['type' => 'string'],
                            'J' => ['type' => 'string'],
                        ],
                        'required' => ['E', 'S', 'T', 'J'],
                    ],
                ],
                'required' => [
                    'vector_e',
                    'vector_s',
                    'vector_t',
                    'vector_j',
                    'summary',
                    'top_schools',
                    'explanation',
                ],
            ],
            'strict' => true,
        ];

        $response = Http::timeout(60)
            ->withToken(config('services.openai.api_key'))
            ->post('https://api.openai.com/v1/chat/completions', [
                'model' => config('services.openai.model', 'gpt-4.1-mini'),
                'temperature' => 0.3,
                'response_format' => [
                    'type' => 'json_schema',
                    'json_schema' => $schema,
                ],
                'messages' => [
                    [
                        'role' => 'system',
                        'content' => implode("\n", [
                            'Bạn là chuyên gia phân tích ngành nghề, MBTI và định hướng học tập.',
                            'Hãy suy ra vector MBTI và gợi ý trường đại học phù hợp cho một ngành học/nghề nghiệp.',
                            'Quy ước:',
                            '- vector_e: mức thiên về E, I = 100 - E',
                            '- vector_s: mức thiên về S, N = 100 - S',
                            '- vector_t: mức thiên về T, F = 100 - T',
                            '- vector_j: mức thiên về J, P = 100 - J',
                            'top_schools là danh sách 3-8 trường đại học phù hợp tại Việt Nam.',
                            'Ưu tiên trường phổ biến, dễ nhận biết, liên quan đúng ngành.',
                            'Không bịa quá xa thực tế.',
                            'Chỉ trả dữ liệu đúng JSON schema đã yêu cầu.',
                        ]),
                    ],
                    [
                        'role' => 'user',
                        'content' => $inputText,
                    ],
                ],
            ]);

        if (! $response->successful()) {
            throw new \RuntimeException('OpenAI request failed: ' . $response->body());
        }

        $jsonText = data_get($response->json(), 'choices.0.message.content');

        if (! is_string($jsonText) || trim($jsonText) === '') {
            throw new \RuntimeException('OpenAI trả về content rỗng.');
        }

        $parsed = json_decode($jsonText, true);

        if (! is_array($parsed)) {
            throw new \RuntimeException('Không parse được JSON từ OpenAI.');
        }

        return [
            'vector_e' => $this->clamp($parsed['vector_e'] ?? 50),
            'vector_s' => $this->clamp($parsed['vector_s'] ?? 50),
            'vector_t' => $this->clamp($parsed['vector_t'] ?? 50),
            'vector_j' => $this->clamp($parsed['vector_j'] ?? 50),
            'summary' => trim((string) ($parsed['summary'] ?? 'AI đã phân tích vector cho ngành này.')),
            'top_schools' => collect($parsed['top_schools'] ?? [])
                ->map(fn ($item) => trim((string) $item))
                ->filter()
                ->unique()
                ->values()
                ->take(8)
                ->all(),
            'explanation' => [
                'E' => trim((string) data_get($parsed, 'explanation.E', '')),
                'S' => trim((string) data_get($parsed, 'explanation.S', '')),
                'T' => trim((string) data_get($parsed, 'explanation.T', '')),
                'J' => trim((string) data_get($parsed, 'explanation.J', '')),
            ],
            'source' => 'openai',
        ];
    }

    protected function suggestWithFallback(array $data): array
    {
        $text = Str::lower(implode(' ', [
            $data['name'] ?? '',
            $data['description'] ?? '',
            $data['career_prospects'] ?? '',
            $data['skills'] ?? '',
        ]));

        $e = 50;
        $s = 50;
        $t = 50;
        $j = 50;

        $this->applyKeywordRules($text, $e, [
            'giao tiếp' => 12,
            'thuyết trình' => 10,
            'đàm phán' => 10,
            'làm việc nhóm' => 10,
            'khách hàng' => 8,
            'sự kiện' => 10,
            'bán hàng' => 10,
            'truyền thông' => 10,
            'quan hệ' => 8,
        ]);

        $this->applyKeywordRules($text, $e, [
            'nghiên cứu độc lập' => -12,
            'làm việc độc lập' => -10,
            'tập trung cá nhân' => -8,
            'phân tích chuyên sâu' => -6,
        ]);

        $this->applyKeywordRules($text, $s, [
            'thực hành' => 12,
            'quy trình' => 10,
            'chi tiết' => 10,
            'vận hành' => 8,
            'kỹ thuật' => 8,
            'thực tế' => 8,
            'kiểm tra' => 8,
            'triển khai' => 8,
        ]);

        $this->applyKeywordRules($text, $s, [
            'ý tưởng' => -12,
            'sáng tạo' => -10,
            'chiến lược' => -8,
            'tầm nhìn' => -8,
            'khái niệm' => -8,
            'đổi mới' => -8,
            'thiết kế' => -6,
            'nghệ thuật' => -8,
        ]);

        $this->applyKeywordRules($text, $t, [
            'phân tích' => 12,
            'logic' => 12,
            'dữ liệu' => 12,
            'đánh giá' => 8,
            'ra quyết định' => 8,
            'hệ thống' => 8,
            'lập trình' => 10,
            'tài chính' => 8,
            'kỹ thuật phần mềm' => 10,
        ]);

        $this->applyKeywordRules($text, $t, [
            'đồng cảm' => -12,
            'hỗ trợ' => -10,
            'chăm sóc' => -10,
            'con người' => -8,
            'tư vấn tâm lý' => -12,
            'cộng đồng' => -8,
            'nhân sự' => -6,
        ]);

        $this->applyKeywordRules($text, $j, [
            'kế hoạch' => 12,
            'kỷ luật' => 10,
            'quản lý' => 10,
            'tiến độ' => 8,
            'ổn định' => 8,
            'kiểm soát' => 8,
            'quy chuẩn' => 8,
            'tuân thủ' => 8,
            'quy trình' => 8,
        ]);

        $this->applyKeywordRules($text, $j, [
            'linh hoạt' => -12,
            'thử nghiệm' => -8,
            'ngẫu hứng' => -10,
            'khám phá' => -8,
            'biến động' => -6,
        ]);

        $e = $this->clamp($e);
        $s = $this->clamp($s);
        $t = $this->clamp($t);
        $j = $this->clamp($j);

        $schools = $this->suggestSchoolsFallback($text, $data);

        return [
            'vector_e' => $e,
            'vector_s' => $s,
            'vector_t' => $t,
            'vector_j' => $j,
            'top_schools' => $schools,
            'explanation' => [
                'E' => $this->explainAxis('E', $e),
                'S' => $this->explainAxis('S', $s),
                'T' => $this->explainAxis('T', $t),
                'J' => $this->explainAxis('J', $j),
            ],
            'source' => 'fallback_rule',
        ];
    }

    protected function suggestSchoolsFallback(string $text, array $data): array
    {
        $name = Str::lower((string) ($data['name'] ?? ''));

        if (
            Str::contains($text, ['công nghệ thông tin', 'lập trình', 'phần mềm', 'dữ liệu', 'máy tính', 'khoa học máy tính']) ||
            Str::contains($name, ['công nghệ thông tin', 'kỹ thuật phần mềm', 'khoa học máy tính'])
        ) {
            return [
                'Đại học Bách khoa TP.HCM',
                'Đại học Công nghệ Thông tin - ĐHQG TP.HCM',
                'Đại học Khoa học Tự nhiên - ĐHQG TP.HCM',
                'Đại học FPT',
                'RMIT Việt Nam',
            ];
        }

        if (
            Str::contains($text, ['thiết kế', 'đồ họa', 'mỹ thuật', 'sáng tạo', 'truyền thông', 'typography', 'ui', 'ux']) ||
            Str::contains($name, ['thiết kế đồ họa', 'truyền thông đa phương tiện', 'mỹ thuật'])
        ) {
            return [
                'Đại học Kiến trúc TP.HCM',
                'Đại học Văn Lang',
                'Đại học FPT',
                'RMIT Việt Nam',
                'Đại học Tôn Đức Thắng',
            ];
        }

        if (
            Str::contains($text, ['kinh doanh', 'marketing', 'quản trị', 'thương mại', 'bán hàng']) ||
            Str::contains($name, ['marketing', 'quản trị kinh doanh', 'thương mại'])
        ) {
            return [
                'Đại học Kinh tế TP.HCM',
                'Đại học Ngoại thương',
                'Đại học Kinh tế - Luật ĐHQG TP.HCM',
                'Đại học Tôn Đức Thắng',
                'RMIT Việt Nam',
            ];
        }

        if (
            Str::contains($text, ['luật', 'pháp lý']) ||
            Str::contains($name, ['luật'])
        ) {
            return [
                'Đại học Luật TP.HCM',
                'Đại học Kinh tế - Luật ĐHQG TP.HCM',
                'Đại học Luật Hà Nội',
                'Đại học Mở TP.HCM',
                'Đại học Cần Thơ',
            ];
        }

        if (
            Str::contains($text, ['kiến trúc', 'xây dựng', 'nội thất']) ||
            Str::contains($name, ['kiến trúc', 'xây dựng', 'thiết kế nội thất'])
        ) {
            return [
                'Đại học Kiến trúc TP.HCM',
                'Đại học Bách khoa TP.HCM',
                'Đại học Tôn Đức Thắng',
                'Đại học Xây dựng Hà Nội',
                'Đại học Văn Lang',
            ];
        }

        return [
            'Đại học Quốc gia TP.HCM',
            'Đại học Bách khoa TP.HCM',
            'Đại học Kinh tế TP.HCM',
            'Đại học FPT',
            'RMIT Việt Nam',
        ];
    }

    protected function buildPromptInput(array $data): string
    {
        return implode("\n", [
            'Phân tích ngành sau và suy ra vector MBTI cùng danh sách trường đại học gợi ý:',
            'Tên ngành: ' . ($data['name'] ?? ''),
            'Mã ngành: ' . ($data['code'] ?? ''),
            'Mô tả: ' . ($data['description'] ?? ''),
            'Triển vọng nghề nghiệp: ' . ($data['career_prospects'] ?? ''),
            'Kỹ năng: ' . ($data['skills'] ?? ''),
            '',
            'Yêu cầu:',
            '- Chấm 4 trục E, S, T, J từ 0-100',
            '- Gợi ý 3 đến 8 trường đại học phù hợp tại Việt Nam',
            '- Ưu tiên trường phổ biến, dễ nhận biết, liên quan đúng ngành',
            '- Không bịa thông tin quá xa thực tế',
            '- Viết summary ngắn gọn bằng tiếng Việt',
            '- explanation.E/S/T/J mỗi mục 1 câu ngắn gọn',
        ]);
    }

    protected function applyKeywordRules(string $text, int &$score, array $rules): void
    {
        foreach ($rules as $keyword => $delta) {
            if (Str::contains($text, $keyword)) {
                $score += $delta;
            }
        }
    }

    protected function clamp($value): int
    {
        $num = (int) round((float) $value);
        return max(0, min(100, $num));
    }

    protected function explainAxis(string $axis, int $value): string
    {
        $other = 100 - $value;

        return match ($axis) {
            'E' => $value >= 50
                ? "Ngành này thiên hướng ngoại hơn, mức E khoảng {$value} và I khoảng {$other}."
                : "Ngành này thiên hướng nội hơn, mức I khoảng {$other} và E khoảng {$value}.",
            'S' => $value >= 50
                ? "Ngành này thiên về thực tế, chi tiết và áp dụng, mức S khoảng {$value}."
                : "Ngành này thiên về trực giác, ý tưởng và định hướng tương lai, mức N khoảng {$other}.",
            'T' => $value >= 50
                ? "Ngành này thiên về logic, phân tích và quyết định lý trí, mức T khoảng {$value}."
                : "Ngành này thiên về con người, cảm nhận và sự hài hòa, mức F khoảng {$other}.",
            'J' => $value >= 50
                ? "Ngành này thiên về kế hoạch, cấu trúc và sự rõ ràng, mức J khoảng {$value}."
                : "Ngành này thiên về linh hoạt, khám phá và thích ứng, mức P khoảng {$other}.",
            default => '',
        };
    }
}