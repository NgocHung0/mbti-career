<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Admission;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Throwable;

class AdmissionController extends Controller
{
    public function index(Request $request)
    {
        $q = trim((string) $request->get('q', ''));
        $status = trim((string) $request->get('status', 'all'));

        $perPage = (int) $request->get('per_page', 10);
        $includeInactive =
            (int) $request->get('include_inactive', 1) === 1;

        $perPage = max(1, min($perPage, 100));

        $query = Admission::query();

        if ($q !== '') {
            $query->where(function ($subQuery) use ($q) {
                $subQuery
                    ->where(
                        'school_name',
                        'like',
                        '%' . $q . '%'
                    )
                    ->orWhere(
                        'major_name',
                        'like',
                        '%' . $q . '%'
                    );
            });
        }

        /*
        * Lọc trạng thái trên toàn bộ database.
        */
        if (
            in_array(
                $status,
                ['coming_soon', 'open', 'closed'],
                true
            )
        ) {
            $query->where('status', $status);
        }

        if (!$includeInactive) {
            $query->where('is_active', true);
        }

        $items = $query
            ->orderBy('sort_order')
            ->orderByDesc('id')
            ->paginate($perPage)
            ->appends($request->query());

        return response()->json($items);
    }

    public function publicList()
    {
        $items = Admission::query()
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->orderByDesc('id')
            ->get();

        return response()->json($items);
    }

    public function show($id)
    {
        $item = Admission::findOrFail($id);
        return response()->json($item);
    }

