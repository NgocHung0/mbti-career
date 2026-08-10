<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\MbtiResult;
use Illuminate\Http\Request;

class MbtiResultController extends Controller
{
    public function store(Request $request)
    {
        if (!$request->user()) {
            return response()->json([
                'message' => 'Unauthorized'
            ], 401);
        }

        $data = $request->validate([
            'mbti_type' => ['required', 'string', 'size:4'],
            'scores.E' => ['required', 'integer', 'min:0'],
            'scores.I' => ['required', 'integer', 'min:0'],
            'scores.S' => ['required', 'integer', 'min:0'],
            'scores.N' => ['required', 'integer', 'min:0'],
            'scores.T' => ['required', 'integer', 'min:0'],
            'scores.F' => ['required', 'integer', 'min:0'],
            'scores.J' => ['required', 'integer', 'min:0'],
            'scores.P' => ['required', 'integer', 'min:0'],
            'upgrades' => ['nullable', 'array'],
            'answers' => ['nullable', 'array'],
        ]);

        $result = MbtiResult::create([
            'user_id' => $request->user()->id,
            'mbti_type' => $data['mbti_type'],
            'score_e' => $data['scores']['E'],
            'score_i' => $data['scores']['I'],
            'score_s' => $data['scores']['S'],
            'score_n' => $data['scores']['N'],
            'score_t' => $data['scores']['T'],
            'score_f' => $data['scores']['F'],
            'score_j' => $data['scores']['J'],
            'score_p' => $data['scores']['P'],
        ]);

        return response()->json([
            'message' => 'MBTI result saved successfully.',
            'data' => $result,
        ], 201);
    }

    public function latest(Request $request)
    {
        if (!$request->user()) {
            return response()->json([
                'message' => 'Unauthorized'
            ], 401);
        }

        $result = MbtiResult::where('user_id', $request->user()->id)
            ->latest()
            ->first();

        return response()->json($result);
    }

    public function history(Request $request)
    {
        if (!$request->user()) {
            return response()->json([
                'message' => 'Unauthorized'
            ], 401);
        }

        $items = MbtiResult::where('user_id', $request->user()->id)
            ->latest()
            ->take(5)
            ->get();

        return response()->json($items);
    }
}