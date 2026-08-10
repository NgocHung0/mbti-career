<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;
use Illuminate\Support\Facades\Storage;
use App\Models\UserServicePackage;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Carbon;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $data = $request->validate(
            [
                'name' => ['required', 'string', 'max:255'],
                'email' => [
                    'required',
                    'string',
                    'max:255',
                    'regex:/^[A-Za-z0-9._%+-]+@gmail\.com$/',
                    'unique:users,email',
                ],
                'password' => [
                    'required',
                    'string',
                    'confirmed',
                    Password::min(8)
                        ->mixedCase()
                        ->numbers()
                        ->symbols(),
                ],
            ],
            [
                'name.required' => 'Vui lòng nhập họ tên.',
                'email.required' => 'Vui lòng nhập email.',
                'email.regex' => 'Email phải có đuôi @gmail.com.',
                'email.unique' => 'Email đã tồn tại.',
                'password.required' => 'Vui lòng nhập mật khẩu.',
                'password.confirmed' => 'Mật khẩu xác nhận không khớp.',
            ]
        );

        $user = User::create([
            'name' => trim($data['name']),
            'email' => strtolower(trim($data['email'])),
            'password' => Hash::make($data['password']),
            'role' => 'user',
            'status' => 'active',
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Đăng ký thành công.',
            'token' => $token,
            'user' => $user,
        ], 201);
    }

    public function login(Request $request)
    {
        $data = $request->validate(
            [
                'email' => ['required', 'email'],
                'password' => ['required', 'string'],
            ],
            [
                'email.required' => 'Vui lòng nhập email.',
                'password.required' => 'Vui lòng nhập mật khẩu.',
            ]
        );

        $user = User::where('email', trim($data['email']))->first();

        if (!$user) {
            return response()->json([
                'message' => 'Email hoặc mật khẩu không đúng.',
                'errors' => [
                    'email' => ['Email hoặc mật khẩu không đúng.']
                ]
            ], 401);
        }

        if (($user->status ?? 'active') === 'inactive') {
            return response()->json([
                'message' => 'Tài khoản hiện tại đang bị khóa.',
                'errors' => [
                    'email' => ['Tài khoản hiện tại đang bị khóa.']
                ]
            ], 403);
        }

        if (!Hash::check($data['password'], $user->password)) {
            return response()->json([
                'message' => 'Email hoặc mật khẩu không đúng.',
                'errors' => [
                    'email' => ['Email hoặc mật khẩu không đúng.']
                ]
            ], 401);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        $currentPackage = UserServicePackage::with('package')
            ->where('user_id',$user->id)
            ->where('status','active')
            ->latest('id')
            ->first();

        return response()->json([
            'message' => 'Đăng nhập thành công.',
            'token' => $token,
            'user' => $user,
            'package' => $currentPackage?->package
        ]);
    }

    public function me(Request $request)
    {
        $user = $request->user();

        $currentPackage = UserServicePackage::with('package')
            ->where('user_id', $user->id)
            ->where('status', 'active')
            ->latest('id')
            ->first();

        return response()->json([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'status' => $user->status,
                'avatar' => $user->avatar,
                'avatar_url' => $user->avatar
                    ? asset('storage/' . $user->avatar)
                    : null,
            ],
            'package' => $currentPackage?->package,
            'package_meta' => $currentPackage,
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()?->currentAccessToken()?->delete();

        return response()->json([
            'message' => 'Đăng xuất thành công.',
        ]);
    }

    public function changePassword(Request $request)
    {
        $data = $request->validate(
            [
                'current_password' => ['required', 'string'],
                'new_password' => [
                    'required',
                    'string',
                    'confirmed',
                    Password::min(8)
                        ->mixedCase()
                        ->numbers()
                        ->symbols(),
                ],
            ],
            [
                'current_password.required' => 'Vui lòng nhập mật khẩu hiện tại.',
                'new_password.required' => 'Vui lòng nhập mật khẩu mới.',
                'new_password.confirmed' => 'Mật khẩu xác nhận không khớp.',
            ]
        );

        $user = $request->user();

        if (!$user || !Hash::check($data['current_password'], $user->password)) {
            return response()->json([
                'message' => 'Mật khẩu hiện tại không đúng.',
                'errors' => [
                    'current_password' => ['Mật khẩu hiện tại không đúng.']
                ]
            ], 422);
        }

        $user->password = Hash::make($data['new_password']);
        $user->save();

        return response()->json([
            'message' => 'Đổi mật khẩu thành công.',
        ]);
    }

    public function updateProfile(Request $request)
    {
        $request->validate([
            'name' => ['required', 'string', 'max:255'],
        ]);

        $user = $request->user();

        $user->update([
            'name' => $request->name,
        ]);

        return response()->json([
            'message' => 'Cập nhật hồ sơ thành công.',
            'user' => $user->fresh(),
        ]);
    }

    public function requestChangePasswordOtp(Request $request)
    {
        $data = $request->validate([
            'current_password' => ['required', 'string'],
            'new_password' => [
                'required',
                'string',
                'confirmed',
                Password::min(8)->mixedCase()->numbers()->symbols(),
            ],
        ]);

        $user = $request->user();

        if (!Hash::check($data['current_password'], $user->password)) {
            return response()->json([
                'message' => 'Mật khẩu hiện tại không đúng.',
            ], 422);
        }

        $otp = (string) random_int(100000, 999999);

        DB::table('password_change_otps')
            ->where('user_id', $user->id)
            ->delete();

        DB::table('password_change_otps')->insert([
            'user_id' => $user->id,
            'otp_hash' => Hash::make($otp),
            'new_password_hash' => Hash::make($data['new_password']),
            'expires_at' => Carbon::now()->addMinutes(5),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        Mail::send('emails.password_otp', [
            'otp' => $otp,
        ], function ($message) use ($user) {
            $message->to($user->email)
                ->subject('Mã OTP đổi mật khẩu NAVI');
        });
    }

    public function verifyChangePasswordOtp(Request $request)
    {
        $data = $request->validate([
            'otp' => ['required', 'string', 'size:6'],
        ]);

        $user = $request->user();

        $record = DB::table('password_change_otps')
            ->where('user_id', $user->id)
            ->latest('id')
            ->first();

        if (!$record) {
            return response()->json([
                'message' => 'Bạn chưa yêu cầu mã OTP.',
            ], 422);
        }

        if (Carbon::parse($record->expires_at)->isPast()) {
            DB::table('password_change_otps')->where('id', $record->id)->delete();

            return response()->json([
                'message' => 'Mã OTP đã hết hạn.',
            ], 422);
        }

        if (!Hash::check($data['otp'], $record->otp_hash)) {
            return response()->json([
                'message' => 'Mã OTP không đúng.',
            ], 422);
        }

        $user->password = $record->new_password_hash;
        $user->save();

        DB::table('password_change_otps')
            ->where('user_id', $user->id)
            ->delete();

        return response()->json([
            'message' => 'Đổi mật khẩu thành công.',
        ]);
    }
    public function updateAvatar(Request $request)
    {
        $user = $request->user();

        $request->validate([
            'avatar' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:2048'],
        ]);

        $file = $request->file('avatar');

        if ($user->avatar) {
    Storage::disk('public')->delete($user->avatar);
    }

    $path = $request->file('avatar')->store('avatars', 'public');

    $user->avatar = $path;
    $user->save();

    return response()->json([
        'message' => 'Cập nhật ảnh đại diện thành công.',
        'user' => $user,
        'avatar_url' => asset('storage/' . $path),
    ]);
    }

    public function requestForgotPasswordOtp(Request $request)
{
    $data = $request->validate([
        'email' => ['required', 'email', 'exists:users,email'],
    ]);

    $user = User::where('email', $data['email'])->first();

    $otp = (string) random_int(100000, 999999);

    DB::table('password_change_otps')
        ->where('user_id', $user->id)
        ->delete();

    DB::table('password_change_otps')->insert([
        'user_id' => $user->id,
        'otp_hash' => Hash::make($otp),
        'new_password_hash' => null,
        'expires_at' => now()->addMinutes(5),
        'created_at' => now(),
        'updated_at' => now(),
    ]);

    Mail::send('emails.password_otp', [
        'otp' => $otp,
    ], function ($message) use ($user) {
        $message->to($user->email)
            ->subject('Mã OTP khôi phục mật khẩu NAVI');
    });

    return response()->json([
        'message' => 'Mã OTP đã được gửi về email của bạn.',
    ]);
}

public function resetForgotPassword(Request $request)
{
    $data = $request->validate([
        'email' => ['required', 'email', 'exists:users,email'],
        'otp' => ['required', 'string', 'size:6'],
        'password' => ['required', 'string', 'min:6', 'confirmed'],
    ]);

    $user = User::where('email', $data['email'])->first();

    $record = DB::table('password_change_otps')
        ->where('user_id', $user->id)
        ->latest('id')
        ->first();

    if (!$record) {
        return response()->json(['message' => 'Bạn chưa yêu cầu mã OTP.'], 422);
    }

    if (now()->greaterThan($record->expires_at)) {
        DB::table('password_change_otps')->where('id', $record->id)->delete();
        return response()->json(['message' => 'Mã OTP đã hết hạn.'], 422);
    }

    if (!Hash::check($data['otp'], $record->otp_hash)) {
        return response()->json(['message' => 'Mã OTP không đúng.'], 422);
    }

    $user->password = Hash::make($data['password']);
    $user->save();

    DB::table('password_change_otps')->where('user_id', $user->id)->delete();

    return response()->json([
        'message' => 'Đặt lại mật khẩu thành công.',
    ]);
}
}