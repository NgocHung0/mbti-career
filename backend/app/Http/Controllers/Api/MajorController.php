<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Major;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Support\Str;

class MajorController extends Controller
{
    public function index(Request $request)
    {
        $q = trim((string) $request->get('q', ''));
        $perPage = (int) $request->get('per_page', 10);
        $includeInactive = (int) $request->get('include_inactive', 1) === 1;

        if ($perPage <= 0) {
            $perPage = 10;
        }

        $items = Major::query()
            ->when($q !== '', function ($query) use ($q) {
                $query->where(function ($sub) use ($q) {
                    $sub->where('name', 'like', "%{$q}%")
                        ->orWhere('code', 'like', "%{$q}%")
                        ->orWhere('description', 'like', "%{$q}%")
                        ->orWhere('career_prospects', 'like', "%{$q}%")
                        ->orWhere('skills', 'like', "%{$q}%");
                });
            })
            ->when(!$includeInactive, function ($query) {
                $query->where(function ($sub) {
                    $sub->whereNull('status')
                        ->orWhere('status', 'active');
                });
            })
            ->orderByDesc('id')
            ->paginate($perPage);

        $items->getCollection()->transform(function ($item) {
            return $this->mapMajor($item, true);
        });

        return response()->json($items);
    }

    public function show($id)
    {
        $item = Major::findOrFail($id);

        return response()->json($this->mapMajor($item));
    }

    public function store(Request $request)
    {
        $data = $request->validate($this->rules());

        $vector = [
            'E' => (int) ($data['vector_e'] ?? 50),
            'S' => (int) ($data['vector_s'] ?? 50),
            'T' => (int) ($data['vector_t'] ?? 50),
            'J' => (int) ($data['vector_j'] ?? 50),
        ];

        $imagePath = null;

        if ($request->hasFile('image')) {
            $imagePath = $request->file('image')->store('majors', 'public');
        }

        $item = Major::create([
            'name' => $data['name'],
            'code' => $data['code'] ?? null,
            'description' => $data['description'] ?? null,
            'image_url' => $imagePath,
            'career_prospects' => $data['career_prospects'] ?? null,
            'skills' => $data['skills'] ?? null,

            'suitable_mbti' => array_values($data['suitable_mbti'] ?? []),
            'interest_profile' => $this->defaultInterestProfile($data['interest_profile'] ?? []),
            'ability_profile' => $this->defaultAbilityProfile($data['ability_profile'] ?? []),

            'top_schools' => array_values($data['top_schools'] ?? []),
            'status' => $data['status'],
            'vector' => $vector,
            'vector_e' => $vector['E'],
            'vector_s' => $vector['S'],
            'vector_t' => $vector['T'],
            'vector_j' => $vector['J'],
        ]);

        return response()->json([
            'message' => 'Tạo ngành nghề thành công.',
            'data' => $this->mapMajor($item),
        ], 201);
    }

    public function update(Request $request, $id)
    {
        $item = Major::findOrFail($id);

        $data = $request->validate($this->rules($item->id));

        $vector = [
            'E' => (int) ($data['vector_e'] ?? 50),
            'S' => (int) ($data['vector_s'] ?? 50),
            'T' => (int) ($data['vector_t'] ?? 50),
            'J' => (int) ($data['vector_j'] ?? 50),
        ];

        $updateData = [
            'name' => $data['name'],
            'code' => $data['code'] ?? null,
            'description' => $data['description'] ?? null,
            'career_prospects' => $data['career_prospects'] ?? null,
            'skills' => $data['skills'] ?? null,

            'suitable_mbti' => array_values($data['suitable_mbti'] ?? []),
            'interest_profile' => $this->defaultInterestProfile($data['interest_profile'] ?? []),
            'ability_profile' => $this->defaultAbilityProfile($data['ability_profile'] ?? []),

            'top_schools' => array_values($data['top_schools'] ?? []),
            'status' => $data['status'],
            'vector' => $vector,
            'vector_e' => $vector['E'],
            'vector_s' => $vector['S'],
            'vector_t' => $vector['T'],
            'vector_j' => $vector['J'],
        ];

        if ($request->hasFile('image')) {
            $imagePath = $request->file('image')->store('majors', 'public');
            $updateData['image_url'] = $imagePath;
        }

        $item->update($updateData);

        return response()->json([
            'message' => 'Cập nhật ngành nghề thành công.',
            'data' => $this->mapMajor($item->fresh()),
        ]);
    }

