<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use App\Models\CoursePayment;

class CoursePaymentController extends Controller
{
    public function confirm(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'course_id' => ['required', 'integer'],
        ]);

        $payment = CoursePayment::create([
            'user_id' => $request->user()->id,
            'course_id' => $validated['course_id'],
            'amount' => 0,
            'status' => 'paid',
            'payment_method' => 'manual_qr',
        ]);

        return response()->json([
            'message' => 'Đã lưu thanh toán vào database.',
            'payment' => $payment,
        ]);
    }
}