<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\TestPackage;
use App\Models\TestHistory;
use App\Models\UserServicePackage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class UserPortalController extends Controller
{
    public function packages(Request $request)
    {
        $user = $request->user();

        $packages = TestPackage::query()
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->orderBy('id')
            ->get();

        $currentPackageMeta = UserServicePackage::query()
            ->with('package')
            ->where('user_id', $user->id)
            ->where('status', 'active')
            ->latest('id')
            ->first();

        return response()->json([
            'user' => $user,
            'packages' => $packages,
            'current_package' => $currentPackageMeta?->package,
            'current_package_meta' => $currentPackageMeta,
        ]);
    }

    public function assignPackage(Request $request)
    {
        $data = $request->validate([
            'package_id' => ['required', 'integer', 'exists:service_packages,id'],
        ]);

        $user = $request->user();

        $package = TestPackage::query()
            ->where('id', $data['package_id'])
            ->where('is_active', true)
            ->firstOrFail();

        $record = DB::transaction(function () use ($user, $package) {
            UserServicePackage::query()
                ->where('user_id', $user->id)
                ->where('status', 'active')
                ->update([
                    'status' => 'inactive',
                    'updated_at' => now(),
                ]);

            return UserServicePackage::query()->updateOrCreate(
                [
                    'user_id' => $user->id,
                    'package_id' => $package->id,
                ],
                [
                    'status' => 'active',
                    'started_at' => now(),
                    'expires_at' => null,
                ]
            );
        });

        return response()->json([
            'message' => 'Gán gói test thành công.',
            'record' => $record->load('package'),
        ]);
    }

    public function storeHistory(Request $request)
    {
        $user = $request->user();

        $data = $request->validate([
            'test_session_id' => ['nullable', 'string', 'max:255'],
            'test_type' => ['required', 'string', 'max:50'],
            'result_code' => ['nullable', 'string', 'max:100'],
            'answers' => ['nullable', 'array'],
            'questions' => ['nullable', 'array'],
            'scores' => ['nullable', 'array'],
            'result_payload' => ['nullable', 'array'],
            'package_id' => ['nullable', 'integer'],
            'package_name' => ['nullable', 'string', 'max:255'],
        ]);

        $payload = $data['result_payload'] ?? [];

        $snapshotPackageName =
            $data['package_name']
            ?? data_get($payload, 'package_name')
            ?? data_get($payload, 'package')
            ?? data_get($payload, 'level')
            ?? 'free';

        $snapshotPackageName = strtolower(trim($snapshotPackageName));

        if (str_contains($snapshotPackageName, 'premium')) {
            $snapshotPackageName = 'premium';
        } elseif (str_contains($snapshotPackageName, 'plus')) {
            $snapshotPackageName = 'plus';
        } else {
            $snapshotPackageName = 'free';
        }

        $payload['package_name'] = $snapshotPackageName;

        $sessionId = $data['test_session_id'] ?? null;

        if ($sessionId) {
            $history = TestHistory::query()
                ->where('user_id', $user->id)
                ->where('test_session_id', $sessionId)
                ->first();

            if ($history) {
                $history->update([
                    'test_type' => $data['test_type'],
                    'result_code' => $data['result_code'] ?? $history->result_code,
                    'answers' => $data['answers'] ?? [],
                    'questions' => $data['questions'] ?? [],
                    'scores' => $data['scores'] ?? [],
                    'result_payload' => $payload,
                    'package_id' => $data['package_id'] ?? $history->package_id,
                    'package_name' => $snapshotPackageName,
                ]);

                return response()->json([
                    'message' => 'Updated history',
                    'history' => $history->fresh(),
                ]);
            }
        }

        $history = TestHistory::query()->create([
            'user_id' => $user->id,
            'test_session_id' => $sessionId,
            'test_type' => $data['test_type'],
            'result_code' => $data['result_code'] ?? null,
            'answers' => $data['answers'] ?? [],
            'questions' => $data['questions'] ?? [],
            'scores' => $data['scores'] ?? [],
            'result_payload' => $payload,
            'package_id' => $data['package_id'] ?? null,
            'package_name' => $snapshotPackageName,
        ]);

        return response()->json([
            'message' => 'Created history',
            'history' => $history,
        ], 201);
    }

    public function histories(Request $request)
    {
        $user = $request->user();

        $items = TestHistory::query()
            ->where('user_id', $user->id)
            ->latest('id')
            ->get([
                'id',
                'test_session_id',
                'test_type',
                'result_code',
                'package_id',
                'package_name',
                'scores',
                'result_payload',
                'created_at',
            ]);

        return response()->json([
            'histories' => $items,
        ]);
    }

    public function historyDetail(Request $request, int $id)
    {
        $user = $request->user();

        $history = TestHistory::query()
            ->where('user_id', $user->id)
            ->findOrFail($id);

        return response()->json([
            'history' => $history,
        ]);
    }
}