    public function destroy($id)
    {
        $item = Major::findOrFail($id);
        $item->delete();

        return response()->json([
            'message' => 'Xóa ngành nghề thành công.',
        ]);
    }

    private function rules(?int $ignoreId = null): array
    {
        $codeRule = ['nullable', 'string', 'max:50'];

        if ($ignoreId) {
            $codeRule[] = Rule::unique('majors', 'code')->ignore($ignoreId);
        } else {
            $codeRule[] = 'unique:majors,code';
        }

        return [
            'name' => ['required', 'string', 'max:255'],
            'code' => $codeRule,
            'description' => ['nullable', 'string'],
            'image' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:2048'],
            'career_prospects' => ['nullable', 'string'],
            'skills' => ['nullable', 'string'],

            'top_schools' => ['nullable', 'array'],
            'top_schools.*' => ['string', 'max:255'],

            'status' => ['required', Rule::in(['active', 'inactive'])],

            'vector_e' => ['nullable', 'integer', 'min:0', 'max:100'],
            'vector_s' => ['nullable', 'integer', 'min:0', 'max:100'],
            'vector_t' => ['nullable', 'integer', 'min:0', 'max:100'],
            'vector_j' => ['nullable', 'integer', 'min:0', 'max:100'],

            'suitable_mbti' => ['nullable', 'array'],
            'suitable_mbti.*' => ['string', 'size:4'],

            'interest_profile' => ['nullable', 'array'],
            'interest_profile.creative' => ['nullable', 'integer', 'min:0', 'max:3'],
            'interest_profile.analytic' => ['nullable', 'integer', 'min:0', 'max:3'],
            'interest_profile.social' => ['nullable', 'integer', 'min:0', 'max:3'],
            'interest_profile.business' => ['nullable', 'integer', 'min:0', 'max:3'],
            
            'ability_profile' => ['nullable', 'array'],
            'ability_profile.LANGUAGE' => ['nullable', 'integer', 'min:0', 'max:3'],
            'ability_profile.LOGIC' => ['nullable', 'integer', 'min:0', 'max:3'],
            'ability_profile.CREATIVE' => ['nullable', 'integer', 'min:0', 'max:3'],
            'ability_profile.TECH' => ['nullable', 'integer', 'min:0', 'max:3'],
            'ability_profile.LEADERSHIP' => ['nullable', 'integer', 'min:0', 'max:3'],
            'ability_profile.TEAMWORK' => ['nullable', 'integer', 'min:0', 'max:3'],
            'ability_profile.DETAIL' => ['nullable', 'integer', 'min:0', 'max:3'],
            'ability_profile.ADAPT' => ['nullable', 'integer', 'min:0', 'max:3'],
            'ability_profile.PRACTICAL' => ['nullable', 'integer', 'min:0', 'max:3'],
            'ability_profile.STRATEGIC' => ['nullable', 'integer', 'min:0', 'max:3'],
        ];
    }

    private function decodeJsonArray(
        mixed $value
    ): array {
        for ($i = 0; $i < 3; $i++) {
            if (is_array($value)) {
                return $value;
            }

            if (is_object($value)) {
                return (array) $value;
            }

            if (
                !is_string($value)
                || trim($value) === ''
            ) {
                return [];
            }

            $decoded = json_decode(
                $value,
                true
            );

            if (
                json_last_error()
                !== JSON_ERROR_NONE
            ) {
                return [];
            }

            $value = $decoded;
        }

        return is_array($value)
            ? $value
            : [];
    }

