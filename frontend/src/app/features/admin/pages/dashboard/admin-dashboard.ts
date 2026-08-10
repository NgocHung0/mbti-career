import {
  ChangeDetectorRef,
  Component,
  DestroyRef,
  NgZone,
  OnInit,
  inject,
} from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { Router, RouterModule } from '@angular/router';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { finalize } from 'rxjs/operators';
import { STORAGE_URL } from '../../../../core/api.config';

type RevenueView = 'day' | 'week' | 'month' | 'year';

type ActivityItem = {
  title: string;
  description: string;
  time?: string;
};

type RecentUserItem = {
  id?: number | null;
  name: string;
  email: string;
  avatar?: string | null;
  avatar_url?: string | null;
  image?: string | null;
  created_at?: string | null;
};

type RevenueChartItem = {
  label: string;
  date: string;
  amount: number;
};

type RevenueDisplayItem = {
  label: string;
  value: number;
};

type MbtiDistributionItem = {
  type: string;
  count: number;
  percent: number;
};

type PackageDistributionItem = {
  name: string;
  count: number;
  percent: number;
};

type DashboardResponse = {
  stats?: {
    total_users?: number;
    total_tests?: number;
    total_majors?: number;
    total_admissions?: number;
    revenue_chart?: RevenueChartItem[];
    revenue_chart_day?: RevenueChartItem[];
    revenue_chart_week?: RevenueChartItem[];
    revenue_chart_month?: RevenueChartItem[];
    revenue_chart_year?: RevenueChartItem[];
    mbti_distribution?: MbtiDistributionItem[];
    package_distribution?: PackageDistributionItem[];
    users_with_tests?: number;
    test_completion_rate?: number;
  };
  revenue?: {
    today?: number;
    month?: number;
    total?: number;
    week?: number;
    year?: number;
  };
  recent_users?: RecentUserItem[];
  recent_activities?: ActivityItem[];
};

type MetricTone = 'blue' | 'green' | 'pink';

type RevenueMetric = {
  label: string;
  shortLabel: string;
  value: number;
  displayValue: string;
  hint: string;
  tone: MetricTone;
};

@Component({
  selector: 'app-admin-dashboard',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './admin-dashboard.html',
  styleUrl: './admin-dashboard.css'
})
export class AdminDashboard implements OnInit {
  private http = inject(HttpClient);
  private router = inject(Router);
  private cdr = inject(ChangeDetectorRef);
  private ngZone = inject(NgZone);
  private destroyRef = inject(DestroyRef);

  private currentRequestId = 0;
  private hasLoadedOnce = false;

  loading = true;
  error = '';

  revenueView: RevenueView = 'day';

  totalUsers = 0;
  totalTests = 0;
  totalMajors = 0;
  totalAdmissions = 0;
  totalRevenue = 0;

  usersWithTests = 0;
  testCompletionPercent = 0;

  recentUsers: RecentUserItem[] = [];
  packageDistribution: PackageDistributionItem[] = [];
  revenueMetrics: RevenueMetric[] = [];
  activities: ActivityItem[] = [];
  revenueChart: RevenueChartItem[] = [];
  revenueChartDay: RevenueChartItem[] = [];
  revenueChartWeek: RevenueChartItem[] = [];
  revenueChartMonth: RevenueChartItem[] = [];
  revenueChartYear: RevenueChartItem[] = [];
  mbtiDistribution: MbtiDistributionItem[] = [];

  ngOnInit(): void {
    queueMicrotask(() => {
      this.loadDashboard(true);
    });
  }

