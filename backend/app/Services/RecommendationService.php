<?php

namespace App\Services;

use App\Models\AbilityResult;
use App\Models\InterestResult;
use App\Models\Major;
use App\Models\MbtiResult;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class RecommendationService
{
    public function recommendForUser(
        int $userId,
        string $level = 'plus',
        int $limit = 5
    ): array {
        $level = strtolower($level) === 'premium'
            ? 'premium'
            : 'plus';

        $mbti = MbtiResult::query()
            ->where('user_id', $userId)
            ->latest()
            ->first();

        $interest = InterestResult::query()
            ->where('user_id', $userId)
            ->latest()
            ->first();

        $ability = AbilityResult::query()
            ->where('user_id', $userId)
            ->latest()
            ->first();

        /*
         * Ưu tiên lấy cột scores nếu model có lưu JSON.
         */
        $storedMbtiScores = $this->decodeArray(
            $mbti?->scores ?? null
        );

        /*
         * Nếu không có scores JSON thì lấy từ
         * các cột score_e, score_i...
         */
        if ($storedMbtiScores === []) {
            $storedMbtiScores = [
                'E' => (int) ($mbti?->score_e ?? 0),
                'I' => (int) ($mbti?->score_i ?? 0),
                'S' => (int) ($mbti?->score_s ?? 0),
                'N' => (int) ($mbti?->score_n ?? 0),
                'T' => (int) ($mbti?->score_t ?? 0),
                'F' => (int) ($mbti?->score_f ?? 0),
                'J' => (int) ($mbti?->score_j ?? 0),
                'P' => (int) ($mbti?->score_p ?? 0),
            ];
        }

        return $this->recommend([
            'mbti_type' => $mbti?->mbti_type,
            'mbti_scores' => $storedMbtiScores,

            'interest_group_scores' =>
                $interest?->group_scores ?? [],

            'ability_scores' =>
                $ability?->scores ?? [],

            'level' => $level,
            'limit' => $limit,
        ]);
    }

    public function recommend(array $input): array
    {
        $level = strtolower(
            (string) ($input['level'] ?? 'plus')
        ) === 'premium'
            ? 'premium'
            : 'plus';

        $limit = max(
            1,
            min(
                20,
                (int) ($input['limit'] ?? 5)
            )
        );

        $mbtiType = strtoupper(
            trim(
                (string) (
                    $input['mbti_type'] ?? ''
                )
            )
        );

        /*
         * Điểm MBTI chỉ trả về để hiển thị.
         * Không tham gia tính điểm ngành.
         */
        $mbtiScores = $this->normalizeMbtiScores(
            $input['mbti_scores'] ?? []
        );

        /*
         * Tỷ lệ sở thích 0–100.
         */
        $interestPercentages =
            $this->normalizeInterestGroupScores(
                $input['interest_group_scores'] ?? []
            );

        /*
         * Tỷ lệ năng lực 0–100.
         */
        $abilityPercentages =
            $this->normalizeAbilityScores(
                $input['ability_scores'] ?? []
            );

        /*
         * Quy đổi tỷ lệ thành mức người dùng 0–3.
         */
        $interestLevels =
            $this->buildInterestUserLevels(
                $interestPercentages
            );

        $abilityLevels =
            $this->buildAbilityUserLevels(
                $abilityPercentages
            );

        /*
         * Không có MBTI thì không thể lọc ngành.
         */
        if ($mbtiType === '') {
            return [
                'level' => $level,
                'mbti_type' => '',
                'mbti_scores' => $mbtiScores,

                'interest_group_scores' =>
                    $interestPercentages,

                'interest_levels' =>
                    $interestLevels,

                'ability_scores' =>
                    $abilityPercentages,

                'ability_levels' =>
                    $abilityLevels,

                'top_majors' => [],
            ];
        }

        $interestKeys = [
            'creative',
            'analytic',
            'social',
            'business',
        ];

        $abilityKeys = [
            'LANGUAGE',
            'LOGIC',
            'CREATIVE',
            'TECH',
            'LEADERSHIP',
            'TEAMWORK',
            'DETAIL',
            'ADAPT',
            'PRACTICAL',
            'STRATEGIC',
        ];

        /*
         * MBTI chỉ dùng để lọc ngành.
         */
        $majors = Major::query()
            ->where(function ($query) {
                $query
                    ->whereNull('status')
                    ->orWhere('status', 'active');
            })
            ->get()
            ->filter(function (Major $major) use (
                $mbtiType
            ) {
                return $this->majorMatchesMbti(
                    $mbtiType,
                    $major->suitable_mbti ?? []
                );
            });

        $items = $majors
            ->map(function (Major $major) use (
                $mbtiType,
                $interestLevels,
                $abilityLevels,
                $interestKeys,
                $abilityKeys,
                $level
            ) {
                /*
                 * Match sở thích:
                 *
                 * Σ(u × w / 3)
                 * ---------------- × 100
                 *       Σw
                 */
                $interestFit =
                    $this->calculateWeightedProfileFit(
                        $interestLevels,
                        $major->interest_profile ?? [],
                        $interestKeys
                    );

                /*
                 * Hồ sơ ngành không có trọng số
                 * sở thích thì không xếp hạng.
                 */
                if (!$interestFit['valid']) {
                    return null;
                }

                $abilityFit = [
                    'valid' => true,
                    'percent' => 0.0,
                    'core_percent' => 0.0,
                    'core_count' => 0,
                ];

                /*
                 * Premium mới tính năng lực.
                 */
                if ($level === 'premium') {
                    $abilityFit =
                        $this->calculateWeightedProfileFit(
                            $abilityLevels,
                            $major->ability_profile ?? [],
                            $abilityKeys
                        );

                    /*
                     * Hồ sơ Premium phải có
                     * trọng số năng lực hợp lệ.
                     */
                    if (!$abilityFit['valid']) {
                        return null;
                    }
                }

                if ($level === 'premium') {
                    /*
                     * Premium:
                     * 50% sở thích + 50% năng lực.
                     */
                    $finalScore = round(
                        (
                            0.5 *
                            $interestFit['percent']
                        ) +
                        (
                            0.5 *
                            $abilityFit['percent']
                        ),
                        1
                    );

                    /*
                     * Điểm tiêu chí cốt lõi dùng
                     * để xử lý trường hợp bằng điểm.
                     */
                    $coreScore = round(
                        (
                            0.5 *
                            $interestFit['core_percent']
                        ) +
                        (
                            0.5 *
                            $abilityFit['core_percent']
                        ),
                        4
                    );

                    $coreCount =
                        $interestFit['core_count'] +
                        $abilityFit['core_count'];

                    $formula =
                        'Premium = 50% sở thích + 50% năng lực; MBTI chỉ dùng để lọc ngành';
                } else {
                    /*
                     * Plus chỉ dùng điểm sở thích.
                     */
                    $finalScore = round(
                        $interestFit['percent'],
                        1
                    );

                    $coreScore =
                        $interestFit['core_percent'];

                    $coreCount =
                        $interestFit['core_count'];

                    $formula =
                        'Plus = điểm sở thích; MBTI chỉ dùng để lọc ngành';
                }

                /*
                 * Chỉ truy vấn trường một lần
                 * cho mỗi ngành.
                 */
                $universities =
                    $this->findUniversitiesForMajor(
                        $major
                    );

                return [
                    'id' => $major->id,
                    'code' => $major->code,
                    'name' => $major->name,

                    'description' =>
                        $major->description,

                    'career_prospects' =>
                        $major->career_prospects,

                    'skills' => $major->skills,

                    'suitable_mbti' =>
                        $major->suitable_mbti ?? [],

                    /*
                     * Điểm xếp hạng cuối.
                     */
                    'score' => $finalScore,

                    /*
                     * MBTI đã khớp vì ngành
                     * đã đi qua bước lọc.
                     */
                    'fit_mbti' => 100,

                    'fit_interest' => round(
                        $interestFit['percent'],
                        1
                    ),

                    'fit_ability' =>
                        $level === 'premium'
                            ? round(
                                $abilityFit['percent'],
                                1
                            )
                            : null,

                    'universities' => $universities,
                    'schools' => $universities,

                    'reasons' => $this->buildReasons(
                        $mbtiType,
                        100,
                        (int) round(
                            $interestFit['percent']
                        ),
                        (int) round(
                            $abilityFit['percent']
                        ),
                        $level
                    ),

                    'explain' => [
                        'mbti' =>
                            "MBTI {$mbtiType} được dùng để lọc ngành, không cộng vào điểm",

                        'interest' =>
                            'Điểm sở thích: ' .
                            round(
                                $interestFit['percent'],
                                1
                            ) .
                            '%',

                        'ability' =>
                            $level === 'premium'
                                ? 'Điểm năng lực: ' .
                                    round(
                                        $abilityFit['percent'],
                                        1
                                    ) .
                                    '%'
                                : null,

                        'formula' => $formula,
                    ],

                    /*
                     * Các trường nội bộ dùng để
                     * xử lý trường hợp bằng điểm.
                     */
                    '_core_score' => $coreScore,
                    '_core_count' => $coreCount,

                    '_stable_key' => mb_strtolower(
                        trim(
                            (string) (
                                $major->code
                                ?: $major->name
                            )
                        )
                    ),
                ];
            })
            ->filter()
            ->sort(function (
                array $left,
                array $right
            ) {
                /*
                 * 1. Điểm tổng cao hơn.
                 */
                $scoreCompare =
                    $right['score']
                    <=>
                    $left['score'];

                if ($scoreCompare !== 0) {
                    return $scoreCompare;
                }

                /*
                 * 2. Điểm tiêu chí cốt lõi cao hơn.
                 */
                $coreCompare =
                    $right['_core_score']
                    <=>
                    $left['_core_score'];

                if ($coreCompare !== 0) {
                    return $coreCompare;
                }

                /*
                 * 3. Ngành có nhiều trọng số 3 hơn.
                 */
                $countCompare =
                    $right['_core_count']
                    <=>
                    $left['_core_count'];

                if ($countCompare !== 0) {
                    return $countCompare;
                }

                /*
                 * 4. Sắp xếp cố định theo
                 * mã ngành hoặc tên ngành.
                 */
                return strcmp(
                    $left['_stable_key'],
                    $right['_stable_key']
                );
            })
            ->take($limit)
            ->map(function (array $item) {
                unset(
                    $item['_core_score'],
                    $item['_core_count'],
                    $item['_stable_key']
                );

                return $item;
            })
            ->values()
            ->all();

        return [
            'level' => $level,
            'mbti_type' => $mbtiType,
            'mbti_scores' => $mbtiScores,

            'interest_group_scores' =>
                $interestPercentages,

            'interest_levels' =>
                $interestLevels,

            'ability_scores' =>
                $abilityPercentages,

            'ability_levels' =>
                $abilityLevels,

            'top_majors' => $items,
        ];
    }

    /**
     * Chuyển JSON hoặc array thành array.
     */
    private function decodeArray(
        array|string|null $value
    ): array {
        if (is_array($value)) {
            return $value;
        }

        if (is_string($value)) {
            $decoded = json_decode(
                $value,
                true
            );

            if (is_array($decoded)) {
                return $decoded;
            }
        }

        return [];
    }

    /**
     * Quy đổi tỷ lệ 0–100 thành mức 0–3.
     */
    private function percentToUserLevel(
        float $percent
    ): int {
        $percent = max(
            0,
            min(100, $percent)
        );

        if ($percent < 25) {
            return 0;
        }

        if ($percent < 50) {
            return 1;
        }

        if ($percent < 75) {
            return 2;
        }

        return 3;
    }

    /**
     * Tạo vector 4 mức sở thích.
     */
    private function buildInterestUserLevels(
        array $percentages
    ): array {
        $keys = [
            'creative',
            'analytic',
            'social',
            'business',
        ];

        $levels = [];

        foreach ($keys as $key) {
            $levels[$key] =
                $this->percentToUserLevel(
                    (float) (
                        $percentages[$key] ?? 0
                    )
                );
        }

        return $levels;
    }

    /**
     * Tạo vector 10 mức năng lực.
     */
    private function buildAbilityUserLevels(
        array $scores
    ): array {
        $keys = [
            'LANGUAGE',
            'LOGIC',
            'CREATIVE',
            'TECH',
            'LEADERSHIP',
            'TEAMWORK',
            'DETAIL',
            'ADAPT',
            'PRACTICAL',
            'STRATEGIC',
        ];

        /*
         * Hỗ trợ dữ liệu cũ:
         * 0–6 là số lần được chọn.
         *
         * Dữ liệu mới:
         * 0–100 là tỷ lệ.
         */
        $maximum = 0.0;

        foreach ($keys as $key) {
            $maximum = max(
                $maximum,
                (float) (
                    $scores[$key] ?? 0
                )
            );
        }

        $looksLikeOldSelectedCounts =
            $maximum > 0 &&
            $maximum <= 6;

        $levels = [];

        foreach ($keys as $key) {
            $value = max(
                0,
                (float) (
                    $scores[$key] ?? 0
                )
            );

            $percent =
                $looksLikeOldSelectedCounts
                    ? ($value / 6) * 100
                    : $value;

            $levels[$key] =
                $this->percentToUserLevel(
                    $percent
                );
        }

        return $levels;
    }

    /**
     * Kiểm tra MBTI người dùng có nằm trong
     * danh sách MBTI phù hợp của ngành không.
     */
    private function majorMatchesMbti(
        string $mbtiType,
        array|string|null $suitableMbti
    ): bool {
        if (is_string($suitableMbti)) {
            $decoded = json_decode(
                $suitableMbti,
                true
            );

            $suitableMbti =
                is_array($decoded)
                    ? $decoded
                    : (
                        preg_split(
                            '/[,;|]+/',
                            $suitableMbti
                        ) ?: []
                    );
        }

        $normalizedMbti = strtoupper(
            trim($mbtiType)
        );

        $normalizedList = collect(
            $suitableMbti ?? []
        )
            ->flatten()
            ->map(function ($type) {
                return strtoupper(
                    trim((string) $type)
                );
            })
            ->filter()
            ->unique()
            ->values()
            ->all();

        return in_array(
            $normalizedMbti,
            $normalizedList,
            true
        );
    }

    /**
     * Tính điểm:
     *
     * c = u × w / 3
     *
     * Match = Σc / Σw × 100
     */
    private function calculateWeightedProfileFit(
        array $userLevels,
        array|string|null $profile,
        array $keys
    ): array {
        $profile = $this->decodeArray(
            $profile
        );

        /*
         * Chuẩn hóa key để hỗ trợ:
         * creative và CREATIVE.
         */
        $normalizedUserLevels = [];
        $normalizedProfile = [];

        foreach ($userLevels as $key => $value) {
            $normalizedUserLevels[
                strtoupper(
                    trim((string) $key)
                )
            ] = $value;
        }

        foreach ($profile as $key => $value) {
            $normalizedProfile[
                strtoupper(
                    trim((string) $key)
                )
            ] = $value;
        }

        $contributionTotal = 0.0;
        $weightTotal = 0;

        $coreContributionTotal = 0.0;
        $coreWeightTotal = 0;
        $coreCount = 0;

        foreach ($keys as $key) {
            $normalizedKey = strtoupper(
                trim((string) $key)
            );

            $userLevel = max(
                0,
                min(
                    3,
                    (int) (
                        $normalizedUserLevels[
                            $normalizedKey
                        ] ?? 0
                    )
                )
            );

            $industryWeight = max(
                0,
                min(
                    3,
                    (int) (
                        $normalizedProfile[
                            $normalizedKey
                        ] ?? 0
                    )
                )
            );

            /*
             * Trọng số 0 không tham gia tính điểm.
             */
            if ($industryWeight === 0) {
                continue;
            }

            /*
             * cᵢ = uᵢ × wᵢ / 3
             */
            $contribution =
                (
                    $userLevel *
                    $industryWeight
                ) / 3;

            $contributionTotal +=
                $contribution;

            $weightTotal +=
                $industryWeight;

            /*
             * Tiêu chí trọng số 3 là
             * tiêu chí cốt lõi.
             */
            if ($industryWeight === 3) {
                $coreContributionTotal +=
                    $contribution;

                $coreWeightTotal +=
                    $industryWeight;

                $coreCount++;
            }
        }

        /*
         * Tổng trọng số bằng 0:
         * hồ sơ ngành không hợp lệ.
         */
        if ($weightTotal <= 0) {
            return [
                'valid' => false,
                'percent' => 0.0,
                'core_percent' => 0.0,
                'core_count' => 0,
            ];
        }

        $percent =
            (
                $contributionTotal /
                $weightTotal
            ) * 100;

        $corePercent =
            $coreWeightTotal > 0
                ? (
                    $coreContributionTotal /
                    $coreWeightTotal
                ) * 100
                : 0.0;

        return [
            'valid' => true,

            'percent' => max(
                0,
                min(100, $percent)
            ),

            'core_percent' => max(
                0,
                min(
                    100,
                    $corePercent
                )
            ),

            'core_count' => $coreCount,
        ];
    }

    /**
     * Chuẩn hóa tỷ lệ sở thích.
     */
    private function normalizeInterestGroupScores(
        array|string|null $scores
    ): array {
        $scores = $this->decodeArray(
            $scores
        );

        return [
            'creative' => max(
                0,
                min(
                    100,
                    (float) (
                        $scores['creative'] ?? 0
                    )
                )
            ),

            'analytic' => max(
                0,
                min(
                    100,
                    (float) (
                        $scores['analytic'] ?? 0
                    )
                )
            ),

            'social' => max(
                0,
                min(
                    100,
                    (float) (
                        $scores['social'] ?? 0
                    )
                )
            ),

            'business' => max(
                0,
                min(
                    100,
                    (float) (
                        $scores['business'] ?? 0
                    )
                )
            ),
        ];
    }

    /**
     * Chuẩn hóa điểm MBTI.
     */
    private function normalizeMbtiScores(
        array|string|null $scores
    ): array {
        $scores = $this->decodeArray(
            $scores
        );

        return [
            'E' => (int) (
                $scores['E'] ??
                $scores['score_e'] ??
                0
            ),

            'I' => (int) (
                $scores['I'] ??
                $scores['score_i'] ??
                0
            ),

            'S' => (int) (
                $scores['S'] ??
                $scores['score_s'] ??
                0
            ),

            'N' => (int) (
                $scores['N'] ??
                $scores['score_n'] ??
                0
            ),

            'T' => (int) (
                $scores['T'] ??
                $scores['score_t'] ??
                0
            ),

            'F' => (int) (
                $scores['F'] ??
                $scores['score_f'] ??
                0
            ),

            'J' => (int) (
                $scores['J'] ??
                $scores['score_j'] ??
                0
            ),

            'P' => (int) (
                $scores['P'] ??
                $scores['score_p'] ??
                0
            ),
        ];
    }

    /**
     * Chuẩn hóa tỷ lệ năng lực.
     */
    private function normalizeAbilityScores(
        array|string|null $scores
    ): array {
        $scores = $this->decodeArray(
            $scores
        );

        $keys = [
            'LANGUAGE',
            'LOGIC',
            'CREATIVE',
            'TECH',
            'LEADERSHIP',
            'TEAMWORK',
            'DETAIL',
            'ADAPT',
            'PRACTICAL',
            'STRATEGIC',
        ];

        $normalized = [];

        foreach ($keys as $key) {
            $value =
                $scores[$key]
                ?? $scores[strtolower($key)]
                ?? 0;

            /*
             * Giữ số thập phân như 66.67.
             */
            $normalized[$key] = max(
                0,
                min(
                    100,
                    (float) $value
                )
            );
        }

        return $normalized;
    }

    /**
     * Chuẩn hóa URL logo trường.
     */
    private function resolveAdmissionLogo(
        ?string $value
    ): ?string {
        if (!$value) {
            return null;
        }

        $raw = trim($value);

        if ($raw === '') {
            return null;
        }

        if (
            str_starts_with(
                $raw,
                'http://'
            ) ||
            str_starts_with(
                $raw,
                'https://'
            )
        ) {
            return $raw;
        }

        $raw = ltrim(
            $raw,
            '/'
        );

        if (
            str_starts_with(
                $raw,
                'images/'
            ) ||
            str_starts_with(
                $raw,
                'assets/'
            )
        ) {
            return asset($raw);
        }

        if (
            str_starts_with(
                $raw,
                'storage/images/'
            ) ||
            str_starts_with(
                $raw,
                'storage/assets/'
            )
        ) {
            return asset($raw);
        }

        if (
            Storage::disk('public')
                ->exists($raw)
        ) {
            return asset(
                'storage/' . $raw
            );
        }

        $withoutStorage = preg_replace(
            '/^storage\//',
            '',
            $raw
        );

        if (
            $withoutStorage &&
            Storage::disk('public')
                ->exists($withoutStorage)
        ) {
            return asset(
                'storage/' .
                $withoutStorage
            );
        }

        $clean = preg_replace(
            '/^storage\/admissions\//',
            '',
            $raw
        );

        $clean = preg_replace(
            '/^admissions\//',
            '',
            (string) $clean
        );

        $name = pathinfo(
            (string) $clean,
            PATHINFO_FILENAME
        );

        foreach (
            [
                'png',
                'jpg',
                'jpeg',
                'webp',
                'gif',
                'svg',
            ] as $extension
        ) {
            $path =
                "admissions/{$name}.{$extension}";

            if (
                Storage::disk('public')
                    ->exists($path)
            ) {
                return asset(
                    'storage/' . $path
                );
            }
        }

        return null;
    }

    /**
     * Lấy tối đa 5 trường phù hợp với ngành.
     */
    private function findUniversitiesForMajor(
        Major $major
    ): array {
        $items = collect();

        $majorName = trim(
            (string) $major->name
        );

        $majorCode = trim(
            (string) $major->code
        );

        $searchTerms =
            $this->buildAdmissionSearchTerms(
                $majorName,
                $majorCode
            );

        if ($searchTerms !== []) {
            $admissions = DB::table(
                'admissions'
            )
                ->where(
                    'is_active',
                    1
                )
                ->where(
                    function ($query) use (
                        $searchTerms
                    ) {
                        foreach (
                            $searchTerms
                            as $term
                        ) {
                            $query
                                ->orWhere(
                                    'major_name',
                                    'like',
                                    "%{$term}%"
                                )
                                ->orWhere(
                                    'school_name',
                                    'like',
                                    "%{$term}%"
                                )
                                ->orWhere(
                                    'tags',
                                    'like',
                                    "%{$term}%"
                                );
                        }
                    }
                )
                ->orderByDesc(
                    'featured'
                )
                ->orderBy(
                    'sort_order'
                )
                ->orderBy(
                    'school_name'
                )
                ->limit(10)
                ->get();

            foreach (
                $admissions as $admission
            ) {
                $items->push([
                    'school_name' =>
                        $admission->school_name,

                    'name' =>
                        $admission->school_name,

                    'city' =>
                        $admission->city,

                    'featured' => (bool) (
                        $admission->featured
                        ?? false
                    ),

                    'major_name' =>
                        $admission->major_name,

                    'short_description' =>
                        $admission
                            ->short_description
                        ?? 'Trường có dữ liệu tuyển sinh phù hợp với ngành này.',

                    'tuition_fee' =>
                        $admission->tuition_fee,

                    'application_deadline' =>
                        $admission
                            ->application_deadline,

                    'register_link' =>
                        $admission->register_link,

                    'image_url' =>
                        $this->resolveAdmissionLogo(
                            $admission->image_url
                        ),

                    'reason' =>
                        'Trường có dữ liệu tuyển sinh phù hợp.',
                ]);
            }
        }

        /*
         * Nếu chưa tìm thấy tuyển sinh,
         * dùng top_schools của ngành.
         */
        if ($items->isEmpty()) {
            $topSchools =
                $major->top_schools ?? [];

            if (is_string($topSchools)) {
                $decoded = json_decode(
                    $topSchools,
                    true
                );

                $topSchools =
                    is_array($decoded)
                        ? $decoded
                        : array_map(
                            'trim',
                            explode(
                                ',',
                                $topSchools
                            )
                        );
            }

            foreach (
                $topSchools as $school
            ) {
                $items->push([
                    'school_name' => $school,
                    'name' => $school,
                    'featured' => false,

                    'reason' =>
                        'Trường tham khảo của ngành.',
                ]);
            }
        }

        return $items
            ->unique('school_name')
            ->sort(function (
                $left,
                $right
            ) {
                $featuredLeft =
                    !empty(
                        $left['featured']
                    )
                        ? 1
                        : 0;

                $featuredRight =
                    !empty(
                        $right['featured']
                    )
                        ? 1
                        : 0;

                if (
                    $featuredLeft !==
                    $featuredRight
                ) {
                    return $featuredRight
                        <=>
                        $featuredLeft;
                }

                return strcmp(
                    $left['school_name']
                        ?? '',
                    $right['school_name']
                        ?? ''
                );
            })
            ->values()
            ->take(5)
            ->all();
    }

    /**
     * Tạo các từ khóa dùng để tìm dữ liệu
     * tuyển sinh tương ứng với ngành.
     */
    private function buildAdmissionSearchTerms(
        string $majorName,
        string $majorCode
    ): array {
        $name = mb_strtolower(
            $majorName
        );

        $terms = [];

        if ($majorName !== '') {
            $terms[] = $majorName;
        }

        if ($majorCode !== '') {
            $terms[] = $majorCode;
        }

        if (
            str_contains(
                $name,
                'tài chính'
            )
        ) {
            $terms[] = 'Tài chính';
            $terms[] =
                'Tài chính ngân hàng';
            $terms[] = 'Ngân hàng';
        }

        if (
            str_contains(
                $name,
                'kế toán'
            ) ||
            str_contains(
                $name,
                'kiểm toán'
            )
        ) {
            $terms[] = 'Kế toán';
            $terms[] = 'Kiểm toán';
            $terms[] = 'Tài chính';
            $terms[] =
                'Tài chính ngân hàng';
        }

        if (
            str_contains(
                $name,
                'công nghệ'
            ) ||
            str_contains(
                $name,
                'kỹ thuật'
            )
        ) {
            $terms[] =
                'Công nghệ thông tin';

            $terms[] =
                'Kỹ thuật điện';

            $terms[] =
                'Kỹ thuật cơ điện tử';

            $terms[] =
                'Công nghệ thực phẩm';
        }

        if (
            str_contains(
                $name,
                'marketing'
            ) ||
            str_contains(
                $name,
                'truyền thông'
            )
        ) {
            $terms[] = 'Marketing';

            $terms[] =
                'Truyền thông đa phương tiện';

            $terms[] =
                'Quản trị kinh doanh';
        }

        if (
            str_contains(
                $name,
                'luật'
            )
        ) {
            $terms[] = 'Luật kinh tế';
        }

        if (
            str_contains(
                $name,
                'kiến trúc'
            )
        ) {
            $terms[] = 'Kiến trúc';
        }

        /*
         * Không dùng điều kiện chứa chữ "y"
         * vì sẽ khớp nhầm rất nhiều ngành.
         */
        if (
            str_contains(
                $name,
                'y khoa'
            ) ||
            str_contains(
                $name,
                'y đa khoa'
            ) ||
            str_contains(
                $name,
                'dược'
            ) ||
            str_contains(
                $name,
                'điều dưỡng'
            ) ||
            str_contains(
                $name,
                'răng hàm mặt'
            )
        ) {
            $terms[] = 'Y đa khoa';
            $terms[] = 'Dược học';
            $terms[] = 'Điều dưỡng';
            $terms[] = 'Răng Hàm Mặt';
        }

        return collect($terms)
            ->map(function ($term) {
                return trim(
                    (string) $term
                );
            })
            ->filter()
            ->unique()
            ->values()
            ->all();
    }

    /**
     * Tạo lý do giải thích kết quả.
     */
    private function buildReasons(
        string $mbtiType,
        int $mbtiFit,
        int $interestFit,
        int $abilityFit,
        string $level
    ): array {
        $reasons = [];

        if ($mbtiFit >= 70) {
            $reasons[] =
                "MBTI {$mbtiType} nằm trong nhóm phù hợp với ngành này.";
        }

        if ($interestFit >= 60) {
            $reasons[] =
                'Sở thích của bạn khớp với nhóm đặc trưng ngành.';
        }

        if (
            $level === 'premium' &&
            $abilityFit >= 60
        ) {
            $reasons[] =
                'Năng lực hiện tại khớp với yêu cầu chính của ngành.';
        }

        if ($reasons === []) {
            $reasons[] =
                'Ngành này được xếp hạng sau khi lọc MBTI và so khớp hồ sơ người dùng với trọng số ngành.';
        }

        return $reasons;
    }
}