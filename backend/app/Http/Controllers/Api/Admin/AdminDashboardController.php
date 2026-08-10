<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class AdminDashboardController extends Controller
{
    public function index(): JsonResponse
    {
        $totalUsers = $this->safeCountTable('users');
        $totalTests = $this->safeCountTable('test_histories');
        $totalMajors = $this->safeCountTable('majors');
        $totalAdmissions = $this->safeCountTable('admissions');
        $totalCourses = $this->safeCountTable('service_packages');

        $todayRevenue = $this->sumPaidRevenueToday();
        $monthRevenue = $this->sumPaidRevenueThisMonth();
        $totalRevenue = $this->sumPaidRevenueTotal();

        $revenueChartDay = $this->buildRevenueChartDay();
        $revenueChartWeek = $this->buildRevenueChartWeek();
        $revenueChartMonth = $this->buildRevenueChartMonth();
        $revenueChartYear = $this->buildRevenueChartYear();

        $mbtiDistribution = $this->buildMbtiDistribution();

        $newUsers7Days = $this->safeCountWhereDate('users', 'created_at', now()->subDays(7));
        $newTests7Days = $this->safeCountWhereDate('test_histories', 'created_at', now()->subDays(7));

        $recentUsers = $this->getRecentUsers(20);
        $recentActivities = $this->buildRecentActivities();

        $usersWithTests = $this->countUsersWithTests();

        $testCompletionRate = $totalUsers > 0
            ? round(($usersWithTests / $totalUsers) * 100)
            : 0;

        $packageDistribution = $this->buildPackageDistribution($totalUsers);

        $totalContentBase = max($totalMajors + $totalAdmissions + $totalCourses, 1);

        return response()->json([
            'stats' => [
                'total_users' => $totalUsers,
                'total_tests' => $totalTests,
                'total_majors' => $totalMajors,
                'total_admissions' => $totalAdmissions,

                'users_with_tests' => $usersWithTests,
                'test_completion_rate' => $testCompletionRate,
                'package_distribution' => $packageDistribution,

                'users_growth_text' => '+' . $newUsers7Days . ' người dùng trong 7 ngày gần đây',
                'tests_growth_text' => '+' . $newTests7Days . ' lượt test trong 7 ngày gần đây',
                'majors_hint_text' => 'Dữ liệu ngành nghề đang hoạt động',
                'admissions_hint_text' => 'Nội dung tuyển sinh hiện có',

                'revenue_chart' => $revenueChartDay,
                'revenue_chart_day' => $revenueChartDay,
                'revenue_chart_week' => $revenueChartWeek,
                'revenue_chart_month' => $revenueChartMonth,
                'revenue_chart_year' => $revenueChartYear,

                'mbti_distribution' => $mbtiDistribution,
            ],

            'revenue' => [
                'today' => $todayRevenue,
                'month' => $monthRevenue,
                'total' => $totalRevenue,
                'today_hint_text' => 'Doanh thu phát sinh hôm nay',
                'month_hint_text' => 'Doanh thu trong tháng hiện tại',
                'total_hint_text' => 'Tổng doanh thu toàn hệ thống',
            ],

            'revenue_chart' => $revenueChartDay,
            'mbti_distribution' => $mbtiDistribution,
            'recent_users' => $recentUsers,
            'recent_activities' => $recentActivities,

            'quick_actions' => [
                [
                    'label' => 'Quản lý người dùng',
                    'route' => '/admin/users',
                    'description' => 'Xem danh sách và trạng thái tài khoản',
                ],
                [
                    'label' => 'Quản lý ngành nghề',
                    'route' => '/admin/majors',
                    'description' => 'Thêm và cập nhật dữ liệu ngành nghề',
                ],
                [
                    'label' => 'Quản lý tuyển sinh',
                    'route' => '/admin/admissions',
                    'description' => 'Theo dõi bài viết tuyển sinh',
                ],
                [
                    'label' => 'Quản lý khóa học',
                    'route' => '/admin/courses',
                    'description' => 'Cập nhật gói học và bài học',
                ],
            ],

            'content_overview' => [
                [
                    'label' => 'Ngành nghề',
                    'value' => $totalMajors,
                    'percent' => (int) round(($totalMajors / $totalContentBase) * 100),
                ],
                [
                    'label' => 'Tuyển sinh',
                    'value' => $totalAdmissions,
                    'percent' => (int) round(($totalAdmissions / $totalContentBase) * 100),
                ],
                [
                    'label' => 'Khóa học',
                    'value' => $totalCourses,
                    'percent' => (int) round(($totalCourses / $totalContentBase) * 100),
                ],
            ],

            'notes' => [
                'Theo dõi doanh thu và lượt làm test để đánh giá hiệu quả hệ thống.',
                'Ưu tiên rà soát nội dung tuyển sinh và dữ liệu ngành nghề mỗi tuần.',
                'Kiểm tra hoạt động người dùng mới để tối ưu trải nghiệm onboarding.',
            ],
        ]);
    }

    private function buildRecentActivities(): array
    {
        $activities = [];

        $activities = array_merge($activities, $this->getLatestRegisteredUserActivities(5));
        $activities = array_merge($activities, $this->getLatestPaidCourseOrderActivities(5));
        $activities = array_merge($activities, $this->getLatestCompletedTestActivities(5));
        $activities = array_merge($activities, $this->getLatestPasswordChangedActivities(5));
        $activities = array_merge($activities, $this->getLatestAdmissionUpdatedActivities(5));

        usort($activities, function (array $a, array $b) {
            return strtotime($b['sort_time']) <=> strtotime($a['sort_time']);
        });

        $activities = array_slice($activities, 0, 5);

        return array_map(function (array $item) {
            unset($item['sort_time']);
            return $item;
        }, $activities);
    }

    private function getLatestRegisteredUserActivities(int $limit = 5): array
    {
        if (!Schema::hasTable('users') || !Schema::hasColumn('users', 'created_at')) {
            return [];
        }

        $users = DB::table('users')
            ->select('name', 'email', 'created_at')
            ->orderByDesc('created_at')
            ->limit($limit)
            ->get();

        return $users->map(function ($user) {
            $userName = $user->name
                ?: ($user->email ? explode('@', $user->email)[0] : 'Một người dùng');

            return [
                'title' => 'Người dùng mới đăng ký',
                'description' => $userName . ' vừa tạo tài khoản trong hệ thống',
                'time' => $this->diffForHumansVi($user->created_at ?? null),
                'sort_time' => $this->normalizeSortTime($user->created_at ?? null),
            ];
        })->values()->all();
    }

    private function getLatestCompletedTestActivities(int $limit = 5): array
    {
        if (!Schema::hasTable('results') || !Schema::hasColumn('results', 'created_at')) {
            return [];
        }

        $query = DB::table('results');

        if (
            Schema::hasColumn('results', 'user_id') &&
            Schema::hasTable('users') &&
            Schema::hasColumn('users', 'id')
        ) {
            $query->leftJoin('users', 'results.user_id', '=', 'users.id')
                ->select(
                    'results.created_at',
                    DB::raw('users.name as user_name'),
                    DB::raw('users.email as user_email')
                );
        } else {
            $query->select('results.created_at');
        }

        $results = $query
            ->orderByDesc('results.created_at')
            ->limit($limit)
            ->get();

        return $results->map(function ($result) {
            $userName = $result->user_name
                ?? (
                    !empty($result->user_email)
                        ? explode('@', $result->user_email)[0]
                        : 'Một người dùng'
                );

            return [
                'title' => 'Bài test mới hoàn thành',
                'description' => $userName . ' vừa hoàn thành bài test MBTI',
                'time' => $this->diffForHumansVi($result->created_at ?? null),
                'sort_time' => $this->normalizeSortTime($result->created_at ?? null),
            ];
        })->values()->all();
    }

    private function getLatestPaidCourseOrderActivities(int $limit = 5): array
    {
        $activities = $this->getLatestPaidOrderActivitiesFromOrders($limit);

        if (!empty($activities)) {
            return $activities;
        }

        return $this->getLatestPaidOrderActivitiesFromCoursePayments($limit);
    }

    private function getLatestPaidOrderActivitiesFromOrders(int $limit = 5): array
    {
        if (
            !Schema::hasTable('orders') ||
            !Schema::hasColumn('orders', 'created_at') ||
            !Schema::hasColumn('orders', 'status')
        ) {
            return [];
        }

        $query = DB::table('orders')
            ->where('orders.status', 'paid');

        if (Schema::hasColumn('orders', 'user_id') && Schema::hasTable('users')) {
            $query->leftJoin('users', 'orders.user_id', '=', 'users.id');
        }

        if (Schema::hasColumn('orders', 'package_id') && Schema::hasTable('service_packages')) {
            $query->leftJoin('service_packages', 'orders.package_id', '=', 'service_packages.id');
        } elseif (Schema::hasColumn('orders', 'service_package_id') && Schema::hasTable('service_packages')) {
            $query->leftJoin('service_packages', 'orders.service_package_id', '=', 'service_packages.id');
        }

        $selects = ['orders.created_at'];

        if (Schema::hasTable('users')) {
            if (Schema::hasColumn('users', 'name')) {
                $selects[] = DB::raw('users.name as user_name');
            }
            if (Schema::hasColumn('users', 'email')) {
                $selects[] = DB::raw('users.email as user_email');
            }
        }

        if (Schema::hasTable('service_packages') && Schema::hasColumn('service_packages', 'name')) {
            $selects[] = DB::raw('service_packages.name as package_name');
        }

        $orders = $query
            ->select($selects)
            ->orderByDesc('orders.created_at')
            ->limit($limit)
            ->get();

        return $orders->map(function ($order) {
            $userName = $order->user_name
                ?? (
                    !empty($order->user_email)
                        ? explode('@', $order->user_email)[0]
                        : 'Một người dùng'
                );

            $packageName = $order->package_name ?? 'một gói khóa học';

            return [
                'title' => 'Người dùng đăng ký khóa học',
                'description' => $userName . ' vừa đăng ký gói ' . $packageName,
                'time' => $this->diffForHumansVi($order->created_at ?? null),
                'sort_time' => $this->normalizeSortTime($order->created_at ?? null),
            ];
        })->values()->all();
    }

    private function getLatestPaidOrderActivitiesFromCoursePayments(int $limit = 5): array
    {
        if (
            !Schema::hasTable('course_payments') ||
            !Schema::hasColumn('course_payments', 'created_at') ||
            !Schema::hasColumn('course_payments', 'status')
        ) {
            return [];
        }

        $query = DB::table('course_payments')
            ->where('course_payments.status', 'paid');

        if (Schema::hasColumn('course_payments', 'user_id') && Schema::hasTable('users')) {
            $query->leftJoin('users', 'course_payments.user_id', '=', 'users.id');
        }

        if (Schema::hasColumn('course_payments', 'course_id') && Schema::hasTable('service_packages')) {
            $query->leftJoin('service_packages', 'course_payments.course_id', '=', 'service_packages.id');
        }

        $selects = ['course_payments.created_at'];

        if (Schema::hasTable('users')) {
            if (Schema::hasColumn('users', 'name')) {
                $selects[] = DB::raw('users.name as user_name');
            }
            if (Schema::hasColumn('users', 'email')) {
                $selects[] = DB::raw('users.email as user_email');
            }
        }

        if (Schema::hasTable('service_packages') && Schema::hasColumn('service_packages', 'name')) {
            $selects[] = DB::raw('service_packages.name as package_name');
        }

        $payments = $query
            ->select($selects)
            ->orderByDesc('course_payments.created_at')
            ->limit($limit)
            ->get();

        return $payments->map(function ($payment) {
            $userName = $payment->user_name
                ?? (
                    !empty($payment->user_email)
                        ? explode('@', $payment->user_email)[0]
                        : 'Một người dùng'
                );

            $packageName = $payment->package_name ?? 'một gói khóa học';

            return [
                'title' => 'Người dùng đăng ký khóa học',
                'description' => $userName . ' vừa đăng ký gói ' . $packageName,
                'time' => $this->diffForHumansVi($payment->created_at ?? null),
                'sort_time' => $this->normalizeSortTime($payment->created_at ?? null),
            ];
        })->values()->all();
    }

    private function getLatestPasswordChangedActivities(int $limit = 5): array
    {
        if (!Schema::hasTable('users')) {
            return [];
        }

        $passwordChangedColumn = null;

        if (Schema::hasColumn('users', 'password_changed_at')) {
            $passwordChangedColumn = 'password_changed_at';
        } elseif (Schema::hasColumn('users', 'password_updated_at')) {
            $passwordChangedColumn = 'password_updated_at';
        }

        if (!$passwordChangedColumn) {
            return [];
        }

        $users = DB::table('users')
            ->select('name', 'email', $passwordChangedColumn)
            ->whereNotNull($passwordChangedColumn)
            ->orderByDesc($passwordChangedColumn)
            ->limit($limit)
            ->get();

        return $users->map(function ($user) use ($passwordChangedColumn) {
            $userName = $user->name
                ?: ($user->email ? explode('@', $user->email)[0] : 'Một người dùng');

            $changedAt = $user->{$passwordChangedColumn} ?? null;

            return [
                'title' => 'Người dùng đổi mật khẩu',
                'description' => $userName . ' vừa cập nhật mật khẩu tài khoản',
                'time' => $this->diffForHumansVi($changedAt),
                'sort_time' => $this->normalizeSortTime($changedAt),
            ];
        })->values()->all();
    }

    private function getLatestAdmissionUpdatedActivities(int $limit = 5): array
    {
        if (
            !Schema::hasTable('admissions') ||
            !Schema::hasColumn('admissions', 'updated_at')
        ) {
            return [];
        }

        $admissions = DB::table('admissions')
            ->select('school_name', 'major_name', 'updated_at')
            ->orderByDesc('updated_at')
            ->limit($limit)
            ->get();

        return $admissions->map(function ($admission) {
            $schoolName = $admission->school_name ?? 'Dữ liệu tuyển sinh';
            $majorName = $admission->major_name ?? '';

            return [
                'title' => 'Dữ liệu tuyển sinh được cập nhật',
                'description' => trim($schoolName . ($majorName ? ' - ' . $majorName : '')),
                'time' => $this->diffForHumansVi($admission->updated_at ?? null),
                'sort_time' => $this->normalizeSortTime($admission->updated_at ?? null),
            ];
        })->values()->all();
    }

    private function safeCountTable(string $table): int
    {
        if (!Schema::hasTable($table)) {
            return 0;
        }

        return (int) DB::table($table)->count();
    }

    private function safeCountWhereDate(string $table, string $column, $fromDate): int
    {
        if (!Schema::hasTable($table) || !Schema::hasColumn($table, $column)) {
            return 0;
        }

        return (int) DB::table($table)
            ->where($column, '>=', $fromDate)
            ->count();
    }

    private function normalizeSortTime($date): string
    {
        if (!$date) {
            return now()->toDateTimeString();
        }

        return Carbon::parse($date)->toDateTimeString();
    }

    private function diffForHumansVi($date): string
    {
        if (!$date) {
            return 'Vừa xong';
        }

        $time = Carbon::parse($date);
        $minutes = (int) $time->diffInMinutes(now());

        if ($minutes < 1) {
            return 'Vừa xong';
        }

        if ($minutes < 60) {
            return $minutes . ' phút trước';
        }

        $hours = (int) $time->diffInHours(now());
        if ($hours < 24) {
            return $hours . ' giờ trước';
        }

        $days = (int) $time->diffInDays(now());
        return $days . ' ngày trước';
    }

    private function paidStatusValues(): array
    {
        return ['PAID', 'paid'];
    }

    private function getPaymentDateColumn(): string
    {
        return Schema::hasColumn('mbti_payment_orders', 'paid_at')
            ? 'paid_at'
            : 'updated_at';
    }

    private function sumPaidRevenueToday(): float
    {
        if (!Schema::hasTable('mbti_payment_orders')) {
            return 0;
        }

        $dateColumn = $this->getPaymentDateColumn();

        return (float) DB::table('mbti_payment_orders')
            ->whereIn('status', $this->paidStatusValues())
            ->whereDate($dateColumn, Carbon::today())
            ->sum('amount');
    }

    private function sumPaidRevenueThisMonth(): float
    {
        if (!Schema::hasTable('mbti_payment_orders')) {
            return 0;
        }

        $dateColumn = $this->getPaymentDateColumn();

        return (float) DB::table('mbti_payment_orders')
            ->whereIn('status', $this->paidStatusValues())
            ->whereYear($dateColumn, now()->year)
            ->whereMonth($dateColumn, now()->month)
            ->sum('amount');
    }

    private function sumPaidRevenueTotal(): float
    {
        if (!Schema::hasTable('mbti_payment_orders')) {
            return 0;
        }

        return (float) DB::table('mbti_payment_orders')
            ->whereIn('status', $this->paidStatusValues())
            ->sum('amount');
    }

    private function buildRevenueChartDay(): array
    {
        if (!Schema::hasTable('mbti_payment_orders')) {
            return [];
        }

        $dateColumn = $this->getPaymentDateColumn();

        $rows = DB::table('mbti_payment_orders')
            ->selectRaw("DATE($dateColumn) as day")
            ->selectRaw("SUM(amount) as total")
            ->whereIn('status', $this->paidStatusValues())
            ->whereNotNull($dateColumn)
            ->where($dateColumn, '>=', now()->subDays(6)->startOfDay())
            ->groupByRaw("DATE($dateColumn)")
            ->get()
            ->keyBy('day');

        return collect(range(6, 0))->map(function ($daysAgo) use ($rows) {
            $date = now()->subDays($daysAgo);
            $key = $date->toDateString();

            return [
                'label' => $date->format('d/m'),
                'date' => $key,
                'amount' => (float) ($rows[$key]->total ?? 0),
            ];
        })->values()->all();
    }

    private function buildRevenueChartWeek(): array
        {
            if (!Schema::hasTable('mbti_payment_orders')) {
                return [];
            }

            $dateColumn = $this->getPaymentDateColumn();

            $startOfMonth = now()->startOfMonth();
            $endOfMonth = now()->endOfMonth();

            $rows = DB::table('mbti_payment_orders')
                ->selectRaw("
                    CASE
                        WHEN DAY($dateColumn) BETWEEN 1 AND 7 THEN 1
                        WHEN DAY($dateColumn) BETWEEN 8 AND 14 THEN 2
                        WHEN DAY($dateColumn) BETWEEN 15 AND 21 THEN 3
                        ELSE 4
                    END as week_index
                ")
                ->selectRaw("SUM(amount) as total")
                ->whereIn('status', $this->paidStatusValues())
                ->whereNotNull($dateColumn)
                ->whereBetween($dateColumn, [$startOfMonth, $endOfMonth])
                ->groupByRaw("
                    CASE
                        WHEN DAY($dateColumn) BETWEEN 1 AND 7 THEN 1
                        WHEN DAY($dateColumn) BETWEEN 8 AND 14 THEN 2
                        WHEN DAY($dateColumn) BETWEEN 15 AND 21 THEN 3
                        ELSE 4
                    END
                ")
                ->get()
                ->keyBy('week_index');

            return collect(range(1, 4))->map(function ($week) use ($rows) {
                return [
                    'label' => 'Tuần ' . $week,
                    'date' => 'week-' . $week,
                    'amount' => (float) ($rows[$week]->total ?? 0),
                ];
            })->values()->all();
        }

    private function buildRevenueChartMonth(): array
    {
        if (!Schema::hasTable('mbti_payment_orders')) {
            return [];
        }

        $dateColumn = $this->getPaymentDateColumn();

        $rows = DB::table('mbti_payment_orders')
            ->selectRaw("DATE_FORMAT($dateColumn, '%Y-%m') as month_key")
            ->selectRaw("SUM(amount) as total")
            ->whereIn('status', $this->paidStatusValues())
            ->whereNotNull($dateColumn)
            ->where($dateColumn, '>=', now()->subMonths(5)->startOfMonth())
            ->groupByRaw("DATE_FORMAT($dateColumn, '%Y-%m')")
            ->orderByRaw("DATE_FORMAT($dateColumn, '%Y-%m')")
            ->get()
            ->keyBy('month_key');

        return collect(range(5, 0))->map(function ($i) use ($rows) {
            $date = now()->subMonths($i);
            $key = $date->format('Y-m');

            return [
                'label' => 'T' . $date->format('n'),
                'date' => $key,
                'amount' => (float) ($rows[$key]->total ?? 0),
            ];
        })->values()->all();
    }

    private function buildRevenueChartYear(): array
    {
        if (!Schema::hasTable('mbti_payment_orders')) {
            return [];
        }

        $dateColumn = $this->getPaymentDateColumn();

        $rows = DB::table('mbti_payment_orders')
            ->selectRaw("YEAR($dateColumn) as year_key")
            ->selectRaw("SUM(amount) as total")
            ->whereIn('status', $this->paidStatusValues())
            ->whereNotNull($dateColumn)
            ->where($dateColumn, '>=', now()->subYears(3)->startOfYear())
            ->groupByRaw("YEAR($dateColumn)")
            ->get()
            ->keyBy('year_key');

        return collect(range(3, 0))->map(function ($i) use ($rows) {
            $date = now()->subYears($i);
            $key = $date->format('Y');

            return [
                'label' => $key,
                'date' => $key,
                'amount' => (float) ($rows[$key]->total ?? 0),
            ];
        })->values()->all();
    }

    private function buildMbtiDistribution(): array
    {
        if (!Schema::hasTable('test_histories')) {
            return [];
        }

        $rows = DB::table('test_histories')
            ->select('result_code', DB::raw('COUNT(*) as total'))
            ->whereNotNull('result_code')
            ->groupBy('result_code')
            ->orderByDesc('total')
            ->get();

        $total = max((int) $rows->sum('total'), 1);

        return $rows->map(function ($row) use ($total) {
            return [
                'type' => strtoupper((string) $row->result_code),
                'count' => (int) $row->total,
                'percent' => round(((int) $row->total / $total) * 100, 1),
            ];
        })->values()->all();
    }

    private function getRecentUsers(int $limit = 6): array
    {
        if (!Schema::hasTable('users')) {
            return [];
        }

        $selects = ['id', 'name', 'email', 'created_at'];

        if (Schema::hasColumn('users', 'avatar')) {
            $selects[] = 'avatar';
        }

        if (Schema::hasColumn('users', 'avatar_url')) {
            $selects[] = 'avatar_url';
        }

        return DB::table('users')
            ->select($selects)
            ->orderByDesc('created_at')
            ->limit($limit)
            ->get()
            ->map(function ($user) {
                $avatar = $user->avatar ?? null;
                $avatarUrl = $user->avatar_url ?? null;

                if (!$avatarUrl && $avatar) {
                    $avatarUrl = str_starts_with($avatar, 'http')
                        ? $avatar
                        : asset('storage/' . ltrim($avatar, '/'));
                }

                return [
                    'id' => $user->id,
                    'name' => $user->name ?: 'Người dùng NAVI',
                    'email' => $user->email ?: 'Chưa có email',
                    'avatar' => $avatar,
                    'avatar_url' => $avatarUrl,
                    'created_at' => $user->created_at,
                ];
            })
            ->values()
            ->all();
    }
    
    private function countUsersWithTests(): int
    {
        if (
            !Schema::hasTable('test_histories') ||
            !Schema::hasColumn('test_histories', 'user_id')
        ) {
            return 0;
        }

        return (int) DB::table('test_histories')
            ->whereNotNull('user_id')
            ->distinct('user_id')
            ->count('user_id');
    }

    private function buildPackageDistribution(int $totalUsers): array
    {
        if (!Schema::hasTable('users') || !Schema::hasColumn('users', 'role')) {
            return [];
        }

        $rows = DB::table('users')
            ->select('role', DB::raw('COUNT(*) as total'))
            ->whereNotIn('role', ['admin'])
            ->groupBy('role')
            ->orderByDesc('total')
            ->get();

        $base = max($totalUsers, 1);

        return $rows
            ->map(function ($row) use ($base) {
                $role = strtolower((string) ($row->role ?? ''));

                $name = match ($role) {
                    'premium' => 'Premium',
                    'plus' => 'Plus',
                    'user' => 'Free',
                    default => null,
                };

                if ($name === null) {
                    return null;
                }

                return [
                    'name' => $name,
                    'count' => (int) $row->total,
                    'percent' => round(((int) $row->total / $base) * 100, 1),
                ];
            })
            ->filter()
            ->values()
            ->all();
    }
} 