    private function normalizeProfileKey(
        mixed $key
    ): string {
        $key = Str::ascii(
            trim((string) $key)
        );

        $key = strtoupper($key);

        $key = preg_replace(
            '/[^A-Z0-9]+/',
            '_',
            $key
        ) ?? '';

        return trim($key, '_');
    }

    private function normalizeProfileLevel(
        mixed $value
    ): int {
        if (!is_numeric($value)) {
            return 0;
        }

        $number = (float) $value;

        if ($number <= 0) {
            return 0;
        }

        if ($number <= 3) {
            return max(
                0,
                min(
                    3,
                    (int) round($number)
                )
            );
        }

        if ($number >= 75) {
            return 3;
        }

        if ($number >= 40) {
            return 2;
        }

        return 1;
    }

    private function defaultInterestProfile(
        mixed $input = []
    ): array {
        $input = $this->decodeJsonArray($input);

        $normalized = [];

        foreach ($input as $key => $value) {
            $normalized[
                $this->normalizeProfileKey($key)
            ] = $value;
        }

        $getValue = function (
            array $keys
        ) use ($normalized): int {
            foreach ($keys as $key) {
                if (
                    array_key_exists(
                        $key,
                        $normalized
                    )
                ) {
                    return $this->normalizeProfileLevel(
                        $normalized[$key]
                    );
                }
            }

            return 0;
        };

        return [
            'creative' => $getValue([
                'CREATIVE',
                'SANG_TAO',
            ]),

            'analytic' => $getValue([
                'ANALYTIC',
                'ANALYSIS',
                'PHAN_TICH',
                'PHAN_TICH_CONG_NGHE',
            ]),

            'social' => $getValue([
                'SOCIAL',
                'XA_HOI',
                'GIAO_TIEP',
                'XA_HOI_GIAO_TIEP',
                'CON_NGUOI_GIAO_TIEP',
            ]),

            'business' => $getValue([
                'BUSINESS',
                'KINH_DOANH',
                'KINH_DOANH_TO_CHUC',
            ]),
        ];
    }

    private function defaultAbilityProfile(
        mixed $input = []
    ): array {
        $input = $this->decodeJsonArray($input);

        $normalized = [];

        if (array_is_list($input)) {
            foreach ($input as $item) {
                if (!is_array($item)) {
                    continue;
                }

                $key =
                    $item['ability_key']
                    ?? $item['key']
                    ?? $item['name']
                    ?? $item['code']
                    ?? null;

                $value =
                    $item['weight']
                    ?? $item['value']
                    ?? $item['score']
                    ?? $item['level']
                    ?? 0;

                if ($key === null) {
                    continue;
                }

                $normalized[
                    $this->normalizeProfileKey($key)
                ] = $value;
            }
        } else {
            foreach ($input as $key => $value) {
                $normalized[
                    $this->normalizeProfileKey($key)
                ] = $value;
            }
        }

        $getValue = function (
            array $keys
        ) use ($normalized): int {
            foreach ($keys as $key) {
                if (
                    array_key_exists(
                        $key,
                        $normalized
                    )
                ) {
                    return $this->normalizeProfileLevel(
                        $normalized[$key]
                    );
                }
            }

            return 0;
        };

        return [
            'LANGUAGE' => $getValue([
                'LANGUAGE',
                'NGON_NGU',
                'NGON_NGU_DIEN_DAT',
            ]),

            'LOGIC' => $getValue([
                'LOGIC',
                'TU_DUY_LOGIC',
                'LOGIC_LAP_LUAN',
            ]),

            'CREATIVE' => $getValue([
                'CREATIVE',
                'SANG_TAO',
            ]),

            'TECH' => $getValue([
                'TECH',
                'TECHNOLOGY',
                'CONG_NGHE',
            ]),

            'LEADERSHIP' => $getValue([
                'LEADERSHIP',
                'LANH_DAO',
            ]),

            'TEAMWORK' => $getValue([
                'TEAMWORK',
                'TEAM_WORK',
                'LAM_VIEC_NHOM',
            ]),

            'DETAIL' => $getValue([
                'DETAIL',
                'CAREFUL',
                'DETAIL_CAREFUL',
                'CHI_TIET',
                'CAN_THAN',
                'CHI_TIET_CAN_THAN',
            ]),

            'ADAPT' => $getValue([
                'ADAPT',
                'ADAPTABILITY',
                'THICH_NGHI',
                'THICH_UNG',
            ]),

            'PRACTICAL' => $getValue([
                'PRACTICAL',
                'PRACTICE',
                'THUC_HANH',
            ]),

            'STRATEGIC' => $getValue([
                'STRATEGIC',
                'STRATEGY',
                'CHIEN_LUOC',
            ]),
        ];
    }

