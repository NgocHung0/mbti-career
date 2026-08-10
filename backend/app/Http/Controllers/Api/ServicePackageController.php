<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ServicePackage;

class ServicePackageController extends Controller
{
    public function index()
    {
        $packages = ServicePackage::query()
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->orderBy('id')
            ->get();

        return response()->json([
            'packages' => $packages
        ]);
    }
}