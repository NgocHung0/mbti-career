<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class AdminUserController extends Controller
{
    public function index(Request $request)
    {
        $perPage = max(
            1,
            min((int) $request->get('per_page', 10), 100)
        );

        $keyword = trim(
            (string) $request->get('q', '')
        );

        $status = trim(
            (string) $request->get('status', 'all')
        );

        $role = trim(
            (string) $request->get('role', 'all')
        );

        /*
        * Thống kê toàn bộ người dùng.
        * Không bị thay đổi khi tìm kiếm hoặc lọc.
        */
        $statsQuery = User::query()
            ->where('role', '!=', 'admin');

        $totalUsers = (clone $statsQuery)->count();

        $activeTotal = (clone $statsQuery)
            ->where('status', 'active')
            ->count();

        /*
        * Query dùng để tìm kiếm và phân trang.
        */
        $query = User::query()
            ->where('role', '!=', 'admin');

        /*
        * Tìm trên toàn bộ database trước khi paginate.
        */
        if ($keyword !== '') {
            $query->where(function ($subQuery) use ($keyword) {
                $subQuery
                    ->where('name', 'like', '%' . $keyword . '%')
                    ->orWhere('email', 'like', '%' . $keyword . '%')
                    ->orWhere('role', 'like', '%' . $keyword . '%');
            });
        }

        /*
        * Lọc trạng thái.
        */
        if (in_array($status, ['active', 'inactive'], true)) {
            $query->where('status', $status);
        }

        /*
        * Lọc gói tài khoản nếu frontend có truyền role.
        */
        if (
            $role !== 'all' &&
            in_array($role, ['user', 'plus', 'premium'], true)
        ) {
            $query->where('role', $role);
        }

        /*
        * Sau khi tìm và lọc xong mới phân trang.
        */
        $users = $query
            ->select([
                'id',
                'name',
                'email',
                'role',
                'status',
                'created_at',
            ])
            ->orderBy('id', 'asc')
            ->paginate($perPage)
            ->appends($request->query());

        $users->getCollection()->transform(function ($user) {
            return [
                'id' => (int) $user->id,
                'name' => (string) $user->name,
                'email' => (string) $user->email,
                'role' => $user->role ?? 'user',
                'status' => $user->status ?? 'active',
                'joined_at' => optional($user->created_at)
                    ?->format('Y-m-d'),
            ];
        });

        return response()->json([
            'data' => $users->items(),

            'current_page' => $users->currentPage(),
            'last_page' => $users->lastPage(),
            'per_page' => $users->perPage(),

            // Tổng kết quả sau khi tìm kiếm.
            'filtered_total' => $users->total(),

            // Thống kê toàn hệ thống.
            'total' => $totalUsers,
            'active_total' => $activeTotal,
        ]);
    }
    
    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', 'min:6'],
            'role' => ['required', 'string', 'max:50'],
            'status' => ['required', Rule::in(['active', 'inactive'])],
        ]);

        $user = User::create([
            'name' => trim($data['name']),
            'email' => trim($data['email']),
            'password' => Hash::make($data['password']),
            'role' => $data['role'],
            'status' => $data['status'],
        ]);

        return response()->json([
            'message' => 'Tạo người dùng thành công.',
            'data' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role ?? 'user',
                'status' => $user->status ?? 'active',
                'joined_at' => optional($user->created_at)?->format('Y-m-d'),
            ]
        ], 201);
    }

    public function update(Request $request, User $user)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => [
                'required',
                'email',
                'max:255',
                Rule::unique('users', 'email')->ignore($user->id),
            ],
            'role' => ['required', 'string', 'max:50'],
            'status' => ['required', Rule::in(['active', 'inactive'])],
        ]);

        $user->update([
            'name' => trim($data['name']),
            'email' => trim($data['email']),
            'role' => $data['role'],
            'status' => $data['status'],
        ]);

        return response()->json([
            'message' => 'Cập nhật người dùng thành công.',
            'data' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role ?? 'user',
                'status' => $user->status ?? 'active',
                'joined_at' => optional($user->created_at)?->format('Y-m-d'),
            ]
        ]);
    }

    public function destroy(User $user)
    {
        $user->delete();

        return response()->json([
            'message' => 'Xóa người dùng thành công.'
        ]);
    }
}