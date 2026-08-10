<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Question;

class QuestionController extends Controller
{
    public function index()
    {
        return response()->json([
            'data' => Question::query()
                ->where('is_active', true)
                ->orderBy('code')
                ->get(['id','code','axis','content','a_label','b_label'])
        ]);
    }
}