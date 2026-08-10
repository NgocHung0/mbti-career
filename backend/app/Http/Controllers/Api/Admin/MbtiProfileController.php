<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\MbtiProfile;
use Illuminate\Http\Request;

class MbtiProfileController extends Controller
{
    public function index()
    {
        return response()->json(
            MbtiProfile::query()->orderBy('code')->get()
        );
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'code' => ['required', 'string', 'size:4', 'unique:mbti_profiles,code'],
            'name' => ['required', 'string', 'max:255'],
            'description' => ['required', 'string'],
        ]);

        $data['code'] = strtoupper(trim($data['code']));

        $item = MbtiProfile::create($data);

        return response()->json($item, 201);
    }

    public function update(Request $request, int $id)
    {
        $item = MbtiProfile::query()->findOrFail($id);

        $data = $request->validate([
            'code' => ['required', 'string', 'size:4', 'unique:mbti_profiles,code,' . $id],
            'name' => ['required', 'string', 'max:255'],
            'description' => ['required', 'string'],
        ]);

        $data['code'] = strtoupper(trim($data['code']));

        $item->update($data);

        return response()->json($item);
    }

    public function destroy(int $id)
    {
        $item = MbtiProfile::query()->findOrFail($id);
        $item->delete();

        return response()->json([
            'message' => 'Deleted successfully'
        ]);
    }
    public function showByCode(string $code)
    {
        $item = MbtiProfile::query()
            ->where('code', strtoupper(trim($code)))
            ->first();

        if (!$item) {
            return response()->json([
                'message' => 'Không tìm thấy hồ sơ MBTI.'
            ], 404);
        }

        return response()->json($item);
    }
}