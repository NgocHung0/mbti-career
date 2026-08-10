<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\RecommendationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class RecommendationController extends Controller
{
    public function majors(
        Request $request,
        RecommendationService $service
    ) {
        $data = $request->validate([
            'level' => [
                'nullable',
                'string',
                'in:plus,premium',
            ],

            'mbti_type' => [
                'nullable',
                'string',
                'size:4',
            ],

            'mbti_scores' => [
                'nullable',
                'array',
            ],

            'interest_group_scores' => [
                'nullable',
                'array',
            ],

            'top_interest_groups' => [
                'nullable',
                'array',
            ],

            'ability_scores' => [
                'nullable',
                'array',
            ],

            'limit' => [
                'nullable',
                'integer',
                'min:1',
                'max:20',
            ],
        ]);

        $level = strtolower(
            (string) (
                $data['level']
                ?? $request->query('level', 'plus')
            )
        );

        $level = $level === 'premium'
            ? 'premium'
            : 'plus';

        $limit = max(
            1,
            min(
                20,
                (int) (
                    $data['limit']
                    ?? $request->query('limit', 5)
                )
            )
        );
        
        if ($request->isMethod('get')) {
            $user = $request->user();

            if (!$user) {
                return response()->json([
                    'message' => 'Unauthorized',
                ], 401);
            }

            $result = $service->recommendForUser(
                (int) $user->id,
                $level,
                $limit
            );

            $result['ai_analysis'] =
                $level === 'premium'
                    ? $this->generateGeminiMajorAnalysis(
                        $this->buildAiPayload($result)
                    )
                    : null;

            return response()->json($result);
        }
        $result = $service->recommend([
            'level' => $level,
            'limit' => $limit,

            'mbti_type' =>
                $data['mbti_type'] ?? null,

            'mbti_scores' =>
                $data['mbti_scores'] ?? [],

            'interest_group_scores' =>
                $data['interest_group_scores'] ?? [],

            'top_interest_groups' =>
                $data['top_interest_groups'] ?? [],

            'ability_scores' =>
                $data['ability_scores'] ?? [],
        ]);

        $result['ai_analysis'] =
            $level === 'premium'
                ? $this->generateGeminiMajorAnalysis(
                    $this->buildAiPayload($result)
                )
                : null;

        return response()->json($result);
    }

    private function buildAiPayload(array $result): array
    {
        $interestLabels = [
            'creative' => 'Sáng tạo',
            'analytic' => 'Phân tích - Công nghệ',
            'social' => 'Con người - Giao tiếp',
            'business' => 'Kinh doanh - Tổ chức',
        ];

        $abilityLabels = [
            'LANGUAGE' => 'Ngôn ngữ',
            'LOGIC' => 'Tư duy logic',
            'CREATIVE' => 'Sáng tạo',
            'TECH' => 'Công nghệ',
            'LEADERSHIP' => 'Lãnh đạo',
            'TEAMWORK' => 'Làm việc nhóm',
            'DETAIL' => 'Chi tiết - Cẩn thận',
            'ADAPT' => 'Thích nghi',
            'PRACTICAL' => 'Thực hành',
            'STRATEGIC' => 'Chiến lược',
        ];

        $interestScores =
            $this->normalizeNumericArray(
                $result['interest_group_scores'] ?? []
            );

        $abilityScores =
            $this->normalizeNumericArray(
                $result['ability_scores'] ?? []
            );

        /*
        * Sắp xếp sở thích từ cao xuống thấp để Gemini
        * nhìn thấy rõ điểm mạnh và mức chênh lệch.
        */
        $interestProfile = collect($interestScores)
            ->map(function ($score, $key) use (
                $interestLabels
            ) {
                return [
                    'key' => (string) $key,

                    'label' =>
                        $interestLabels[(string) $key]
                        ?? (string) $key,

                    'percent' => round(
                        (float) $score,
                        1
                    ),
                ];
            })
            ->sortByDesc('percent')
            ->values()
            ->all();

        /*
        * Gửi đủ 10 năng lực nhưng đã sắp xếp.
        * Gemini có thể thấy cả điểm mạnh và điểm cần cải thiện.
        */
        $abilityProfile = collect($abilityScores)
            ->map(function ($score, $key) use (
                $abilityLabels
            ) {
                $normalizedKey = strtoupper(
                    (string) $key
                );

                return [
                    'key' => $normalizedKey,

                    'label' =>
                        $abilityLabels[$normalizedKey]
                        ?? $normalizedKey,

                    'percent' => round(
                        (float) $score,
                        1
                    ),
                ];
            })
            ->sortByDesc('percent')
            ->values()
            ->all();

        $topMajors = collect(
            $result['top_majors'] ?? []
        )
            ->take(5)
            ->map(function ($major) {
                if (!is_array($major)) {
                    return null;
                }

                $schools = collect(
                    $major['schools']
                    ?? $major['universities']
                    ?? []
                )
                    ->take(3)
                    ->map(function ($school) {
                        if (is_string($school)) {
                            $name = trim($school);

                            return $name !== ''
                                ? [
                                    'name' => $name,
                                    'city' => '',
                                    'major_name' => '',
                                    'description' => '',
                                ]
                                : null;
                        }

                        if (!is_array($school)) {
                            return null;
                        }

                        $name = trim(
                            (string) (
                                $school['name']
                                ?? $school['school_name']
                                ?? ''
                            )
                        );

                        if ($name === '') {
                            return null;
                        }

                        return [
                            'name' => $name,

                            'city' => trim(
                                (string) (
                                    $school['city'] ?? ''
                                )
                            ),

                            'major_name' => trim(
                                (string) (
                                    $school['major_name'] ?? ''
                                )
                            ),

                            'description' => mb_substr(
                                trim(
                                    (string) (
                                        $school[
                                            'short_description'
                                        ]
                                        ?? $school[
                                            'description'
                                        ]
                                        ?? ''
                                    )
                                ),
                                0,
                                160
                            ),
                        ];
                    })
                    ->filter()
                    ->values()
                    ->all();

                return [
                    'name' => trim(
                        (string) (
                            $major['name'] ?? ''
                        )
                    ),

                    'score' => round(
                        (float) (
                            $major['score'] ?? 0
                        ),
                        1
                    ),

                    'fit_interest' => round(
                        (float) (
                            $major['fit_interest'] ?? 0
                        ),
                        1
                    ),

                    'fit_ability' => round(
                        (float) (
                            $major['fit_ability'] ?? 0
                        ),
                        1
                    ),

                    /*
                    * Trước đây phần này không được gửi
                    * nên Gemini chỉ nhìn thấy tên ngành.
                    */
                    'description' => mb_substr(
                        trim(
                            (string) (
                                $major['description'] ?? ''
                            )
                        ),
                        0,
                        240
                    ),

                    'reasons' => collect(
                        $major['reasons'] ?? []
                    )
                        ->take(3)
                        ->map(
                            fn ($reason) =>
                                trim((string) $reason)
                        )
                        ->filter()
                        ->values()
                        ->all(),

                    'schools' => $schools,
                ];
            })
            ->filter(function ($major) {
                return is_array($major)
                    && !empty($major['name']);
            })
            ->values()
            ->all();

        return [
            'mbti_type' => strtoupper(
                trim(
                    (string) (
                        $result['mbti_type'] ?? ''
                    )
                )
            ),

            /*
            * Giữ dữ liệu gốc để fallback sử dụng.
            */
            'interest_group_scores' =>
                $interestScores,

            'ability_scores' =>
                $abilityScores,

            /*
            * Dữ liệu đã sắp xếp giúp Gemini
            * phân tích dễ và cụ thể hơn.
            */
            'interest_profile' =>
                $interestProfile,

            'ability_profile' =>
                $abilityProfile,

            'top_majors' => $topMajors,
        ];
    }

    private function normalizeNumericArray(
        mixed $values
    ): array {
        if (is_string($values)) {
            $decoded = json_decode(
                $values,
                true
            );

            $values = is_array($decoded)
                ? $decoded
                : [];
        }

        if (!is_array($values)) {
            return [];
        }

        $normalized = [];

        foreach ($values as $key => $value) {
            if (!is_numeric($value)) {
                continue;
            }

            $normalized[(string) $key] =
                round((float) $value, 2);
        }

        return $normalized;
    }

    private function generateGeminiMajorAnalysis(
        array $data
    ): string {
        $apiKey = trim(
            (string) config(
                'services.gemini.api_key'
            )
        );

        $model = trim(
            (string) config(
                'services.gemini.model',
                'gemini-2.5-flash'
            )
        );

        $fallback =
            $this->buildFallbackAnalysis($data);

        if ($apiKey === '') {
            return $fallback;
        }

        $cacheSource = json_encode(
            [
                'version' => 6,
                'model' => $model,
                'data' => $data,
            ],
            JSON_UNESCAPED_UNICODE
            | JSON_UNESCAPED_SLASHES
        );

        $cacheKey =
            'gemini:major-analysis:' .
            hash(
                'sha256',
                (string) $cacheSource
            );

        $cached = Cache::get($cacheKey);

        if (
            is_string($cached)
            && trim($cached) !== ''
        ) {
            return $cached;
        }

        $dataJson = json_encode(
            $data,
            JSON_UNESCAPED_UNICODE
            | JSON_UNESCAPED_SLASHES
        );

        $prompt = <<<PROMPT
        Hãy phân tích hồ sơ hướng nghiệp trong dữ liệu JSON bên dưới theo hướng cá nhân hóa và có dẫn chứng.

        Chỉ trả về HTML thuần với đúng ba phần:

        <h4>1. Điểm nổi bật của bạn</h4>
        <p>...</p>

        <h4>2. Vì sao ngành và trường này phù hợp?</h4>
        <p>...</p>

        <h4>3. Gợi ý tiếp theo</h4>
        <p>...</p>

        Yêu cầu phân tích:

        - Không chỉ liệt kê MBTI, sở thích và năng lực.
        - Phải giải thích sự kết hợp giữa MBTI với ít nhất 2 sở thích và 3 năng lực nổi bật.
        - Phải nhắc ít nhất 2 tỷ lệ phần trăm cụ thể từ dữ liệu.
        - Nêu một điểm mạnh rõ nhất và một khía cạnh còn thấp hơn để người dùng hiểu hồ sơ cân bằng hơn.
        - Với ngành đứng đầu, giải thích bằng điểm tổng, điểm sở thích và điểm năng lực.
        - So sánh ngắn ngành đứng đầu với ít nhất một ngành khác trong Top 5.
        - Chỉ nhắc trường có trong dữ liệu JSON và giải thích trường đó đang có dữ liệu tuyển sinh cho ngành nào.
        - Gợi ý tiếp theo phải cụ thể, chẳng hạn kỹ năng cần rèn luyện, trải nghiệm nên thử hoặc thông tin tuyển sinh nên kiểm tra.
        - Không viết những câu chung chung như “bạn có một số đặc điểm phù hợp” nếu không có số liệu đi kèm.
        - Không khẳng định kết quả là tuyệt đối.
        - Không tự tạo ngành hoặc trường ngoài dữ liệu.
        - Không markdown, không dấu ```, không danh sách, không icon.
        - Chỉ dùng các thẻ <h4>, <p> và <strong>.
        - Tổng độ dài khoảng 180 đến 230 từ.
        - Mỗi mục có một đoạn văn đầy đủ, tự nhiên và liên kết với nhau.

        Dữ liệu JSON:
        {$dataJson}
        PROMPT;
        $generationConfig = [
            'maxOutputTokens' => 1000,
            'temperature' => 0.65,
            'topP' => 0.9,
            'candidateCount' => 1,
        ];

        if (
            str_starts_with(
                $model,
                'gemini-2.5-flash'
            )
        ) {
            $generationConfig[
                'thinkingConfig'
            ] = [
                'thinkingBudget' => 0,
            ];
        }

       $requestBody = [
            'systemInstruction' => [
                'parts' => [
                    [
                        'text' =>
                            'Bạn là cố vấn hướng nghiệp của hệ thống NAVI. '
                            . 'Bạn phân tích hồ sơ học sinh Việt Nam dựa trên bằng chứng định lượng. '
                            . 'Mọi nhận xét phải liên hệ trực tiếp với tỷ lệ sở thích, năng lực, '
                            . 'điểm phù hợp ngành và dữ liệu trường trong JSON. '
                            . 'Văn phong gần gũi, có chiều sâu, không máy móc và không phán xét.',
                    ],
                ],
            ],

            'contents' => [
                [
                    'role' => 'user',

                    'parts' => [
                        [
                            'text' => $prompt,
                        ],
                    ],
                ],
            ],

            'generationConfig' =>
                $generationConfig,
        ];

        $retryableStatuses = [
            408,
            429,
            500,
            502,
            503,
            504,
        ];

        $maximumAttempts = 3;
        $lastStatus = null;
        $lastBody = null;

        try {
            for (
                $attempt = 1;
                $attempt <= $maximumAttempts;
                $attempt++
            ) {
                $response = Http::connectTimeout(10)
                    ->timeout(45)
                    ->acceptJson()
                    ->withHeaders([
                        'x-goog-api-key' =>
                            $apiKey,

                        'Content-Type' =>
                            'application/json',
                    ])
                    ->post(
                        "https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent",
                        $requestBody
                    );

                $lastStatus = $response->status();
                $lastBody = $response->body();

                if ($response->successful()) {
                    $analysis =
                        $this->extractGeminiText(
                            $response->json()
                        );

                    $finishReason = strtoupper(
                        (string) (
                            $response->json(
                                'candidates.0.finishReason'
                            )
                            ?? ''
                        )
                    );

                    Log::info(
                        'Gemini analysis usage',
                        [
                            'model' => $model,

                            'finish_reason' =>
                                $finishReason,

                            'prompt_tokens' =>
                                $response->json(
                                    'usageMetadata.promptTokenCount'
                                ),

                            'output_tokens' =>
                                $response->json(
                                    'usageMetadata.candidatesTokenCount'
                                ),

                            'thinking_tokens' =>
                                $response->json(
                                    'usageMetadata.thoughtsTokenCount'
                                ),

                            'total_tokens' =>
                                $response->json(
                                    'usageMetadata.totalTokenCount'
                                ),
                        ]
                    );

                    $analysis =
                        $this->sanitizeGeminiHtml(
                            $analysis
                        );

                    if (
                        $finishReason !== 'MAX_TOKENS'
                        && $this->isCompleteAnalysis(
                            $analysis
                        )
                    ) {
                        Cache::put(
                            $cacheKey,
                            $analysis,
                            now()->addHours(12)
                        );

                        return $analysis;
                    }

                    Log::warning(
                        'Gemini returned incomplete analysis',
                        [
                            'finish_reason' =>
                                $finishReason,

                            'analysis' =>
                                $analysis,
                        ]
                    );

                    break;
                }

                Log::warning(
                    'Gemini request attempt failed',
                    [
                        'attempt' => $attempt,
                        'status' =>
                            $response->status(),

                        'body' =>
                            $response->body(),
                    ]
                );

                if (
                    !in_array(
                        $response->status(),
                        $retryableStatuses,
                        true
                    )
                ) {
                    break;
                }

                if (
                    $attempt >=
                    $maximumAttempts
                ) {
                    break;
                }

                $retryAfter = (int) (
                    $response->header(
                        'Retry-After'
                    ) ?? 0
                );

                $delaySeconds =
                    $retryAfter > 0
                        ? min(
                            $retryAfter,
                            8
                        )
                        : 2 ** ($attempt - 1);

                $jitterMicroseconds =
                    random_int(
                        100000,
                        400000
                    );

                usleep(
                    (
                        $delaySeconds *
                        1000000
                    )
                    +
                    $jitterMicroseconds
                );
            }
        } catch (\Throwable $exception) {
            Log::error(
                'Gemini analysis exception',
                [
                    'message' =>
                        $exception->getMessage(),

                    'file' =>
                        $exception->getFile(),

                    'line' =>
                        $exception->getLine(),
                ]
            );
        }

        Log::error(
            'Gemini analysis unavailable',
            [
                'status' => $lastStatus,
                'body' => $lastBody,
            ]
        );

        Cache::put(
            $cacheKey,
            $fallback,
            now()->addMinutes(2)
        );

        return $fallback;
    }

    private function extractGeminiText(
        mixed $responseData
    ): string {
        if (!is_array($responseData)) {
            return '';
        }

        $parts =
            $responseData['candidates'][0]
                ['content']['parts']
            ?? [];

        if (!is_array($parts)) {
            return '';
        }

        return collect($parts)
            ->map(function ($part) {
                return is_array($part)
                    ? (
                        $part['text']
                        ?? ''
                    )
                    : '';
            })
            ->filter()
            ->implode('');
    }

    private function sanitizeGeminiHtml(
        string $html
    ): string {
        $html = trim($html);

        $html = preg_replace(
            '/```(?:html)?/i',
            '',
            $html
        ) ?? $html;

        $html = str_replace(
            '```',
            '',
            $html
        );

        $html = strip_tags(
            $html,
            '<h4><p><strong>'
        );

        return trim($html);
    }

    private function isCompleteAnalysis(
        string $html
    ): bool {
        if ($html === '') {
            return false;
        }

        return
            substr_count($html, '<h4>') >= 3
            && substr_count($html, '</h4>') >= 3
            && substr_count($html, '<p>') >= 3
            && substr_count($html, '</p>') >= 3;
    }

    private function buildFallbackAnalysis(
        array $data
    ): string {
        $mbtiType = strtoupper(
            trim(
                (string) (
                    $data['mbti_type'] ?? ''
                )
            )
        );

        if ($mbtiType === '') {
            $mbtiType = 'chưa xác định';
        }

        $interestLabels = [
            'creative' => 'Sáng tạo',

            'analytic' =>
                'Phân tích - Công nghệ',

            'social' =>
                'Con người - Giao tiếp',

            'business' =>
                'Kinh doanh - Tổ chức',
        ];

        $abilityLabels = [
            'LANGUAGE' => 'Ngôn ngữ',
            'LOGIC' => 'Tư duy logic',
            'CREATIVE' => 'Sáng tạo',
            'TECH' => 'Công nghệ',
            'LEADERSHIP' => 'Lãnh đạo',
            'TEAMWORK' => 'Làm việc nhóm',

            'DETAIL' =>
                'Chi tiết - Cẩn thận',

            'ADAPT' => 'Thích nghi',
            'PRACTICAL' => 'Thực hành',
            'STRATEGIC' => 'Chiến lược',
        ];

        $interestScores =
            $data[
                'interest_group_scores'
            ] ?? [];

        $abilityScores =
            $data['ability_scores'] ?? [];

        $topInterestKey = collect(
            is_array($interestScores)
                ? $interestScores
                : []
        )
            ->sortDesc()
            ->keys()
            ->first();

        $topAbilityKey = collect(
            is_array($abilityScores)
                ? $abilityScores
                : []
        )
            ->sortDesc()
            ->keys()
            ->first();

        $topInterest =
            $interestLabels[
                (string) $topInterestKey
            ]
            ?? 'sở thích nổi bật';

        $topAbility =
            $abilityLabels[
                strtoupper(
                    (string) $topAbilityKey
                )
            ]
            ?? 'năng lực nổi bật';

        $formatPercent = function ($value): string {
    $number = round(
        max(0, min(100, (float) $value)),
        1
    );

    return number_format(
        $number,
        $number == (int) $number ? 0 : 1,
        ',',
        '.'
    );
};

$topInterestPercent = is_array($interestScores)
    ? (float) (
        $interestScores[$topInterestKey] ?? 0
    )
    : 0;

$topAbilityPercent = is_array($abilityScores)
    ? (float) (
        $abilityScores[$topAbilityKey] ?? 0
    )
    : 0;

$lowestAbilityKey = collect(
    is_array($abilityScores)
        ? $abilityScores
        : []
)
    ->sort()
    ->keys()
    ->first();

$lowestAbility = $abilityLabels[
    strtoupper((string) $lowestAbilityKey)
] ?? 'một số kỹ năng bổ trợ';

$lowestAbilityPercent = is_array($abilityScores)
    ? (float) (
        $abilityScores[$lowestAbilityKey] ?? 0
    )
    : 0;

$majorItems = collect(
    $data['top_majors'] ?? []
)
    ->filter(function ($major) {
        return is_array($major);
    })
    ->values();

$majorNames = $majorItems
    ->map(function ($major) {
        return trim(
            (string) (
                $major['name'] ?? ''
            )
        );
    })
    ->filter()
    ->take(3)
    ->map(function ($name) {
        return '<strong>'
            . e($name)
            . '</strong>';
    })
    ->implode(', ');

if ($majorNames === '') {
    $majorNames =
        '<strong>các ngành được hệ thống đề xuất</strong>';
}

$topMajor = $majorItems->first();

$topMajorName = is_array($topMajor)
    ? trim(
        (string) (
            $topMajor['name'] ?? ''
        )
    )
    : '';

$topMajorScore = is_array($topMajor)
    ? (float) (
        $topMajor['score'] ?? 0
    )
    : 0;

$topMajorInterestFit = is_array($topMajor)
    ? (float) (
        $topMajor['fit_interest'] ?? 0
    )
    : 0;

$topMajorAbilityFit = is_array($topMajor)
    ? (float) (
        $topMajor['fit_ability'] ?? 0
    )
    : 0;

if ($topMajorName === '') {
    $topMajorName = 'ngành đứng đầu';
}

$schoolNames = $majorItems
    ->flatMap(function ($major) {
        $schools = $major['schools'] ?? [];

        if (is_string($schools)) {
            return [$schools];
        }

        return is_array($schools)
            ? $schools
            : [];
    })
    ->map(function ($school) {
        if (is_string($school)) {
            return trim($school);
        }

        if (is_array($school)) {
            return trim(
                (string) (
                    $school['name']
                    ?? $school['school_name']
                    ?? ''
                )
            );
        }

        if (is_object($school)) {
            return trim(
                (string) (
                    $school->name
                    ?? $school->school_name
                    ?? ''
                )
            );
        }

        return '';
    })
    ->filter()
    ->unique()
    ->take(3)
    ->map(function ($name) {
        return '<strong>'
            . e($name)
            . '</strong>';
    })
    ->implode(', ');

if ($schoolNames === '') {
    $schoolNames =
        '<strong>các trường có dữ liệu tuyển sinh phù hợp</strong>';
}

return
    '<h4>1. Điểm nổi bật của bạn</h4>'
    . '<p>Nhóm <strong>'
    . e($mbtiType)
    . '</strong> kết hợp với sở thích <strong>'
    . e($topInterest)
    . ' '
    . $formatPercent($topInterestPercent)
    . '%</strong> và năng lực <strong>'
    . e($topAbility)
    . ' '
    . $formatPercent($topAbilityPercent)
    . '%</strong>. Kết quả cho thấy bạn nổi bật hơn ở những môi trường cần sự chủ động, linh hoạt và khả năng phát huy thế mạnh cá nhân. Tuy nhiên, năng lực <strong>'
    . e($lowestAbility)
    . ' '
    . $formatPercent($lowestAbilityPercent)
    . '%</strong> là khía cạnh bạn có thể tiếp tục rèn luyện để hồ sơ trở nên cân bằng hơn.</p>'

    . '<h4>2. Vì sao ngành và trường này phù hợp?</h4>'
    . '<p>Các ngành '
    . $majorNames
    . ' được xếp hạng sau khi hệ thống lọc MBTI và so khớp sở thích, năng lực với trọng số của từng ngành. Trong đó, <strong>'
    . e($topMajorName)
    . '</strong> đạt mức phù hợp <strong>'
    . $formatPercent($topMajorScore)
    . '%</strong>, gồm điểm sở thích <strong>'
    . $formatPercent($topMajorInterestFit)
    . '%</strong> và điểm năng lực <strong>'
    . $formatPercent($topMajorAbilityFit)
    . '%</strong>. Các trường '
    . $schoolNames
    . ' được hiển thị vì đang có dữ liệu tuyển sinh tương ứng với những ngành được đề xuất.</p>'

    . '<h4>3. Gợi ý tiếp theo</h4>'
    . '<p>Bạn nên ưu tiên tìm hiểu sâu hơn về <strong>'
    . e($topMajorName)
    . '</strong>, đồng thời so sánh chương trình đào tạo, học phí, phương thức xét tuyển và cơ hội nghề nghiệp giữa các trường. Bên cạnh việc phát huy <strong>'
    . e($topAbility)
    . '</strong>, bạn có thể tham gia dự án, khóa học hoặc hoạt động thực tế nhằm cải thiện <strong>'
    . e($lowestAbility)
    . '</strong>. Kết quả này mang tính tham khảo và nên được kết hợp với mục tiêu cá nhân, điều kiện học tập và trải nghiệm thực tế của bạn.</p>';
    }
}