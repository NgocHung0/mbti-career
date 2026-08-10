<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AbilityResult;
use Illuminate\Http\Request;

class AbilityResultController extends Controller
{
    public function store(Request $request)
    {
        $data = $request->validate([
            'answers' => ['required', 'array'],
            'scores' => ['required', 'array'],
        ]);

        $result = AbilityResult::create([
            'user_id' => $request->user()->id,
            'answers' => $data['answers'],
            'scores' => $data['scores'],
        ]);

        return response()->json([
            'message' => 'Ability result saved successfully.',
            'data' => $result,
        ], 201);
    }

    public function latest(Request $request)
    {
        $result = AbilityResult::where('user_id', $request->user()->id)
            ->latest()
            ->first();

        return response()->json($result);
    }
}