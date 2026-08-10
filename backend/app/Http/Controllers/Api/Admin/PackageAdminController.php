<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\TestPackage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class PackageAdminController extends Controller
{
    public function index()
    {
        $packages = TestPackage::query()
            ->where(function ($query) {
                $query->whereNull('category')
                    ->orWhere('category', '!=', 'course');
            })
            ->orderBy('sort_order')
            ->orderBy('id')
            ->get();

        return response()->json([
            'packages' => $packages,
        ]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'slug' => ['nullable', 'string', 'max:255', 'unique:service_packages,slug'],
            'price' => ['required', 'numeric', 'min:0'],
            'short_description' => ['nullable', 'string'],
            'description' => ['nullable', 'string'],
            'badge_text' => ['nullable', 'string', 'max:255'],
            'theme' => ['nullable', 'string', 'max:50'],
            'sort_order' => ['nullable', 'integer', 'min:1'],
            'is_active' => ['nullable', 'boolean'],
            'is_featured' => ['nullable', 'boolean'],
            'include_interest_test' => ['nullable', 'boolean'],
            'include_ability_test' => ['nullable', 'boolean'],
        ]);

        $data['slug'] = $this->resolveSlug($data['slug'] ?? null, $data['name']);
        $data['category'] = 'test';
        $data['theme'] = $data['theme'] ?? 'blue';
        $data['sort_order'] = $data['sort_order'] ?? $this->nextSortOrder();
        $data['is_active'] = $data['is_active'] ?? true;
        $data['is_featured'] = $data['is_featured'] ?? false;
        $data['include_interest_test'] = (bool) ($data['include_interest_test'] ?? true);
        $data['include_ability_test'] = (bool) ($data['include_ability_test'] ?? false);

        $package = DB::transaction(function () use ($data) {
            return TestPackage::create($data);
        });

        return response()->json([
            'message' => 'Tạo gói thành công',
            'package' => $package,
        ], 201);
    }

    public function update(Request $request, $id)
    {
        $package = TestPackage::query()
            ->where(function ($query) {
                $query->whereNull('category')
                    ->orWhere('category', '!=', 'course');
            })
            ->findOrFail($id);

        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'slug' => [
                'nullable',
                'string',
                'max:255',
                Rule::unique('service_packages', 'slug')->ignore($package->id),
            ],
            'price' => ['required', 'numeric', 'min:0'],
            'short_description' => ['nullable', 'string'],
            'description' => ['nullable', 'string'],
            'badge_text' => ['nullable', 'string', 'max:255'],
            'theme' => ['nullable', 'string', 'max:50'],
            'sort_order' => ['nullable', 'integer', 'min:1'],
            'is_active' => ['nullable', 'boolean'],
            'is_featured' => ['nullable', 'boolean'],
            'include_interest_test' => ['nullable', 'boolean'],
            'include_ability_test' => ['nullable', 'boolean'],
        ]);

        $data['slug'] = $this->resolveSlug($data['slug'] ?? null, $data['name'], $package->id);
        $data['category'] = $package->category && $package->category !== 'course'
            ? $package->category
            : 'test';
        $data['theme'] = $data['theme'] ?? ($package->theme ?: 'blue');
        $data['sort_order'] = $data['sort_order'] ?? $package->sort_order;
        $data['is_active'] = $data['is_active'] ?? $package->is_active;
        $data['is_featured'] = $data['is_featured'] ?? $package->is_featured;
        $data['include_interest_test'] = (bool) ($data['include_interest_test'] ?? $package->include_interest_test);
        $data['include_ability_test'] = (bool) ($data['include_ability_test'] ?? $package->include_ability_test);

        $package = DB::transaction(function () use ($package, $data) {
            $package->update($data);
            return $package->fresh();
        });

        return response()->json([
            'message' => 'Cập nhật gói thành công',
            'package' => $package,
        ]);
    }

    public function destroy($id)
    {
        $package = TestPackage::query()
            ->where(function ($query) {
                $query->whereNull('category')
                    ->orWhere('category', '!=', 'course');
            })
            ->findOrFail($id);

        $package->delete();

        return response()->json([
            'message' => 'Xóa gói thành công',
        ]);
    }

    private function resolveSlug(?string $slug, string $name, ?int $ignoreId = null): string
    {
        $base = Str::slug($slug ?: $name);

        if (!$base) {
            $base = 'service-package';
        }

        $finalSlug = $base;
        $counter = 1;

        while (
            TestPackage::query()
                ->where('slug', $finalSlug)
                ->when($ignoreId, fn ($q) => $q->where('id', '!=', $ignoreId))
                ->exists()
        ) {
            $finalSlug = $base . '-' . $counter;
            $counter++;
        }

        return $finalSlug;
    }

    private function nextSortOrder(): int
    {
        return ((int) TestPackage::query()
            ->where(function ($query) {
                $query->whereNull('category')
                    ->orWhere('category', '!=', 'course');
            })
            ->max('sort_order')) + 1;
    }
}