    private function mapMajor(Major $item, bool $withShort = false): array
    {
        $vector = is_array($item->vector) ? $item->vector : [];

        $e = (int) ($item->vector_e ?? ($vector['E'] ?? 50));
        $s = (int) ($item->vector_s ?? ($vector['S'] ?? 50));
        $t = (int) ($item->vector_t ?? ($vector['T'] ?? 50));
        $j = (int) ($item->vector_j ?? ($vector['J'] ?? 50));

        $data = [
            'id' => $item->id,
            'name' => $item->name,
            'code' => $item->code,
            'description' => $item->description,
            'image_url' => $item->image_url ? asset('storage/' . $item->image_url) : null,
            'career_prospects' => $item->career_prospects,
            'skills' => $item->skills,

            'suitable_mbti' => $item->suitable_mbti ?? [],
            'interest_profile' => $this->defaultInterestProfile($item->interest_profile ?? []),
            'ability_profile' => $this->defaultAbilityProfile($item->ability_profile ?? []),

            'top_schools' => $item->top_schools ?? [],
            'status' => $item->status ?? 'active',

            'vector' => [
                'E' => $e,
                'S' => $s,
                'T' => $t,
                'J' => $j,
            ],
            'vector_e' => $e,
            'vector_s' => $s,
            'vector_t' => $t,
            'vector_j' => $j,

            'created_at' => $item->created_at,
            'updated_at' => $item->updated_at,
        ];

        if ($withShort) {
            $data['short_description'] = mb_strimwidth(
                strip_tags((string) $item->description),
                0,
                140,
                '...'
            );
        }

        return $data;
    }

    public function publicList()
    {
        $items = Major::query()
            ->where(function ($sub) {
                $sub->whereNull('status')
                    ->orWhere('status', 'active');
            })
            ->orderByDesc('id')
            ->get()
            ->map(function ($item) {
                return [
                    'id' => $item->id,
                    'title' => $item->name ?? '',
                    'code' => $item->code ?? '',
                    'group' => 'Ngành nghề',
                    'desc' => $item->description ?? '',
                    'image' => $item->image_url
                        ? asset('storage/' . $item->image_url)
                        : '/images/major-default.png',
                    'career_prospects' => $item->career_prospects ?? '',
                    'skills' => $item->skills ?? '',
                    'suitable_mbti' => $item->suitable_mbti ?? [],
                    'interest_profile' => $this->defaultInterestProfile($item->interest_profile ?? []),
                    'ability_profile' => $this->defaultAbilityProfile($item->ability_profile ?? []),
                    'tags' => collect(explode(',', (string) $item->skills))
                        ->map(fn ($x) => trim($x))
                        ->filter()
                        ->values()
                        ->all(),
                    'top_schools' => $item->top_schools ?? [],
                ];
            });

        return response()->json($items);
    }
}