    public function store(Request $request)
    {
        try {
            $data = $request->validate([
                'school_name' => ['required', 'string', 'max:255'],
                'major_name' => ['required', 'string', 'max:255'],
                'city' => ['nullable', 'string', 'max:255'],
                'short_description' => ['nullable', 'string'],
                'image' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:2048'],
                'tags' => ['nullable'],
                'status' => ['required', Rule::in(['coming_soon', 'open', 'closed'])],
                'featured' => ['nullable'],
                'tuition_fee' => ['nullable', 'string', 'max:255'],
                'duration' => ['nullable', 'string', 'max:255'],
                'degree' => ['nullable', 'string', 'max:255'],
                'admission_method' => ['nullable', 'string', 'max:500'],
                'application_deadline' => ['nullable', 'string', 'max:255'],
                'start_date' => ['nullable', 'string', 'max:255'],
                'register_link' => ['nullable', 'string', 'max:255'],
                'contact_phone' => ['nullable', 'string', 'max:255'],
                'contact_email' => ['nullable', 'email', 'max:255'],
                'sort_order' => ['nullable', 'integer'],
                'is_active' => ['nullable'],
            ]);

            $imagePath = null;
            if ($request->hasFile('image')) {
                $imagePath = $request->file('image')->store('admissions', 'public');
            }

            $tags = $request->input('tags', []);
            if (is_string($tags)) {
                $tags = array_values(array_filter(array_map('trim', explode(',', $tags))));
            }

            $item = Admission::create([
                'school_name' => trim((string) $data['school_name']),
                'major_name' => trim((string) $data['major_name']),
                'city' => $data['city'] ?? null,
                'short_description' => $data['short_description'] ?? null,
                'image_url' => $imagePath,
                'tags' => is_array($tags) ? $tags : [],
                'status' => $data['status'],
                'featured' => in_array($request->input('featured'), ['1', 1, true, 'true', 'on'], true),
                'tuition_fee' => $data['tuition_fee'] ?? null,
                'duration' => $data['duration'] ?? null,
                'degree' => $data['degree'] ?? null,
                'admission_method' => $data['admission_method'] ?? null,
                'application_deadline' => $data['application_deadline'] ?? null,
                'start_date' => $data['start_date'] ?? null,
                'register_link' => $data['register_link'] ?? null,
                'contact_phone' => $data['contact_phone'] ?? null,
                'contact_email' => $data['contact_email'] ?? null,
                'sort_order' => (int) ($data['sort_order'] ?? 0),
                'is_active' => filter_var($request->input('is_active', true), FILTER_VALIDATE_BOOLEAN),
            ]);

            return response()->json([
                'message' => 'Tạo tuyển sinh thành công.',
                'data' => $item,
            ], 201);
        } catch (Throwable $e) {
            Log::error('Admission store error', [
                'message' => $e->getMessage(),
                'line' => $e->getLine(),
                'file' => $e->getFile(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'message' => 'Lỗi khi tạo tuyển sinh.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function update(Request $request, $id)
    {
        try {
            $item = Admission::findOrFail($id);

            $data = $request->validate([
                'school_name' => ['required', 'string', 'max:255'],
                'major_name' => ['required', 'string', 'max:255'],
                'city' => ['nullable', 'string', 'max:255'],
                'short_description' => ['nullable', 'string'],
                'image' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:2048'],
                'tags' => ['nullable'],
                'status' => ['required', Rule::in(['coming_soon', 'open', 'closed'])],
                'featured' => ['nullable'],
                'tuition_fee' => ['nullable', 'string', 'max:255'],
                'duration' => ['nullable', 'string', 'max:255'],
                'degree' => ['nullable', 'string', 'max:255'],
                'admission_method' => ['nullable', 'string', 'max:500'],
                'application_deadline' => ['nullable', 'string', 'max:255'],
                'start_date' => ['nullable', 'string', 'max:255'],
                'register_link' => ['nullable', 'string', 'max:255'],
                'contact_phone' => ['nullable', 'string', 'max:255'],
                'contact_email' => ['nullable', 'email', 'max:255'],
                'sort_order' => ['nullable', 'integer'],
                'is_active' => ['nullable'],
            ]);

            $tags = $request->input('tags', []);
            if (is_string($tags)) {
                $tags = array_values(array_filter(array_map('trim', explode(',', $tags))));
            }

            $updateData = [
                'school_name' => trim((string) $data['school_name']),
                'major_name' => trim((string) $data['major_name']),
                'city' => $data['city'] ?? null,
                'short_description' => $data['short_description'] ?? null,
                'tags' => is_array($tags) ? $tags : [],
                'status' => $data['status'],
                'featured' => in_array($request->input('featured'), ['1', 1, true, 'true', 'on'], true),
                'tuition_fee' => $data['tuition_fee'] ?? null,
                'duration' => $data['duration'] ?? null,
                'degree' => $data['degree'] ?? null,
                'admission_method' => $data['admission_method'] ?? null,
                'application_deadline' => $data['application_deadline'] ?? null,
                'start_date' => $data['start_date'] ?? null,
                'register_link' => $data['register_link'] ?? null,
                'contact_phone' => $data['contact_phone'] ?? null,
                'contact_email' => $data['contact_email'] ?? null,
                'sort_order' => (int) ($data['sort_order'] ?? 0),
                'is_active' => filter_var($request->input('is_active', true), FILTER_VALIDATE_BOOLEAN),
            ];

            if ($request->hasFile('image')) {
                if (
                    !empty($item->image_url) &&
                    is_string($item->image_url) &&
                    Storage::disk('public')->exists($item->image_url)
                ) {
                    Storage::disk('public')->delete($item->image_url);
                }

                $imagePath = $request->file('image')->store('admissions', 'public');
                $updateData['image_url'] = $imagePath;
            }

            $updateData['featured'] = $request->has('featured')
                ? (int) $request->input('featured')
                : 0;

            $item->update($updateData);

            return response()->json([
                'message' => 'Cập nhật tuyển sinh thành công.',
                'data' => $item->fresh(),
            ]);
        } catch (Throwable $e) {
            Log::error('Admission update error', [
                'admission_id' => $id,
                'message' => $e->getMessage(),
                'line' => $e->getLine(),
                'file' => $e->getFile(),
                'trace' => $e->getTraceAsString(),
                'payload' => $request->except(['image']),
            ]);

            return response()->json([
                'message' => 'Lỗi khi cập nhật tuyển sinh.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function destroy($id)
    {
        try {
            $item = Admission::findOrFail($id);

            if (
                !empty($item->image_url) &&
                is_string($item->image_url) &&
                Storage::disk('public')->exists($item->image_url)
            ) {
                Storage::disk('public')->delete($item->image_url);
            }

            $item->delete();

            return response()->json([
                'message' => 'Xóa tuyển sinh thành công.',
            ]);
        } catch (Throwable $e) {
            Log::error('Admission destroy error', [
                'admission_id' => $id,
                'message' => $e->getMessage(),
                'line' => $e->getLine(),
                'file' => $e->getFile(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'message' => 'Lỗi khi xóa tuyển sinh.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function majors()
    {
        return Admission::query()
            ->where('is_active', 1)
            ->whereNotNull('major_name')
            ->where('major_name', '!=', '')
            ->select('major_name')
            ->distinct()
            ->orderBy('major_name')
            ->pluck('major_name');
    }
}