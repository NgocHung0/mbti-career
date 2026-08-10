<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\MbtiPaymentOrder;
use App\Models\TestPackage;
use App\Models\UserPackage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;

class MbtiPaymentController extends Controller
{
    private const PAYOS_BASE_URL = 'https://api-merchant.payos.vn';

    public function createLink(Request $request)
    {
        $data = $request->validate([
            'package_id' => ['required', 'integer', 'exists:service_packages,id'],
        ]);

        $user = $request->user();

        if (!$user) {
            return response()->json([
                'message' => 'Bạn cần đăng nhập để thanh toán gói.',
            ], 401);
        }

        $package = TestPackage::query()
            ->where('id', $data['package_id'])
            ->where('is_active', true)
            ->firstOrFail();

        $orderCode = $this->makeOrderCode();
        $amount = (int) round((float) $package->price);
        $description = $this->makeDescription($package->id);
        $cancelUrl = config('services.payos.cancel_url');
        $returnUrl = config('services.payos.return_url');

        if (!$cancelUrl || !$returnUrl) {
            return response()->json([
                'message' => 'Thiếu PAYOS_RETURN_URL hoặc PAYOS_CANCEL_URL trong file .env.',
            ], 500);
        }

        $payload = [
            'orderCode' => $orderCode,
            'amount' => $amount,
            'description' => $description,
            'buyerName' => $user->name,
            'buyerEmail' => $user->email,
            'items' => [
                [
                    'name' => $package->name,
                    'quantity' => 1,
                    'price' => $amount,
                ],
            ],
            'cancelUrl' => $cancelUrl,
            'returnUrl' => $returnUrl,
            'expiredAt' => now()->addMinutes(30)->timestamp,
        ];

        $payload['signature'] = $this->signCreatePaymentPayload($payload);

        $response = Http::withHeaders($this->payosHeaders())
            ->asJson()
            ->post(self::PAYOS_BASE_URL . '/v2/payment-requests', $payload);

        if ($response->failed()) {
            return response()->json([
                'message' => 'Không tạo được link thanh toán từ PayOS.',
                'payos' => $response->json(),
            ], $response->status() ?: 500);
        }

        $json = $response->json();
        $payosData = $json['data'] ?? null;

        if (!$payosData || empty($payosData['orderCode'])) {
            return response()->json([
                'message' => 'PayOS trả dữ liệu không hợp lệ.',
                'payos' => $json,
            ], 500);
        }

        $checkoutUrl = $payosData['checkoutUrl'] ?? null;
        $qrCode = $payosData['qrCode'] ?? null;

        if (!$qrCode && $checkoutUrl) {
            $qrCode = $checkoutUrl;
        }

        if (!$checkoutUrl && $qrCode) {
            $checkoutUrl = $qrCode;
        }

        $order = MbtiPaymentOrder::query()->create([
            'user_id' => $user->id,
            'package_id' => $package->id,
            'order_code' => (int) $payosData['orderCode'],
            'payment_link_id' => $payosData['paymentLinkId'] ?? null,
            'amount' => $amount,
            'status' => strtoupper((string) ($payosData['status'] ?? 'PENDING')),
            'checkout_url' => $checkoutUrl,
            'qr_code' => $qrCode,
            'provider_raw' => $json,
        ]);

        return response()->json([
            'message' => 'Tạo link thanh toán thành công.',
            'order_id' => $order->id,
            'order_code' => (int) $order->order_code,
            'payment_link_id' => $order->payment_link_id,
            'amount' => (int) $order->amount,
            'status' => $order->status,
            'checkout_url' => (string) ($order->checkout_url ?? ''),
            'qr_code' => (string) ($order->qr_code ?? ''),
        ]);
    }

    public function status(Request $request, int $orderCode)
    {
        $user = $request->user();

        if (!$user) {
            return response()->json([
                'message' => 'Bạn cần đăng nhập để kiểm tra thanh toán.',
            ], 401);
        }

        $order = MbtiPaymentOrder::query()
            ->with('package')
            ->where('user_id', $user->id)
            ->where('order_code', $orderCode)
            ->firstOrFail();

        if ($order->status !== 'PAID') {
            $response = Http::withHeaders($this->payosHeaders())
                ->acceptJson()
                ->get(self::PAYOS_BASE_URL . '/v2/payment-requests/' . $order->order_code);

            if ($response->ok()) {
                $json = $response->json();
                $payosData = $json['data'] ?? [];
                $remoteStatus = strtoupper((string) ($payosData['status'] ?? $order->status));

                $order->update([
                    'status' => $remoteStatus,
                    'provider_raw' => $json,
                ]);

                if ($remoteStatus === 'PAID') {
                    $this->markOrderPaidAndAssignPackage($order, $json);
                    $order->refresh()->load('package');
                } else {
                    $order->refresh();
                }
            }
        }

        return response()->json([
            'success' => true,
            'order_id' => $order->id,
            'order_code' => (int) $order->order_code,
            'package_id' => (int) $order->package_id,
            'status' => $order->status,
            'is_paid' => $order->status === 'PAID',
            'paid_at' => $order->paid_at,
            'package' => $order->status === 'PAID' ? $order->package : null,
        ]);
    }

