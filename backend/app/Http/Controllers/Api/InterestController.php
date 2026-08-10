<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\DB;

class InterestController extends Controller
{
    public function tags()
    {
        return response()->json([
            'data' => DB::table('interest_tags')
                ->select('id', 'name', 'slug')
                ->orderBy('id')
                ->get(),
        ]);
    }
}