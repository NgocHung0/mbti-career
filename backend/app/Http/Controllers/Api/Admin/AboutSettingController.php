<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AboutSetting;
use App\Models\AboutStat;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AboutSettingController extends Controller
{
    public function show(): JsonResponse
    {
        $setting = AboutSetting::query()->first();

        $stats = AboutStat::query()
            ->orderBy('sort_order')
            ->orderBy('id')
            ->get();

        return response()->json([
            'setting' => $setting,
            'stats' => $stats,
        ]);
    }

    public function save(Request $request): JsonResponse
    {
        $data = $request->validate([
            'hero_title' => ['nullable', 'string', 'max:255'],
            'short_description' => ['nullable', 'string'],
            'full_description' => ['nullable', 'string'],
            'privacy_policy' => ['nullable','string'],
            

            'mission_title' => ['nullable', 'string', 'max:255'],
            'mission_description' => ['nullable', 'string'],
            'vision_title' => ['nullable', 'string', 'max:255'],
            'vision_description' => ['nullable', 'string'],
            'banner_image' => ['nullable', 'string', 'max:2048'],
            'secondary_image' => ['nullable', 'string', 'max:2048'],
        ]);

        $setting = AboutSetting::query()->first();

        if (!$setting) {
            $setting = new AboutSetting();
        }

$setting->fill([
    'hero_title' => $data['hero_title'] ?? null,
    'short_description' => $data['short_description'] ?? null,
    'full_description' => $data['full_description'] ?? null,

    'mission_title' => $data['mission_title'] ?? null,
    'mission_description' => $data['mission_description'] ?? null,

    'vision_title' => $data['vision_title'] ?? null,
    'vision_description' => $data['vision_description'] ?? null,

    'privacy_policy' => $data['privacy_policy'] ?? null,

    'banner_image' => $data['banner_image'] ?? null,
    'secondary_image' => $data['secondary_image'] ?? null,
]);

        $setting->save();

        return response()->json([
            'message' => 'Lưu nội dung trang Về chúng tôi thành công.',
            'setting' => $setting,
        ]);
    }

    public function createStat(Request $request): JsonResponse
    {
        $data = $request->validate([
            'label' => ['required', 'string', 'max:255'],
            'value' => ['required', 'string', 'max:255'],
            'sort_order' => ['nullable', 'integer', 'min:1'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $stat = AboutStat::query()->create([
            'label' => $data['label'],
            'value' => $data['value'],
            'sort_order' => $data['sort_order'] ?? 1,
            'is_active' => (bool) ($data['is_active'] ?? true),
        ]);

        return response()->json($stat);
    }

    public function updateStat(Request $request, int $id): JsonResponse
    {
        $stat = AboutStat::query()->findOrFail($id);

        $data = $request->validate([
            'label' => ['required', 'string', 'max:255'],
            'value' => ['required', 'string', 'max:255'],
            'sort_order' => ['nullable', 'integer', 'min:1'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $stat->update([
            'label' => $data['label'],
            'value' => $data['value'],
            'sort_order' => $data['sort_order'] ?? $stat->sort_order,
            'is_active' => (bool) ($data['is_active'] ?? $stat->is_active),
        ]);

        return response()->json($stat->fresh());
    }

    public function deleteStat(int $id): JsonResponse
    {
        $stat = AboutStat::query()->findOrFail($id);
        $stat->delete();

        return response()->json([
            'message' => 'Xóa thống kê thành công.',
        ]);
    }

    public function uploadImage(Request $request): JsonResponse
    {
        $request->validate([
            'image' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:4096'],
            'type' => ['nullable', 'string', 'in:banner,secondary'],
        ]);

        $file = $request->file('image');
        $type = $request->input('type', 'banner');

        $path = $file->store("about/{$type}", 'public');

        return response()->json([
            'message' => 'Tải ảnh thành công.',
            'path' => $path,
            'url' => asset('storage/' . $path),
        ]);
    }
}