  loadDashboard(forceSkeleton = false): void {
    const requestId = ++this.currentRequestId;

    if (forceSkeleton || !this.hasLoadedOnce) {
      this.loading = true;
    }

    this.error = '';

    if (!this.hasLoadedOnce) {
      this.resetDashboardData();
    }

    this.cdr.detectChanges();

    this.http
      .get<DashboardResponse>('/api/admin/dashboard', {
        withCredentials: true,
      })
      .pipe(
        takeUntilDestroyed(this.destroyRef),
        finalize(() => {
          if (requestId !== this.currentRequestId) return;

          this.ngZone.run(() => {
            this.loading = false;
            this.hasLoadedOnce = true;
            this.cdr.detectChanges();
          });
        })
      )
      .subscribe({
        next: (response) => {
          if (requestId !== this.currentRequestId) return;

          this.ngZone.run(() => {
            try {
              const stats = response?.stats ?? {};
              const revenue = response?.revenue ?? {};

              this.totalUsers = Number(stats.total_users ?? 0);
              this.totalTests = Number(stats.total_tests ?? 0);
              this.totalMajors = Number(stats.total_majors ?? 0);
              this.totalAdmissions = Number(stats.total_admissions ?? 0);
              this.totalRevenue = Number(revenue.total ?? 0);

              this.usersWithTests = Number(
                stats.users_with_tests ??
                Math.min(this.totalTests, this.totalUsers)
              );

              this.testCompletionPercent = Number(
                stats.test_completion_rate ??
                this.calcPercent(this.usersWithTests, this.totalUsers)
              );

              this.revenueMetrics = [
                {
                  label: 'Doanh thu hôm nay',
                  shortLabel: 'Hôm nay',
                  value: Number(revenue.today ?? 0),
                  displayValue: this.formatCurrency(revenue.today ?? 0),
                  hint: 'Doanh thu phát sinh hôm nay',
                  tone: 'green'
                },
                {
                  label: 'Doanh thu tháng',
                  shortLabel: 'Tháng',
                  value: Number(revenue.month ?? 0),
                  displayValue: this.formatCurrency(revenue.month ?? 0),
                  hint: 'Doanh thu trong tháng hiện tại',
                  tone: 'blue'
                },
                {
                  label: 'Tổng doanh thu',
                  shortLabel: 'Tổng',
                  value: Number(revenue.total ?? 0),
                  displayValue: this.formatCurrency(revenue.total ?? 0),
                  hint: 'Tổng doanh thu toàn hệ thống',
                  tone: 'pink'
                }
              ];

              this.recentUsers = Array.isArray(response?.recent_users)
                ? response.recent_users.map((user) => ({
                    id: user?.id ?? null,
                    name: user?.name || 'Người dùng NAVI',
                    email: user?.email || 'Chưa có email',
                    avatar: user?.avatar || null,
                    avatar_url: user?.avatar_url || null,
                    image: user?.image || null,
                    created_at: user?.created_at || null
                  }))
                : [];

              this.packageDistribution = Array.isArray(stats.package_distribution)
                ? stats.package_distribution.map((item) => ({
                    name: item?.name || 'Không xác định',
                    count: Number(item?.count ?? 0),
                    percent: Number(item?.percent ?? 0)
                  }))
                : [];

              this.activities = Array.isArray(response?.recent_activities)
                ? response.recent_activities.map((item) => ({
                    title: item?.title || 'Hoạt động hệ thống',
                    description: item?.description || 'Không có mô tả',
                    time: item?.time || ''
                  }))
                : [];

              this.revenueChart = Array.isArray(stats.revenue_chart)
                ? stats.revenue_chart
                : [];

              this.revenueChartDay = Array.isArray(stats.revenue_chart_day)
                ? stats.revenue_chart_day
                : this.revenueChart;

              this.revenueChartWeek = Array.isArray(stats.revenue_chart_week)
                ? stats.revenue_chart_week
                : [];

              this.revenueChartMonth = Array.isArray(stats.revenue_chart_month)
                ? stats.revenue_chart_month
                : [];

              this.revenueChartYear = Array.isArray(stats.revenue_chart_year)
                ? stats.revenue_chart_year
                : [];

              this.mbtiDistribution = Array.isArray(stats.mbti_distribution)
                ? stats.mbti_distribution
                : [];

              this.error = '';
              this.cdr.detectChanges();
            } catch (e) {
              console.error('Dashboard mapping error:', e);
              this.error = 'Dữ liệu dashboard trả về không đúng định dạng.';
              this.resetDashboardData(false);
              this.cdr.detectChanges();
            }
          });
        },
        error: (err) => {
          if (requestId !== this.currentRequestId) return;

          console.error('Dashboard API error:', err);

          this.ngZone.run(() => {
            this.error = 'Không thể tải dữ liệu dashboard. Vui lòng thử lại.';
            this.resetDashboardData(false);
            this.cdr.detectChanges();
          });
        }
      });
  }