    public function webhook(Request $request)
    {
        $payload = $request->all();
        $data = $payload['data'] ?? [];
        $signature = (string) ($payload['signature'] ?? '');

        if (!$this->isValidWebhookSignature($data, $signature)) {
            return response()->json([
                'message' => 'Invalid signature.',
            ], 400);
        }

        $orderCode = (int) ($data['orderCode'] ?? 0);
        if (!$orderCode) {
            return response()->json(['message' => 'OK']);
        }

        $order = MbtiPaymentOrder::query()->where('order_code', $orderCode)->first();
        if (!$order) {
            return response()->json(['message' => 'OK']);
        }

        $code = (string) ($data['code'] ?? '');
        $desc = Str::lower((string) ($data['desc'] ?? ''));
        $isPaid = $code === '00' && str_contains($desc, 'thành công');

        if ($isPaid) {
            $this->markOrderPaidAndAssignPackage($order, $payload);
        } else {
            $order->update([
                'status' => 'PENDING',
                'provider_raw' => $payload,
            ]);
        }

        return response()->json(['message' => 'OK']);
    }

    private function markOrderPaidAndAssignPackage(MbtiPaymentOrder $order, array $raw = []): void
    {
        DB::transaction(function () use ($order, $raw) {
            $order->refresh();

            if ($order->status !== 'PAID') {
                $order->update([
                    'status' => 'PAID',
                    'paid_at' => $order->paid_at ?: now(),
                    'provider_raw' => $raw ?: $order->provider_raw,
                ]);
            }

            UserPackage::query()
                ->where('user_id', $order->user_id)
                ->where('status', 'active')
                ->update([
                    'status' => 'inactive',
                    'updated_at' => now(),
                ]);

            UserPackage::query()->updateOrCreate(
                [
                    'user_id' => $order->user_id,
                    'package_id' => $order->package_id,
                ],
                [
                    'status' => 'active',
                    'started_at' => now(),
                    'expires_at' => null,
                ]
            );
        });
    }

    private function signCreatePaymentPayload(array $payload): string
    {
        $signData = [
            'amount' => $payload['amount'] ?? '',
            'cancelUrl' => $payload['cancelUrl'] ?? '',
            'description' => $payload['description'] ?? '',
            'orderCode' => $payload['orderCode'] ?? '',
            'returnUrl' => $payload['returnUrl'] ?? '',
        ];

        ksort($signData);

        $dataString = collect($signData)
            ->map(fn ($value, $key) => $key . '=' . $value)
            ->implode('&');

        return hash_hmac('sha256', $dataString, (string) config('services.payos.checksum_key'));
    }

    private function isValidWebhookSignature(array $data, string $signature): bool
    {
        if (!$signature) {
            return false;
        }

        ksort($data);
        $pairs = [];

        foreach ($data as $key => $value) {
            if ($value === null || $value === 'null' || $value === 'undefined') {
                $value = '';
            }

            if (is_array($value)) {
                $value = json_encode($this->sortArrayObjects($value), JSON_UNESCAPED_UNICODE);
            }

            $pairs[] = $key . '=' . $value;
        }

        $dataString = implode('&', $pairs);
        $computed = hash_hmac('sha256', $dataString, (string) config('services.payos.checksum_key'));

        return hash_equals(strtolower($computed), strtolower($signature));
    }

    private function sortArrayObjects(array $items): array
    {
        return array_map(function ($item) {
            if (is_array($item)) {
                ksort($item);
            }
            return $item;
        }, $items);
    }

    private function payosHeaders(): array
    {
        return [
            'x-client-id' => (string) config('services.payos.client_id'),
            'x-api-key' => (string) config('services.payos.api_key'),
            'Accept' => 'application/json',
        ];
    }

    private function makeOrderCode(): int
    {
        return (int) now()->format('ymdHis') . random_int(10, 99);
    }

    private function makeDescription(int $packageId): string
    {
        return 'NAVI' . $packageId . now()->format('Hi');
    }
}