  setRevenueView(view: RevenueView): void {
    this.revenueView = view;
  }

  getRevenueViewLabel(): string {
    if (this.revenueView === 'day') return 'Theo ngày';
    if (this.revenueView === 'week') return 'Theo tuần';
    if (this.revenueView === 'month') return 'Theo tháng';
    return 'Theo năm';
  }

  getRevenueChartData(): RevenueDisplayItem[] {
    const source =
      this.revenueView === 'day'
        ? this.revenueChartDay
        : this.revenueView === 'week'
          ? this.revenueChartWeek
          : this.revenueView === 'month'
            ? this.revenueChartMonth
            : this.revenueChartYear;

    if (source.length) {
      return source.map((item) => ({
        label: item.label || item.date || '',
        value: Number(item.amount ?? 0)
      }));
    }

    const total = this.totalRevenue;

    if (this.revenueView === 'day') {
      return [
        { label: 'T2', value: 0 },
        { label: 'T3', value: 0 },
        { label: 'T4', value: 0 },
        { label: 'T5', value: 0 },
        { label: 'T6', value: total },
        { label: 'T7', value: 0 }
      ];
    }

    if (this.revenueView === 'week') {
      return [
        { label: 'Tuần 1', value: 0 },
        { label: 'Tuần 2', value: 0 },
        { label: 'Tuần 3', value: 0 },
        { label: 'Tuần 4', value: total }
      ];
    }

    if (this.revenueView === 'month') {
      return [
        { label: 'T1', value: 0 },
        { label: 'T2', value: 0 },
        { label: 'T3', value: 0 },
        { label: 'T4', value: 0 },
        { label: 'T5', value: 0 },
        { label: 'T6', value: total }
      ];
    }

    return [
      { label: '2023', value: 0 },
      { label: '2024', value: 0 },
      { label: '2025', value: 0 },
      { label: '2026', value: total }
    ];
  }

  getRevenueMax(): number {
    const values = this.getRevenueChartData().map((item) => Number(item.value || 0));
    return Math.max(...values, 1);
  }

  getRevenueBarHeight(value: number): number {
    if (!value) return 8;
    return Math.max(8, Math.round((value / this.getRevenueMax()) * 100));
  }

  getRevenueViewTotal(): number {
    return this.getRevenueChartData().reduce((sum, item) => sum + Number(item.value || 0), 0);
  }

  userInitial(name: string): string {
    return name?.trim()?.charAt(0)?.toUpperCase() || 'U';
  }
userAvatar(user: RecentUserItem): string {
  if (!user.avatar) return '';

  return `${STORAGE_URL}/${user.avatar}`;
}
  formatDateTime(date?: string | null): string {
    if (!date) return 'Chưa rõ thời gian';

    const normalized = date.includes('T')
      ? date
      : date.replace(' ', 'T');

    const parsed = new Date(normalized + '+00:00');

    return parsed.toLocaleString('vi-VN', {
      timeZone: 'Asia/Ho_Chi_Minh',
      hour12: false
    });
  }

  goTo(route: string): void {
    if (!route) return;
    this.router.navigateByUrl(route);
  }

  trackByIndex(index: number): number {
    return index;
  }

  trackByLabel(_: number, item: { label: string }): string {
    return item.label;
  }

  trackByMbtiType(_: number, item: MbtiDistributionItem): string {
    return item.type;
  }

  trackByPackageName(_: number, item: PackageDistributionItem): string {
    return item.name;
  }

  getTestCompletionRingStyle(): string {
    const percent = this.normalizePercent(this.testCompletionPercent);
    return `conic-gradient(#5caeff 0 ${percent * 3.6}deg, #e8f0f7 ${percent * 3.6}deg 360deg)`;
  }

  getPackageRingStyle(): string {
    if (!this.packageDistribution.length) {
      return 'conic-gradient(#e8f0f7 0 360deg)';
    }

    const colors = ['#69b8ff', '#8f7dff', '#ff7db8', '#67d6b0', '#ffb66b'];
    let start = 0;

    const parts = this.packageDistribution.map((item, index) => {
      const degrees = this.normalizePercent(item.percent) * 3.6;
      const end = start + degrees;
      const color = colors[index % colors.length];
      const part = `${color} ${start}deg ${end}deg`;
      start = end;
      return part;
    });

    if (start < 360) {
      parts.push(`#e8f0f7 ${start}deg 360deg`);
    }

    return `conic-gradient(${parts.join(', ')})`;
  }

  private resetDashboardData(resetActivities = true): void {
    this.totalUsers = 0;
    this.totalTests = 0;
    this.totalMajors = 0;
    this.totalAdmissions = 0;
    this.totalRevenue = 0;

    this.usersWithTests = 0;
    this.testCompletionPercent = 0;

    this.recentUsers = [];
    this.packageDistribution = [];
    this.revenueMetrics = [];
    this.activities = resetActivities ? [] : this.activities;
    this.revenueChart = [];
    this.revenueChartDay = [];
    this.revenueChartWeek = [];
    this.revenueChartMonth = [];
    this.revenueChartYear = [];
    this.mbtiDistribution = [];
  }

  private calcPercent(value: number, total: number): number {
    if (!total || total <= 0) return 0;
    return this.normalizePercent(Math.round((value / total) * 100));
  }

  private formatNumber(value: number): string {
    return new Intl.NumberFormat('vi-VN').format(Number(value || 0));
  }

  formatPublicNumber(value: number): string {
    return this.formatNumber(value);
  }

  private formatCurrency(value: number): string {
    return new Intl.NumberFormat('vi-VN', {
      style: 'currency',
      currency: 'VND',
      maximumFractionDigits: 0
    }).format(Number(value || 0));
  }

  formatPublicCurrency(value: number): string {
    return this.formatCurrency(value);
  }

  private normalizePercent(value: number): number {
    if (Number.isNaN(value)) return 0;
    return Math.max(0, Math.min(100, Math.round(value)));
  }
  getRevenueLineDots() {
  const data = this.getRevenueChartData();
  const max = Math.max(this.getRevenueMax(), 1);

  const width = 900;
  const top = 34;
  const bottom = 260;
  const height = bottom - top;

  if (!data.length) return [];

  return data.map((item, index) => {
    const x = data.length === 1
      ? width / 2
      : (width / (data.length - 1)) * index;

    const y = bottom - (Number(item.value || 0) / max) * height;

    return {
      x: Math.round(x),
      y: Math.round(y),
      label: item.label,
      value: Number(item.value || 0)
    };
  });
}

getRevenueSmoothPath(): string {
  const points = this.getRevenueLineDots();

  if (!points.length) return '';
  if (points.length === 1) return `M ${points[0].x} ${points[0].y}`;

  let d = `M ${points[0].x} ${points[0].y}`;

  for (let i = 1; i < points.length; i++) {
    const prev = points[i - 1];
    const curr = points[i];

    const cx1 = prev.x + (curr.x - prev.x) / 2;
    const cy1 = prev.y;
    const cx2 = prev.x + (curr.x - prev.x) / 2;
    const cy2 = curr.y;

    d += ` C ${cx1} ${cy1}, ${cx2} ${cy2}, ${curr.x} ${curr.y}`;
  }

  return d;
}

getRevenueAreaPath(): string {
  const points = this.getRevenueLineDots();

  if (!points.length) return '';

  const line = this.getRevenueSmoothPath();
  const first = points[0];
  const last = points[points.length - 1];
  const baseline = 260;

  return `${line} L ${last.x} ${baseline} L ${first.x} ${baseline} Z`;
}

getRevenueYAxisTicks(): number[] {
  const max = this.getRevenueMax();
  const rounded = Math.ceil(max / 100000) * 100000 || 100000;

  return [
    rounded,
    Math.round(rounded * 0.75),
    Math.round(rounded * 0.5),
    Math.round(rounded * 0.25),
    0
  ];
}

formatShortCurrency(value: number): string {
  const num = Number(value || 0);

  if (num >= 1000000) {
    return `${Math.round(num / 1000000)}tr đ`;
  }

  if (num >= 1000) {
    return `${Math.round(num / 1000)}k đ`;
  }

  return `${num} đ`;
}
}