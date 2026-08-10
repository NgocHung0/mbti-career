import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { finalize } from 'rxjs/operators';
import Swal from 'sweetalert2';
import { ResultApiService } from '../../services/result-api.service';
import {
  UserPortalService,
  TestHistoryItem,
  TestHistoryDetail
} from '../../services/user-portal.service';
import {
  API_ORIGIN,
  API_URL,
  STORAGE_URL,
} from '../../core/api.config';

type LessonHistoryQuestionItem = {
  questionId: string;
  question: string;
  selectedLabel: string;
  selectedOptionIndex: number;
  selectedOptionContent: string;
  isCorrect: boolean;
  answeredAt: string;
  options: Array<{
    label?: string;
    content: string;
    is_correct?: boolean;
  }>;
  explanation?: string | null;
};

type LessonHistoryItem = {
  lessonId: number;
  lessonTitle: string;
  courseId: number;
  courseName: string;
  updatedAt: string;
  totalQuestions: number;
  correctCount: number;
  wrongCount: number;
  completed: boolean;
  questions: LessonHistoryQuestionItem[];
};

type LessonHistoryStore = Record<string, LessonHistoryItem>;

type InterestGroupKey = 'creative' | 'analytic' | 'social' | 'business';

type AbilityKey =
  | 'LANGUAGE'
  | 'LOGIC'
  | 'CREATIVE'
  | 'TECH'
  | 'LEADERSHIP'
  | 'TEAMWORK'
  | 'DETAIL'
  | 'ADAPT'
  | 'PRACTICAL'
  | 'STRATEGIC';

type CareerItem = {
  name: string;
  description: string;
  mbtiTypes: string[];
  interestGroups: InterestGroupKey[];
  abilityKeys: AbilityKey[];
  schools: string[];
  score?: number;
  reasons?: string[];
};

type RadarAxisKey =
  | 'creative'
  | 'analytic'
  | 'communication'
  | 'leadership'
  | 'technology'
  | 'strategy';

type RadarDatum = {
  key: RadarAxisKey;
  label: string;
  interestValue: number;
  abilityValue: number;
};

type CircularSegment = {
  key: string;
  labelLines: string[];
  percent: number;
  areaPath: string;
  progressPath: string;
  labelX: number;
  labelY: number;
};

@Component({
  selector: 'app-me',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './me.html',
  styleUrl: './me.css'
})
export class MePage implements OnInit {
  private get lessonHistoryStorageKey(): string {
    const userId = this.user?.id || 'guest';
    return `courseLessonHistory_${userId}`;
  }
  avatarPreview = '';
  avatarUploading = false;
  user: any = null;

  testHistories: TestHistoryItem[] = [];
  selectedTestDetail: TestHistoryDetail | null = null;

  lessonHistories: LessonHistoryItem[] = [];
  selectedLessonHistory: LessonHistoryItem | null = null;

  showProfileEdit = true;
  showChangePassword = false;
  showTestHistory = false;
  showLessonHistory = false;

  testHistoryLoaded = false;
  testHistoryLoading = false;
  testHistoryError = '';
  testDetailLoading = false;
  selectedTestHistoryItem: TestHistoryItem | null = null;

  private readonly testDetailCache = new Map<number, TestHistoryDetail>();
  private testDetailRequestToken = 0;
  private testHistoryPrefetchTimer: ReturnType<typeof setTimeout> | null = null;

  lessonHistoryLoaded = false;
  lessonHistoryLoading = false;
  lessonHistoryError = '';

  currentPassword = '';
  newPassword = '';
  confirmPassword = '';
  passwordMessage = '';
  passwordError = '';

  otp = '';
  otpSent = false;
  otpCountdown = 0;
  otpTimer: any = null;
  passwordLoading = false;

  profileName = '';
  profileEmail = '';
  profileMessage = '';
  profileError = '';

  readonly groupLabels: Record<InterestGroupKey, string> = {
    creative: 'Sáng tạo',
    analytic: 'Phân tích - Công nghệ',
    social: 'Con người - Giao tiếp',
    business: 'Kinh doanh - Tổ chức'
  };

  readonly abilityLabels: Record<AbilityKey, string> = {
    LANGUAGE: 'Ngôn ngữ',
    LOGIC: 'Logic',
    CREATIVE: 'Sáng tạo',
    TECH: 'Công nghệ',
    LEADERSHIP: 'Lãnh đạo',
    TEAMWORK: 'Làm việc nhóm',
    DETAIL: 'Chi tiết',
    ADAPT: 'Thích ứng',
    PRACTICAL: 'Thực tế',
    STRATEGIC: 'Chiến lược'
  };

  readonly radarLabels: Record<RadarAxisKey, string> = {
    creative: 'Sáng tạo',
    analytic: 'Phân tích',
    communication: 'Giao tiếp',
    leadership: 'Lãnh đạo',
    technology: 'Công nghệ',
    strategy: 'Chiến lược'
  };

  readonly svgSize = 420;
  readonly svgCenter = 210;
  readonly svgRadius = 140;

  readonly overviewSvgSize = 620;
  readonly overviewCenter = 310;

  constructor(
    private router: Router,
    private route: ActivatedRoute,
    private api: ResultApiService,
    private userPortal: UserPortalService,
    private cdr: ChangeDetectorRef,
    private http: HttpClient
  ) {}

  ngOnInit(): void {
    if (typeof window === 'undefined') return;

    const token = localStorage.getItem('auth_token');
    if (!token) {
      this.router.navigateByUrl('/login');
      return;
    }

    this.loadUser();
    this.scheduleTestHistoryPrefetch();

    this.route.queryParamMap.subscribe(params => {
      const tab = params.get('tab');

      if (tab === 'lessons') {
        this.showLessonHistory = true;
        this.showProfileEdit = false;
        this.showChangePassword = false;
        this.showTestHistory = false;

        if (!this.lessonHistoryLoaded && !this.lessonHistoryLoading) {
          this.loadLessonHistory();
        }
        return;
      }

      if (tab === 'history') {
        this.showTestHistory = true;
        this.showProfileEdit = false;
        this.showChangePassword = false;
        this.showLessonHistory = false;

        if (!this.testHistoryLoaded && !this.testHistoryLoading) {
          this.loadTestHistory();
        }
      }
    });
  }

    loadUser(): void {
      if (typeof window === 'undefined') return;

      this.http
        .get<any>(`${API_URL}/me`, {
          withCredentials: true,
          headers: this.getAuthHeaders()
        })
        .subscribe({
          next: (res) => {
            const latestUser =
              res?.user ??
              res?.data ??
              res;

            if (!latestUser) {
              this.loadUserFromLocalStorage();
              return;
            }

            this.user = latestUser;
            this.profileName = latestUser?.name || '';
            this.profileEmail = latestUser?.email || '';

            localStorage.setItem(
              'auth_user',
              JSON.stringify(latestUser)
            );

            this.api.user.set(latestUser);
            this.cdr.detectChanges();
          },

          error: (error) => {
            console.error('Không tải được thông tin người dùng:', {
              status: error?.status,
              statusText: error?.statusText,
              url: error?.url,
              error: error?.error
            });

            this.user = null;
            this.profileName = '';
            this.profileEmail = '';

            this.profileError =
              error?.status === 401
                ? 'Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại.'
                : 'Không tải được thông tin mới nhất từ hệ thống.';

            this.cdr.detectChanges();
          }
        });
    }

    private loadUserFromLocalStorage(): void {
      if (typeof window === 'undefined') return;

      const raw = localStorage.getItem('auth_user');

      if (!raw) {
        this.user = null;
        return;
      }

      try {
        this.user = JSON.parse(raw);
        this.profileName = this.user?.name || '';
        this.profileEmail = this.user?.email || '';
      } catch {
        this.user = null;
      }
    }

  fillProfileForm(): void {
    this.profileName = this.user?.name || '';
    this.profileEmail = this.user?.email || '';
  }

  private scheduleTestHistoryPrefetch(): void {
    if (typeof window === 'undefined') return;
    if (this.testHistoryLoaded || this.testHistoryLoading) return;

    if (this.testHistoryPrefetchTimer) {
      clearTimeout(this.testHistoryPrefetchTimer);
    }

    this.testHistoryPrefetchTimer = setTimeout(() => {
      if (!this.testHistoryLoaded && !this.testHistoryLoading) {
        this.loadTestHistory();
      }
    }, 150);
  }

  toggleProfileEdit(): void {
    this.showProfileEdit = !this.showProfileEdit;

    if (this.showProfileEdit) {
      this.showChangePassword = false;
      this.showTestHistory = false;
      this.showLessonHistory = false;
      this.clearQueryTab();
    }

    this.profileMessage = '';
    this.profileError = '';
  }

  saveProfile(): void {
    this.profileMessage = '';
    this.profileError = '';

    const name = this.profileName.trim();

    if (!name) {
      this.profileError = 'Vui lòng nhập họ và tên.';
      return;
    }

    this.http
      .post<any>(
        `${API_URL}/profile/update`,
        { name },
        {
          withCredentials: true,
          headers: this.getAuthHeaders()
        }
      )
      .subscribe({
        next: (res) => {
          const updatedUser = {
            ...(this.user || {}),
            ...(res?.user || {}),
            email: this.user?.email
          };

          this.user = updatedUser;
          this.profileName = updatedUser.name || '';
          this.profileEmail = updatedUser.email || '';

          localStorage.setItem(
            'auth_user',
            JSON.stringify(updatedUser)
          );

          this.api.user.set(updatedUser);

          this.profileMessage =
            res?.message ||
            'Cập nhật thông tin cá nhân thành công.';

          this.cdr.detectChanges();
        },

        error: (err) => {
          this.profileError =
            err?.error?.errors?.name?.[0] ||
            err?.error?.message ||
            'Không cập nhật được thông tin cá nhân.';

          this.cdr.detectChanges();
        }
      });
  }

  toggleChangePassword(): void {
    this.showChangePassword = !this.showChangePassword;

    if (this.showChangePassword) {
      this.showProfileEdit = false;
      this.showTestHistory = false;
      this.showLessonHistory = false;
      this.clearQueryTab();
    }

    this.passwordMessage = '';
    this.passwordError = '';
  }

  toggleTestHistory(): void {
    this.showTestHistory = !this.showTestHistory;

    if (this.showTestHistory) {
      this.showProfileEdit = false;
      this.showChangePassword = false;
      this.showLessonHistory = false;

      this.router.navigate([], {
        relativeTo: this.route,
        queryParams: { tab: 'history' },
        queryParamsHandling: 'merge',
        replaceUrl: true
      });

      if (!this.testHistoryLoaded && !this.testHistoryLoading) {
        this.loadTestHistory();
      }
    } else {
      this.clearQueryTab();
    }
  }

  loadTestHistory(forceReload = false): void {
    if (this.testHistoryPrefetchTimer) {
      clearTimeout(this.testHistoryPrefetchTimer);
      this.testHistoryPrefetchTimer = null;
    }

    if (!forceReload) {
      if (this.testHistoryLoading) return;
      if (this.testHistoryLoaded && this.testHistories.length > 0) return;
    } else {
      this.testHistoryLoaded = false;
      this.testDetailCache.clear();
    }

    this.testHistoryLoading = true;
    this.testHistoryError = '';
    this.cdr.detectChanges();

    this.userPortal.getHistories()
      .pipe(
        finalize(() => {
          this.testHistoryLoading = false;
          this.testHistoryLoaded = true;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: (res) => {
          const items = Array.isArray(res?.histories) ? res.histories : [];
          this.testHistories = [...items].sort((a, b) => {
            return new Date(b.created_at).getTime() - new Date(a.created_at).getTime();
          });
          this.testHistoryError = '';
        },
        error: (err) => {
          this.testHistories = [];
          this.testHistoryError =
            err?.error?.message ||
            err?.message ||
            'Không tải được lịch sử test.';
        }
      });
  }

  viewTestDetail(item: TestHistoryItem): void {
    this.testHistoryError = '';
    this.selectedTestHistoryItem = item;

    const cachedDetail = this.testDetailCache.get(item.id);
    if (cachedDetail) {
      this.selectedTestDetail = cachedDetail;
      this.testDetailLoading = false;
      this.cdr.detectChanges();
      return;
    }

    const requestToken = ++this.testDetailRequestToken;
    this.selectedTestDetail = null;
    this.testDetailLoading = true;
    this.cdr.detectChanges();

    this.userPortal.getHistoryDetail(item.id)
      .pipe(
        finalize(() => {
          if (requestToken !== this.testDetailRequestToken) return;
          this.testDetailLoading = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: (res) => {
          if (requestToken !== this.testDetailRequestToken) return;

          const detail = res?.history ?? null;
          if (detail) {
            this.testDetailCache.set(item.id, detail);
          }

          this.selectedTestDetail = detail;
        },
        error: () => {
          if (requestToken !== this.testDetailRequestToken) return;
          this.selectedTestDetail = null;
          this.testHistoryError = 'Không tải được chi tiết lịch sử test.';
        }
      });
  }

  cancelTestDetailLoading(): void {
    this.testDetailRequestToken += 1;
    this.testDetailLoading = false;
    this.selectedTestDetail = null;
    this.selectedTestHistoryItem = null;
    this.cdr.detectChanges();
  }

  closeTestDetail(): void {
    this.selectedTestDetail = null;
    this.selectedTestHistoryItem = null;
    this.testDetailLoading = false;
  }

  toggleLessonHistory(): void {
    this.showLessonHistory = !this.showLessonHistory;

    if (this.showLessonHistory) {
      this.showProfileEdit = false;
      this.showChangePassword = false;
      this.showTestHistory = false;

      this.router.navigate([], {
        relativeTo: this.route,
        queryParams: { tab: 'lessons' },
        queryParamsHandling: 'merge',
        replaceUrl: true
      });

      if (!this.lessonHistoryLoaded && !this.lessonHistoryLoading) {
        this.loadLessonHistory();
      }
    } else {
      this.clearQueryTab();
    }
  }

  loadLessonHistory(forceReload = false): void {
    if (typeof window === 'undefined') return;

    if (forceReload) {
      this.lessonHistoryLoaded = false;
    }

    this.lessonHistoryLoading = true;
    this.lessonHistoryError = '';
    this.cdr.detectChanges();

    this.http
      .get<any>(`${API_URL}/course-quiz-history`, {
        withCredentials: true,
        headers: this.getAuthHeaders(),
      })
      .pipe(finalize(() => {
        this.lessonHistoryLoading = false;
        this.lessonHistoryLoaded = true;
        this.cdr.detectChanges();
      }))
      .subscribe({
        next: (res) => {
          const rawItems = Array.isArray(res?.histories)
            ? res.histories
            : Array.isArray(res?.data)
              ? res.data
              : Array.isArray(res)
                ? res
                : [];

          this.lessonHistories = rawItems
            .map((item: any) => this.normalizeLessonHistory(item))
            .filter((item: LessonHistoryItem | null): item is LessonHistoryItem => !!item)
            .sort(
              (a: LessonHistoryItem, b: LessonHistoryItem) =>
                new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime()
            );

          this.lessonHistoryError = '';
          this.cdr.detectChanges();
        },
        error: (error) => {
          console.error('Load course quiz history error:', error);

          this.lessonHistories = [];
          this.lessonHistoryError =
            error?.error?.message ||
            'Không tải được lịch sử làm bài khóa học từ hệ thống.';

          this.cdr.detectChanges();
        },
      });
  }

  openLessonHistoryDetail(item: LessonHistoryItem): void {
    this.selectedLessonHistory = item;
  }

  closeLessonHistoryDetail(): void {
    this.selectedLessonHistory = null;
  }

  clearLessonHistory(): void {
    this.lessonHistoryError =
      'Lịch sử đang được lưu trên hệ thống nên không thể xóa bằng localStorage nữa.';
    this.cdr.detectChanges();
  }

  requestPasswordOtp(): void {
    this.passwordMessage = '';
    this.passwordError = '';

    if (!this.currentPassword || !this.newPassword || !this.confirmPassword) {
      this.passwordError = 'Vui lòng nhập đầy đủ thông tin.';
      return;
    }

    if (this.newPassword.length < 6) {
      this.passwordError = 'Mật khẩu mới phải có ít nhất 6 ký tự.';
      return;
    }

    if (this.newPassword !== this.confirmPassword) {
      this.passwordError = 'Mật khẩu xác nhận không khớp.';
      return;
    }

    this.passwordLoading = true;

    this.http.post<any>(`${API_URL}/change-password/request-otp`, {
      current_password: this.currentPassword,
      new_password: this.newPassword,
      new_password_confirmation: this.confirmPassword,
    }, {
      withCredentials: true,
      headers: this.getAuthHeaders(),
    }).pipe(
      finalize(() => {
        this.passwordLoading = false;
        this.cdr.detectChanges();
      })
    ).subscribe({
      next: (res) => {
        this.otpSent = true;
        this.otp = '';
        this.passwordMessage = res?.message || 'Mã OTP đã được gửi về email của bạn.';
        this.passwordError = '';
        this.startOtpCountdown();
      },
      error: (err) => {
        this.passwordMessage = '';
        this.passwordError =
          err?.error?.message ||
          err?.error?.errors?.current_password?.[0] ||
          err?.error?.errors?.new_password?.[0] ||
          'Không gửi được mã OTP.';
      }
    });
  }

  verifyPasswordOtp(): void {
    this.passwordMessage = '';
    this.passwordError = '';

    if (!this.otp || this.otp.trim().length !== 6) {
      this.passwordError = 'Vui lòng nhập mã OTP gồm 6 số.';
      return;
    }

    this.passwordLoading = true;

    this.http.post<any>(`${API_URL}/change-password/verify-otp`, {
      otp: this.otp.trim(),
    }, {
      withCredentials: true,
      headers: this.getAuthHeaders(),
    }).pipe(
      finalize(() => {
        this.passwordLoading = false;
        this.cdr.detectChanges();
      })
    ).subscribe({
      next: (res) => {
        this.passwordMessage = res?.message || 'Đổi mật khẩu thành công.';
        this.passwordError = '';

        this.currentPassword = '';
        this.newPassword = '';
        this.confirmPassword = '';
        this.otp = '';
        this.otpSent = false;
        this.stopOtpCountdown();
      },
      error: (err) => {
        this.passwordMessage = '';
        this.passwordError =
          err?.error?.message ||
          err?.error?.errors?.otp?.[0] ||
          'Xác nhận OTP thất bại.';
      }
    });
  }

  startOtpCountdown(): void {
    this.stopOtpCountdown();
    this.otpCountdown = 300;

    this.otpTimer = setInterval(() => {
      this.otpCountdown--;

      if (this.otpCountdown <= 0) {
        this.stopOtpCountdown();
      }

      this.cdr.detectChanges();
    }, 1000);
  }

  stopOtpCountdown(): void {
    if (this.otpTimer) {
      clearInterval(this.otpTimer);
      this.otpTimer = null;
    }
  }

  formatOtpTime(): string {
    const minutes = Math.floor(this.otpCountdown / 60);
    const seconds = this.otpCountdown % 60;

    return `${minutes}:${seconds.toString().padStart(2, '0')}`;
  }

  clearQueryTab(): void {
    this.router.navigate([], {
      relativeTo: this.route,
      queryParams: {},
      replaceUrl: true
    });
  }

  answerOf(questionId: number | string): string {
    const detail = this.selectedTestDetail;
    if (!detail?.answers) return '-';
    return detail.answers[String(questionId)] || '-';
  }

  testTypeLabel(type: string): string {
    if (type === 'mbti') return 'MBTI';
    if (type === 'ability') return 'Năng lực + sở thích';
    if (type === 'full') return 'Bài test đầy đủ';
    return type;
  }

  summaryTitle(item: TestHistoryItem): string {
    return item.result_code || 'Chưa có kết quả';
  }

  summarySubtitle(item: TestHistoryItem): string {
    return `${this.testTypeLabel(item.test_type)} • ${this.historyPackageName(item as any)}`;
  }

    private normalizePackageName(value: unknown): string {
    return String(value || '')
      .trim()
      .toLowerCase();
  }

  private isFreePackageName(name: string): boolean {
    return [
      '',
      'free',
      'basic',
      'cơ bản',
      'co ban',
      'không dùng gói',
      'khong dung goi',
      'miễn phí',
      'mien phi'
    ].includes(name);
  }

  historyPackageName(source: any): string {
    const raw = this.normalizePackageName(source?.package_name);

    if (this.isFreePackageName(raw)) {
      return 'Không dùng gói';
    }

    return source?.package_name || 'Không dùng gói';
  }

  hasSnapshotPackage(source: any): boolean {
    const packageId = Number(source?.package_id || 0);
    const packageName = this.normalizePackageName(source?.package_name);

    if (packageId > 0) return true;
    return !this.isFreePackageName(packageName);
  }

  isMbtiHistory(detail: any): boolean {
    const type = String(detail?.test_type || '').toLowerCase();
    return type === 'mbti' || type === 'plus';
  }

  isPlusHistory(detail: any): boolean {
    const type = String(detail?.test_type || '').toLowerCase();
    return type === 'plus';
  }

  isFullHistory(detail: any): boolean {
    const type = String(detail?.test_type || '').toLowerCase();

    if (type === 'ability' || type === 'full') {
      return true;
    }

    const payload = detail?.result_payload || {};

    return !!payload?.ability_scores
      || Array.isArray(payload?.top_abilities);
  }

  isBasicFreeHistory(detail: any): boolean {
    return !this.isPlusHistory(detail)
      && this.isMbtiHistory(detail)
      && !this.hasSnapshotPackage(detail)
      && !this.isFullHistory(detail);
  }

  isBasicPaidHistory(detail: any): boolean {
    return this.isPlusHistory(detail)
      || (
        this.isMbtiHistory(detail)
        && this.hasSnapshotPackage(detail)
        && !this.isFullHistory(detail)
      );
  }

  shouldShowMbtiStrengths(detail: any): boolean {
    return this.isMbtiHistory(detail);
  }

  shouldShowMbtiAxis(detail: any): boolean {
    return this.isBasicPaidHistory(detail);
  }

  shouldShowMbtiStudySuggestion(detail: any): boolean {
    return this.isBasicPaidHistory(detail);
  }

  shouldShowMbtiMajors(detail: any): boolean {
    return this.isBasicPaidHistory(detail);
  }

  shouldShowMbtiSchools(detail: any): boolean {
    return this.isBasicPaidHistory(detail);
  }

  shouldShowFullBlocks(detail: any): boolean {
    return this.isFullHistory(detail);
  }

  shouldShowBasicUpgradeNote(detail: any): boolean {
    return this.isBasicFreeHistory(detail);
  }

  shouldShowAnswerDetail(detail: any): boolean {
    return !this.isBasicPaidHistory(detail) && !this.isFullHistory(detail);
  }

  resultTitle(detail: TestHistoryDetail | null): string {
    if (!detail) return 'Báo cáo kết quả';

    const payloadTitle = detail.result_payload?.title;
    if (payloadTitle) return payloadTitle;

    return detail.result_code || 'Báo cáo kết quả';
  }

  resultSummary(detail: TestHistoryDetail | null): string {
    if (!detail) return '';

    const payloadSummary = detail.result_payload?.summary;
    if (payloadSummary) return payloadSummary;

    return 'Xem lại kết quả, điểm số và đáp án bạn đã chọn trong lần làm bài này.';
  }

  scoreEntries(detail: TestHistoryDetail | null): Array<{ key: string; value: number }> {
    if (!detail?.scores) return [];

    return Object.entries(detail.scores)
      .sort((a, b) => b[1] - a[1])
      .map(([key, value]) => ({
        key: this.formatScoreKey(key),
        value
      }));
  }

  formatScoreKey(key: string): string {
    return this.abilityLabels[key as AbilityKey] || key;
  }

  getDisplayQuestionLabel(index: number): string {
    return `Câu ${index + 1}`;
  }

  getQuestionSectionLabel(question: any): string {
    const id = Number(question?.id || 0);
    return id >= 21 ? 'Nâng cao' : 'Cơ bản';
  }

  getMbtiType(detail: TestHistoryDetail | null): string {
    if (!detail) return '----';

    const payloadType = detail.result_payload?.mbti_type;
    if (payloadType) return payloadType;

    if (detail.test_type === 'mbti' && detail.result_code) {
      return detail.result_code;
    }

    return '----';
  }

  getTopInterestLabel(detail: TestHistoryDetail | null): string {
    const topGroups = detail?.result_payload?.interest_top_groups;
    if (Array.isArray(topGroups) && topGroups.length) {
      const top = topGroups[0];
      return this.groupLabels[top.key as InterestGroupKey] || top.key;
    }

    const fallback = this.getInterestGroupScores(detail);
    const entries = Object.entries(fallback).sort((a, b) => b[1] - a[1]);
    if (!entries.length) return '--';

    return this.groupLabels[entries[0][0] as InterestGroupKey] || entries[0][0];
  }


  historyAiAnalysis(detail: TestHistoryDetail | null): string {
    return String(
      detail?.result_payload?.ai_analysis ??
      detail?.result_payload?.aiAnalysis ??
      ''
    ).trim();
  }

  getTopAbilityLabel(detail: TestHistoryDetail | null): string {
    const topAbilities = detail?.result_payload?.top_abilities;

    if (Array.isArray(topAbilities) && topAbilities.length) {
      const first = topAbilities[0];

      if (typeof first === 'string') {
        return first;
      }

      return String(
        first?.title ??
        first?.label ??
        first?.key ??
        ''
      ).trim() || '--';
    }

    const abilityScores = this.getAbilityScores(detail);
    const entries = Object.entries(abilityScores).sort((a, b) => b[1] - a[1]);
    if (!entries.length) return '--';

    return this.abilityLabels[entries[0][0] as AbilityKey] || entries[0][0];
  }

  getAbilityScores(detail: TestHistoryDetail | null): Record<string, number> {
    if (!detail?.scores) return {};

    if (detail.result_payload?.ability_scores) {
      return detail.result_payload.ability_scores;
    }

    const abilityKeys: AbilityKey[] = [
      'LANGUAGE',
      'LOGIC',
      'CREATIVE',
      'TECH',
      'LEADERSHIP',
      'TEAMWORK',
      'DETAIL',
      'ADAPT',
      'PRACTICAL',
      'STRATEGIC'
    ];

    const filtered: Record<string, number> = {};
    for (const key of abilityKeys) {
      if (typeof detail.scores[key] === 'number') {
        filtered[key] = detail.scores[key];
      }
    }

    return filtered;
  }

  getInterestGroupScores(detail: TestHistoryDetail | null): Record<InterestGroupKey, number> {
    const payloadScores = detail?.result_payload?.interest_group_scores;
    if (payloadScores) {
      return payloadScores;
    }

    const abilityScores = this.getAbilityScores(detail);

    return {
      creative: (abilityScores['CREATIVE'] || 0) + (abilityScores['LANGUAGE'] || 0),
      analytic: (abilityScores['LOGIC'] || 0) + (abilityScores['TECH'] || 0),
      social: (abilityScores['TEAMWORK'] || 0) + (abilityScores['LANGUAGE'] || 0),
      business: (abilityScores['LEADERSHIP'] || 0) + (abilityScores['STRATEGIC'] || 0)
    };
  }

  getHistoryMbtiTitle(detail: TestHistoryDetail | null): string {
  const type = this.getMbtiType(detail);

  const titles: Record<string, string> = {
    INTJ: 'Kiến Trúc Sư',
    INTP: 'Nhà Tư Duy',
    ENTJ: 'Người Chỉ Huy',
    ENTP: 'Người Tranh Biện',
    INFJ: 'Người Cố Vấn',
    INFP: 'Người Hòa Giải',
    ENFJ: 'Người Dẫn Dắt',
    ENFP: 'Người Truyền Cảm Hứng',
    ISTJ: 'Người Thanh Tra',
    ISFJ: 'Người Bảo Vệ',
    ESTJ: 'Người Điều Hành',
    ESFJ: 'Người Quan Tâm',
    ISTP: 'Nhà Thực Nghiệm',
    ISFP: 'Người Nghệ Sĩ',
    ESTP: 'Người Thực Thi',
    ESFP: 'Người Trình Diễn'
  };

  return titles[type] || 'Nhóm tính cách';
}

getHistoryHeroTitle(detail: TestHistoryDetail | null): string {
  const type = this.getMbtiType(detail);

  if (type && type !== '----') {
    return `${this.getHistoryMbtiTitle(detail)} (${type})`;
  }

  return this.resultTitle(detail);
}

getHistoryMbtiBars(detail: TestHistoryDetail | null): Array<{
  left: string;
  right: string;
  label: string;
  dominant: string;
  percent: number;
}> {
  const scores = detail?.result_payload?.mbti_scores || detail?.scores || {};

  const build = (
    left: string,
    right: string,
    leftValue: number,
    rightValue: number,
    label: string
  ) => {
    const total = Number(leftValue || 0) + Number(rightValue || 0);
    const leftPercent = total ? Math.round((Number(leftValue || 0) / total) * 100) : 50;
    const rightPercent = 100 - leftPercent;

    return leftValue >= rightValue
      ? { left, right, label, dominant: left, percent: leftPercent }
      : { left, right, label, dominant: right, percent: rightPercent };
  };

  return [
    build('E', 'I', Number(scores.E || 0), Number(scores.I || 0), 'Hướng ngoại / Hướng nội'),
    build('S', 'N', Number(scores.S || 0), Number(scores.N || 0), 'Thực tế / Trực giác'),
    build('T', 'F', Number(scores.T || 0), Number(scores.F || 0), 'Lý trí / Cảm xúc'),
    build('J', 'P', Number(scores.J || 0), Number(scores.P || 0), 'Kế hoạch / Linh hoạt')
  ];
}

getHistoryInterestRows(detail: TestHistoryDetail | null): Array<{
  key: InterestGroupKey;
  label: string;
  percent: number;
}> {
  const g = this.getInterestGroupScores(detail);

  const total =
    Number(g.creative || 0) +
    Number(g.analytic || 0) +
    Number(g.social || 0) +
    Number(g.business || 0);

  const toPercent = (value: number) =>
    total ? Math.round((Number(value || 0) / total) * 100) : 0;

  return [
    { key: 'creative', label: 'Sáng tạo', percent: toPercent(g.creative) },
    { key: 'analytic', label: 'Phân tích - Công nghệ', percent: toPercent(g.analytic) },
    { key: 'social', label: 'Con người - Giao tiếp', percent: toPercent(g.social) },
    { key: 'business', label: 'Kinh doanh - Tổ chức', percent: toPercent(g.business) }
  ];
}

getHistoryTopInterestGroups(detail: TestHistoryDetail | null): Array<{
  key: InterestGroupKey;
  label: string;
  description: string;
}> {
  const descriptions: Record<InterestGroupKey, string> = {
    creative: 'Bạn có xu hướng thích ý tưởng mới, nội dung, hình ảnh, thẩm mỹ và môi trường linh hoạt.',
    analytic: 'Bạn thiên về logic, công nghệ, tối ưu hệ thống và giải quyết vấn đề bằng phân tích.',
    social: 'Bạn quan tâm đến con người, giao tiếp, hỗ trợ, kết nối và làm việc cộng tác.',
    business: 'Bạn phù hợp với môi trường có mục tiêu rõ, tổ chức, vận hành và định hướng kết quả.'
  };

  return this.getHistoryInterestRows(detail)
    .sort((a, b) => b.percent - a.percent)
    .slice(0, 2)
    .map(item => ({
      key: item.key,
      label: item.label,
      description: descriptions[item.key]
    }));
}

  getTopAbilities(detail: TestHistoryDetail | null): string[] {
    const payloadTop = detail?.result_payload?.top_abilities;

    if (Array.isArray(payloadTop) && payloadTop.length) {
      return payloadTop
        .map((item: any) => {
          if (typeof item === 'string') return item;

          return String(
            item?.title ??
            item?.label ??
            item?.key ??
            ''
          ).trim();
        })
        .filter(Boolean);
    }

    const abilityScores = this.getAbilityScores(detail);

    return Object.entries(abilityScores)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 3)
      .map(([key]) => this.abilityLabels[key as AbilityKey] || key);
  }

  getCareerData(): CareerItem[] {
    return [
      {
        name: 'Truyền thông đa phương tiện',
        description: 'Phù hợp với người thích sáng tạo nội dung, hình ảnh, video và truyền tải thông điệp.',
        mbtiTypes: ['ENFP', 'INFP', 'ENFJ', 'ESFP'],
        interestGroups: ['creative', 'social'],
        abilityKeys: ['CREATIVE', 'LANGUAGE', 'TEAMWORK'],
        schools: ['Đại học Văn Hiến', 'Đại học Văn Lang', 'Đại học Hoa Sen']
      },
      {
        name: 'Marketing',
        description: 'Phù hợp với người thích sáng tạo, hiểu khách hàng và phát triển ý tưởng truyền thông.',
        mbtiTypes: ['ENFP', 'ENTP', 'ENFJ', 'ESFP'],
        interestGroups: ['creative', 'business', 'social'],
        abilityKeys: ['LANGUAGE', 'CREATIVE', 'STRATEGIC', 'TEAMWORK'],
        schools: ['Đại học Tài chính - Marketing', 'UEH', 'Đại học Văn Lang']
      },
      {
        name: 'Tâm lý học',
        description: 'Phù hợp với người quan tâm đến hành vi, cảm xúc và định hướng hỗ trợ người khác.',
        mbtiTypes: ['INFJ', 'INFP', 'ENFJ', 'ISFJ'],
        interestGroups: ['social'],
        abilityKeys: ['LANGUAGE', 'TEAMWORK', 'ADAPT'],
        schools: ['Đại học KHXH&NV', 'Đại học Văn Hiến', 'Đại học Sư phạm TP.HCM']
      },
      {
        name: 'Thiết kế đồ họa',
        description: 'Phù hợp với người yêu cái đẹp, thích sáng tạo hình ảnh và tư duy thẩm mỹ.',
        mbtiTypes: ['ISFP', 'INFP', 'ENFP', 'ESFP'],
        interestGroups: ['creative'],
        abilityKeys: ['CREATIVE', 'DETAIL'],
        schools: ['Đại học Kiến trúc', 'Đại học Văn Lang', 'Đại học Công nghiệp TP.HCM']
      },
      {
        name: 'Công nghệ thông tin',
        description: 'Phù hợp với người thích công nghệ, logic, xây dựng hệ thống và giải quyết vấn đề.',
        mbtiTypes: ['INTJ', 'INTP', 'ISTJ', 'ISTP'],
        interestGroups: ['analytic'],
        abilityKeys: ['LOGIC', 'TECH', 'DETAIL', 'PRACTICAL'],
        schools: ['Đại học Công nghệ Thông tin', 'Đại học Bách khoa', 'Đại học Khoa học Tự nhiên']
      },
      {
        name: 'Phân tích dữ liệu',
        description: 'Phù hợp với người thích số liệu, logic và tìm insight từ dữ liệu.',
        mbtiTypes: ['INTJ', 'INTP', 'ISTJ'],
        interestGroups: ['analytic', 'business'],
        abilityKeys: ['LOGIC', 'TECH', 'STRATEGIC', 'DETAIL'],
        schools: ['Đại học Công nghệ Thông tin', 'Đại học Bách khoa', 'UEH']
      },
      {
        name: 'Quản trị kinh doanh',
        description: 'Phù hợp với người thích tổ chức, chiến lược, quản lý và định hướng mục tiêu.',
        mbtiTypes: ['ENTJ', 'ESTJ', 'ENFJ', 'ESTP'],
        interestGroups: ['business', 'social'],
        abilityKeys: ['LEADERSHIP', 'STRATEGIC', 'TEAMWORK', 'LANGUAGE'],
        schools: ['UEH', 'Đại học Ngoại thương', 'Đại học Văn Hiến']
      },
      {
        name: 'Quan hệ công chúng',
        description: 'Phù hợp với người giao tiếp tốt, thích kết nối cộng đồng và xây dựng hình ảnh.',
        mbtiTypes: ['ENFJ', 'ENFP', 'ESFJ', 'ESFP'],
        interestGroups: ['social', 'creative'],
        abilityKeys: ['LANGUAGE', 'TEAMWORK', 'CREATIVE'],
        schools: ['Đại học KHXH&NV', 'Đại học Hoa Sen', 'Đại học Văn Lang']
      }
    ];
  }

  getPremiumHistoryCareers(detail: TestHistoryDetail | null): CareerItem[] {
    const payload = detail?.result_payload || {};

    const majors =
      Array.isArray(payload?.top_majors) ? payload.top_majors :
      Array.isArray(payload?.top_major) ? payload.top_major :
      Array.isArray(payload?.recommendations) ? payload.recommendations :
      Array.isArray(payload?.suggested_careers) ? payload.suggested_careers :
      [];

    if (!majors.length) {
      return this.getSuggestedCareers(detail);
    }

    return majors.map((item: any) => ({
      name: String(item?.name ?? ''),
      description: String(item?.description ?? ''),
      mbtiTypes: Array.isArray(item?.suitable_mbti) ? item.suitable_mbti : [],
      interestGroups: [],
      abilityKeys: [],
      schools: Array.isArray(item?.schools)
        ? item.schools
        : Array.isArray(item?.universities)
          ? item.universities
          : [],
      score: Number(item?.score ?? 0),
      reasons: Array.isArray(item?.reasons) ? item.reasons : []
    }));
  }

  getSuggestedCareers(detail: TestHistoryDetail | null): CareerItem[] {
    const mbtiType = this.getMbtiType(detail);
    const interestScores = this.getInterestGroupScores(detail);
    const abilityScores = this.getAbilityScores(detail);

    const topGroupKeys = Object.entries(interestScores)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 2)
      .map(([key]) => key as InterestGroupKey);

    const topAbilityKeys = Object.entries(abilityScores)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 3)
      .map(([key]) => key as AbilityKey);

    return this.getCareerData()
      .map(career => {
        let score = 0;
        const reasons: string[] = [];

        if (career.mbtiTypes.includes(mbtiType)) {
          score += 35;
          reasons.push(`MBTI ${mbtiType} khá phù hợp với ngành này`);
        }

        for (const group of career.interestGroups) {
          if (topGroupKeys.includes(group)) {
            score += 22;
            reasons.push(`Bạn nổi trội ở nhóm ${this.groupLabels[group].toLowerCase()}`);
          }
        }

        for (const abilityKey of career.abilityKeys) {
          if (topAbilityKeys.includes(abilityKey)) {
            score += 15;
            reasons.push(`Bạn có năng lực mạnh ở ${this.abilityLabels[abilityKey].toLowerCase()}`);
          }
        }

        return {
          ...career,
          score,
          reasons: reasons.slice(0, 3)
        };
      })
      .sort((a, b) => (b.score || 0) - (a.score || 0))
      .slice(0, 5);
  }

  getSuggestedSchools(detail: TestHistoryDetail | null): string[] {
    const careers = this.getSuggestedCareers(detail);
    const schoolSet = new Set<string>();

    for (const career of careers) {
      for (const school of career.schools) {
        schoolSet.add(school);
      }
    }

    return Array.from(schoolSet).slice(0, 8);
  }

  radarDataFromDetail(detail: TestHistoryDetail | null): RadarDatum[] {
    if (!detail) return [];

    const cached = detail.result_payload?.combined_chart_data;

    if (Array.isArray(cached) && cached.length) {
      return cached.map((item: any) => ({
        key: item.key as RadarAxisKey,
        label: item.label,
        interestValue: this.toPercentScale(Number(item.interestRaw || 0)),
        abilityValue: this.toPercentScale(Number(item.abilityRaw || 0)),
      }));
    }

    const g = this.getInterestGroupScores(detail);
    const a = this.getAbilityScores(detail);

    const abilityRows = {
      creative: Number(a['CREATIVE'] || 0),
      analytic: Number((a['LOGIC'] || 0) + (a['TECH'] || 0)),
      communication: Number((a['LANGUAGE'] || 0) + (a['TEAMWORK'] || 0)),
      leadership: Number(a['LEADERSHIP'] || 0),
      technology: Number((a['TECH'] || 0) + (a['PRACTICAL'] || 0)),
      strategy: Number((a['STRATEGIC'] || 0) + (a['ADAPT'] || 0)),
    };

    const totalAbility =
      Object.values(abilityRows).reduce((sum, value) => sum + value, 0) || 1;

    return [
      {
        key: 'creative',
        label: this.radarLabels.creative,
        interestValue: this.toPercentScale(Number(g.creative || 0)),
        abilityValue: this.toPercentScale(Math.round((abilityRows.creative / totalAbility) * 100)),
      },
      {
        key: 'analytic',
        label: this.radarLabels.analytic,
        interestValue: this.toPercentScale(Number(g.analytic || 0)),
        abilityValue: this.toPercentScale(Math.round((abilityRows.analytic / totalAbility) * 100)),
      },
      {
        key: 'communication',
        label: this.radarLabels.communication,
        interestValue: this.toPercentScale(Number(g.social || 0)),
        abilityValue: this.toPercentScale(Math.round((abilityRows.communication / totalAbility) * 100)),
      },
      {
        key: 'leadership',
        label: this.radarLabels.leadership,
        interestValue: this.toPercentScale(Number(g.business || 0)),
        abilityValue: this.toPercentScale(Math.round((abilityRows.leadership / totalAbility) * 100)),
      },
      {
        key: 'technology',
        label: this.radarLabels.technology,
        interestValue: this.toPercentScale(Number(g.analytic || 0)),
        abilityValue: this.toPercentScale(Math.round((abilityRows.technology / totalAbility) * 100)),
      },
      {
        key: 'strategy',
        label: this.radarLabels.strategy,
        interestValue: this.toPercentScale(Number(g.business || 0)),
        abilityValue: this.toPercentScale(Math.round((abilityRows.strategy / totalAbility) * 100)),
      },
    ];
  }

  private toPercentScale(value: number): number {
    if (!Number.isFinite(value) || value <= 0) return 0;

    return Math.min(1, value / 50);
  }

  combinedChartDataFromDetail(detail: TestHistoryDetail | null): Array<{
    key: RadarAxisKey;
    label: string;
    interestRaw: number;
    abilityRaw: number;
    interestBarPercent: number;
    abilityBarPercent: number;
  }> {
    return this.radarDataFromDetail(detail).map((item) => {
      const interestRaw = Math.round((item.interestValue || 0) * 50);
      const abilityRaw = Math.round((item.abilityValue || 0) * 50);
      return {
        key: item.key,
        label: item.label,
        interestRaw,
        abilityRaw,
        interestBarPercent: Math.min(100, (interestRaw / 50) * 100),
        abilityBarPercent: Math.min(100, (abilityRaw / 50) * 100),
      };
    });
  }

  radarInterestNodesFromDetail(detail: TestHistoryDetail | null): Array<{ x: number; y: number }> {
    const data = this.radarDataFromDetail(detail);
    const count = data.length;

    return data.map((item, index) => {
      const angle = this.getAngle(index, count);
      const scale = Math.max(item.interestValue || 0, item.abilityValue || 0, 0.18);

      return {
        x: this.pointX(angle, scale),
        y: this.pointY(angle, scale),
      };
    });
  }

  topAbilitiesFromDetail(detail: TestHistoryDetail | null): Array<{
    label: string;
    percent?: number;
    description: string;
  }> {
    const payloadTop = detail?.result_payload?.top_abilities;

    if (Array.isArray(payloadTop) && payloadTop.length) {
      return payloadTop.slice(0, 3).map((item: any) => {
        if (typeof item === 'string') {
          return {
            label: item,
            description: 'Đây là một năng lực nổi bật trong hồ sơ định hướng của bạn.'
          };
        }

        return {
          label: String(item?.title ?? item?.label ?? '').trim(),
          percent: Number(item?.percent ?? 0),
          description: String(
            item?.description ??
            'Đây là một năng lực nổi bật trong hồ sơ định hướng của bạn.'
          ).trim()
        };
      }).filter((item: any) => item.label);
    }

    const abilityScores = this.getAbilityScores(detail);

    const descriptions: Record<string, string> = {
      LANGUAGE: 'Bạn mạnh về diễn đạt, viết, nói và truyền tải ý tưởng.',
      LOGIC: 'Bạn mạnh về tư duy phân tích, lập luận và nhìn ra cấu trúc của vấn đề.',
      CREATIVE: 'Bạn có khả năng sáng tạo, tạo ý tưởng mới và nhìn vấn đề theo nhiều hướng.',
      TECH: 'Bạn có xu hướng làm việc tốt với công nghệ, công cụ và hệ thống.',
      LEADERSHIP: 'Bạn có tố chất dẫn dắt, định hướng và tổ chức nhóm.',
      TEAMWORK: 'Bạn phối hợp tốt với người khác và thích môi trường làm việc nhóm.',
      DETAIL: 'Bạn chú ý chi tiết, cẩn thận và có xu hướng hạn chế sai sót.',
      ADAPT: 'Bạn linh hoạt, dễ thích nghi và xử lý tốt khi tình huống thay đổi.',
      PRACTICAL: 'Bạn thiên về thực tế, thao tác cụ thể và giải quyết vấn đề bằng hành động.',
      STRATEGIC: 'Bạn có xu hướng nhìn dài hạn, định hướng mục tiêu và lên kế hoạch tốt.',
    };

    return Object.entries(abilityScores)
      .sort((a, b) => Number(b[1]) - Number(a[1]))
      .slice(0, 3)
      .map(([key, value]) => ({
        label: this.abilityLabels[key as AbilityKey] || key,
        percent: Number(value || 0),
        description: descriptions[key] || 'Đây là một năng lực nổi bật trong hồ sơ định hướng của bạn.',
      }));
  }

  radarInterestPointsFromDetail(detail: TestHistoryDetail | null): string {
    return this.buildRadarPoints(this.radarDataFromDetail(detail).map(item => item.interestValue));
  }

  radarAbilityPointsFromDetail(detail: TestHistoryDetail | null): string {
    return this.buildRadarPoints(this.radarDataFromDetail(detail).map(item => item.abilityValue));
  }

  radarAxesFromDetail(detail: TestHistoryDetail | null): Array<{ x1: number; y1: number; x2: number; y2: number }> {
    const data = this.radarDataFromDetail(detail);
    const count = data.length;

    return data.map((_, index) => {
      const angle = this.getAngle(index, count);
      return {
        x1: this.svgCenter,
        y1: this.svgCenter,
        x2: this.pointX(angle, 1),
        y2: this.pointY(angle, 1)
      };
    });
  }

  radarGridPolygonsFromDetail(detail: TestHistoryDetail | null): string[] {
    const data = this.radarDataFromDetail(detail);
    return [0.2, 0.4, 0.6, 0.8, 1].map(scale =>
      this.buildRadarPoints(new Array(data.length).fill(scale))
    );
  }

  radarLabelPositionsFromDetail(detail: TestHistoryDetail | null): Array<{ label: string; x: number; y: number }> {
    const data = this.radarDataFromDetail(detail);
    const count = data.length;

    return data.map((item, index) => {
      const angle = this.getAngle(index, count);
      return {
        label: item.label,
        x: this.pointX(angle, 1.18),
        y: this.pointY(angle, 1.18)
      };
    });
  }

  private normalizeInterest(value: number, max: number): number {
    if (!max) return 0;
    return Math.max(0, Math.min(1, value / max));
  }

  private normalizeAbility(value: number, max: number): number {
    if (!max) return 0;
    return Math.max(0, Math.min(1, value / max));
  }

  private getAngle(index: number, count: number): number {
    return (-90 + (360 / count) * index) * (Math.PI / 180);
  }

  private pointX(angle: number, scale: number): number {
    return this.svgCenter + Math.cos(angle) * this.svgRadius * scale;
  }

  private pointY(angle: number, scale: number): number {
    return this.svgCenter + Math.sin(angle) * this.svgRadius * scale;
  }

  private buildRadarPoints(values: number[]): string {
    const count = values.length;

    return values
      .map((value, index) => {
        const angle = this.getAngle(index, count);
        return `${this.pointX(angle, value)},${this.pointY(angle, value)}`;
      })
      .join(' ');
  }

  trackByTestHistory(index: number, item: TestHistoryItem): number {
    return item.id;
  }

  trackByLessonHistory(index: number, item: LessonHistoryItem): string {
    return `${item.lessonId}-${item.updatedAt}`;
  }

  formatDate(date: string): string {
    if (!date) return '';
    return new Date(date).toLocaleString('vi-VN');
  }

  get avatarLetter(): string {
    return this.user?.name?.trim()?.charAt(0)?.toUpperCase() || 'U';
  }

  private getAuthHeaders(): Record<string, string> {
    const token =
      typeof window !== 'undefined'
        ? localStorage.getItem('auth_token')
        : null;

    return token
      ? {
          Authorization: `Bearer ${token}`,
          Accept: 'application/json',
          'Content-Type': 'application/json',
        }
      : {
          Accept: 'application/json',
          'Content-Type': 'application/json',
        };
  }

  private normalizeLessonHistory(item: any): LessonHistoryItem | null {
    const lessonId = Number(item?.lesson_id ?? item?.lessonId ?? 0);

    if (!lessonId) {
      return null;
    }

    const rawQuestions = Array.isArray(item?.questions) ? item.questions : [];

    const questions: LessonHistoryQuestionItem[] = rawQuestions.map((question: any) => {
      const selectedLabel = String(
        question?.selected_label ??
          question?.selectedLabel ??
          this.optionIndexToLabel(
            Number(
              question?.selected_option_index ??
                question?.selectedOptionIndex ??
                0
            )
          )
      ).toUpperCase();

      const rawOptions = Array.isArray(question?.options)
        ? question.options
        : [];

      return {
        questionId: String(
          question?.question_id ??
            question?.questionId ??
            question?.quiz_id ??
            ''
        ),
        question:
          question?.question ||
          question?.content ||
          question?.title ||
          'Câu hỏi chưa có nội dung',
        selectedLabel,
        selectedOptionIndex: Number(
          question?.selected_option_index ??
            question?.selectedOptionIndex ??
            this.labelToOptionIndex(selectedLabel)
        ),
        selectedOptionContent:
          question?.selected_option_content ||
          question?.selectedOptionContent ||
          '',
        isCorrect: Boolean(question?.is_correct ?? question?.isCorrect),
        answeredAt:
          question?.answered_at ||
          question?.answeredAt ||
          '',
        explanation:
          question?.explanation ||
          question?.description ||
          null,
        options: rawOptions.map((option: any, index: number) => ({
          label: option?.label || this.optionIndexToLabel(index),
          content:
            option?.content ||
            option?.answer ||
            option?.text ||
            option?.label ||
            'Đáp án chưa có nội dung',
          is_correct: Boolean(option?.is_correct ?? option?.isCorrect),
        })),
      };
    });

    return {
      lessonId,
      lessonTitle:
        item?.lesson_title ||
        item?.lessonTitle ||
        'Bài học',
      courseId: Number(item?.course_id ?? item?.courseId ?? 0),
      courseName:
        item?.course_name ||
        item?.courseName ||
        'Khóa học',
      updatedAt:
        item?.updated_at ||
        item?.updatedAt ||
        '',
      totalQuestions: Number(
        item?.total_questions ??
          item?.totalQuestions ??
          questions.length
      ),
      correctCount: Number(
        item?.correct_count ??
          item?.correctCount ??
          questions.filter((question) => question.isCorrect).length
      ),
      wrongCount: Number(
        item?.wrong_count ??
          item?.wrongCount ??
          questions.filter((question) => !question.isCorrect).length
      ),
      completed: Boolean(item?.completed),
      questions,
    };
  }

  private optionIndexToLabel(index: number): string {
    return ['A', 'B', 'C', 'D'][index] || 'A';
  }

  private labelToOptionIndex(label: string): number {
    const normalizedLabel = String(label || '').toUpperCase();
    const index = ['A', 'B', 'C', 'D'].indexOf(normalizedLabel);

    return index >= 0 ? index : 0;
  }

  getHistoryCareerSchools(career: any): any[] {
    const rawSchools = Array.isArray(career?.schools) ? career.schools : [];

    return rawSchools
      .map((school: any) => {
        if (typeof school === 'string') {
          return {
            id: 0,
            name: school,
            featured: false,
            imageUrl: '',
            city: '',
            majorName: career?.name || '',
            shortDescription: ''
          };
        }

        return {
          id: Number(school?.id ?? school?.admission_id ?? 0),
          name: String(
            school?.school_name ??
            school?.name ??
            school?.university_name ??
            school?.title ??
            ''
          ).trim(),
          featured:
            school?.featured === true ||
            school?.featured === 1 ||
            school?.featured === '1' ||
            school?.is_featured === true ||
            school?.is_featured === 1 ||
            school?.is_featured === '1',
          imageUrl: this.resolveHistorySchoolLogo(
            school?.image_url ??
            school?.logo_url ??
            school?.logoUrl ??
            school?.imageUrl ??
            school?.image ??
            school?.logo ??
            ''
          ),
          city: String(school?.city ?? '').trim(),
          majorName: String(school?.major_name ?? school?.majorName ?? career?.name ?? '').trim(),
          shortDescription: String(school?.short_description ?? school?.description ?? '').trim()
        };
      })
      .filter((school: any) => school.name)
      .slice(0, 5);
  }

  goToAdmissionFromHistory(school: any): void {
    this.router.navigate(['/admissions'], {
      queryParams: {
        focus: 1,
        admission_id: school?.id || '',
        school: school?.name || '',
        major: school?.majorName || ''
      }
    });
  }

  avatarUrl(): string {
    if (this.avatarPreview) return this.avatarPreview;

    const avatarUrl = this.user?.avatar_url;
    if (avatarUrl) return avatarUrl;

    const avatar = String(this.user?.avatar || '').trim();
    if (!avatar) return '';

    if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
      return avatar;
    }

    if (avatar.startsWith('/storage/')) {
      return `${API_ORIGIN}${avatar}`;
    }

    return `${STORAGE_URL}/${avatar}`;
  }

  onAvatarSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];

    if (!file) return;

    if (!file.type.startsWith('image/')) {
      this.profileError = 'Vui lòng chọn file hình ảnh.';
      return;
    }

    if (file.size > 2 * 1024 * 1024) {
      this.profileError = 'Ảnh đại diện không được vượt quá 2MB.';
      return;
    }

    this.avatarPreview = URL.createObjectURL(file);

    const formData = new FormData();
    formData.append('avatar', file);

    this.avatarUploading = true;
    this.profileMessage = '';
    this.profileError = '';

    const token = localStorage.getItem('auth_token');

    const headers: Record<string, string> = {
      Accept: 'application/json',
    };

    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    this.http.post<any>(`${API_URL}/me/avatar`, formData, {
      withCredentials: true,
      headers,
    }).pipe(
      finalize(() => {
        this.avatarUploading = false;
        this.cdr.detectChanges();
      })
    )
    .subscribe({
      next: (res) => {
    const updatedUser = {
      ...this.user,
      ...res.user,
      avatar: res.user?.avatar || this.user?.avatar,
      avatar_url: res.avatar_url || res.user?.avatar_url || ''
    };

    this.user = updatedUser;
    this.avatarPreview = updatedUser.avatar_url;

    localStorage.setItem('auth_user', JSON.stringify(updatedUser));

    this.api.user.set(updatedUser);

    Swal.fire({
      toast: true,
      position: 'top-end',
      icon: 'success',
      title: 'Cập nhật ảnh đại diện thành công',
      showConfirmButton: false,
      timer: 2000,
      timerProgressBar: true,
    });

    this.cdr.detectChanges();
      },
      error: (err) => {
        this.avatarPreview = '';
        this.profileError = err?.error?.message || 'Không thể cập nhật ảnh đại diện.';
        this.cdr.detectChanges();
      }
    });
  }

  getAccountPackageLabel(): string {
    const raw = String(
      this.user?.package_name ||
      this.user?.package?.name ||
      this.user?.role ||
      'free'
    ).toLowerCase();

    if (raw.includes('premium')) return 'Tài khoản Premium';
    if (raw.includes('plus')) return 'Tài khoản Plus';

    return 'Tài khoản miễn phí';
  }

  getAccountPackageClass(): string {
    const raw = String(
      this.user?.package_name ||
      this.user?.package?.name ||
      this.user?.role ||
      'free'
    ).toLowerCase();

    if (raw.includes('premium')) return 'premium';
    if (raw.includes('plus')) return 'plus';

    return 'free';
  }

  resolveHistorySchoolLogo(value: any): string {
    const raw = String(value ?? '').trim();
    if (!raw) return '';

    if (
      raw.startsWith('http://') ||
      raw.startsWith('https://') ||
      raw.startsWith('data:')
    ) {
      return raw;
    }

    const cleaned = raw.replace(/^\/+/, '');

    if (
      cleaned.startsWith('images/') ||
      cleaned.startsWith('assets/') ||
      cleaned.startsWith('storage/')
    ) {
      return `${API_ORIGIN}/${cleaned}`;
    }

    if (cleaned.startsWith('admissions/')) {
      return `${STORAGE_URL}/${cleaned}`;
    }

    if (!cleaned.includes('/')) {
      return `${STORAGE_URL}/admissions/${cleaned}`;
    }

    return `${STORAGE_URL}/${cleaned}`;
  }
  getHistoryMbtiRobotImage(detail: TestHistoryDetail | null): string {
    const type = this.getMbtiType(detail);
    return type && type !== '----'
      ? `/images/emoji2/${type}.png`
      : '/images/emoji2/INTP.png';
  }

  historyInterestCircleSegments(detail: TestHistoryDetail | null): CircularSegment[] {
    const scores = this.getInterestGroupScores(detail);

    const values: Array<{
      key: InterestGroupKey;
      labelLines: string[];
      percent: number;
    }> = [
      {
        key: 'creative',
        labelLines: ['Sáng tạo'],
        percent: Number(scores.creative || 0)
      },
      {
        key: 'analytic',
        labelLines: ['Phân tích -', 'Công nghệ'],
        percent: Number(scores.analytic || 0)
      },
      {
        key: 'business',
        labelLines: ['Kinh doanh -', 'Tổ chức'],
        percent: Number(scores.business || 0)
      },
      {
        key: 'social',
        labelLines: ['Con người -', 'Giao tiếp'],
        percent: Number(scores.social || 0)
      }
    ];

    const startAngle = -180;
    const sectorAngle = 90;

    return values.map((item, index) => {
      const start = startAngle + index * sectorAngle;
      const end = start + sectorAngle;
      const mid = start + sectorAngle / 2;
      const percent = this.clampOverviewPercent(item.percent);

      return {
        key: item.key,
        labelLines: item.labelLines,
        percent,
        areaPath: this.buildHistoryAnnularSectorPath(
          start + 1.2,
          end - 1.2,
          88,
          188
        ),
        progressPath: this.buildHistoryProgressArcPath(
          start + 4,
          end - 4,
          196,
          percent
        ),
        labelX: this.historyPolarPoint(mid, 139).x,
        labelY:
          this.historyPolarPoint(mid, 139).y -
          (item.labelLines.length > 1 ? 8 : 0)
      };
    });
  }

  historyAbilityCircleSegments(detail: TestHistoryDetail | null): CircularSegment[] {
    const scores = this.getAbilityScores(detail);

    const orderedKeys: AbilityKey[] = [
      'LANGUAGE',
      'LOGIC',
      'CREATIVE',
      'TECH',
      'LEADERSHIP',
      'TEAMWORK',
      'DETAIL',
      'ADAPT',
      'PRACTICAL',
      'STRATEGIC'
    ];

    const labelLines: Record<AbilityKey, string[]> = {
      LANGUAGE: ['Ngôn ngữ'],
      LOGIC: ['Tư duy logic'],
      CREATIVE: ['Sáng tạo'],
      TECH: ['Công nghệ'],
      LEADERSHIP: ['Lãnh đạo'],
      TEAMWORK: ['Làm việc nhóm'],
      DETAIL: ['Chi tiết -', 'Cẩn thận'],
      ADAPT: ['Thích nghi'],
      PRACTICAL: ['Thực hành'],
      STRATEGIC: ['Chiến lược']
    };

    const startAngle = -108;
    const sectorAngle = 36;

    return orderedKeys.map((key, index) => {
      const start = startAngle + index * sectorAngle;
      const end = start + sectorAngle;
      const mid = start + sectorAngle / 2;
      const percent = this.clampOverviewPercent(Number(scores[key] || 0));

      return {
        key,
        labelLines: labelLines[key],
        percent,
        areaPath: this.buildHistoryAnnularSectorPath(
          start + 0.9,
          end - 0.9,
          208,
          282
        ),
        progressPath: this.buildHistoryProgressArcPath(
          start + 3,
          end - 3,
          291,
          percent
        ),
        labelX: this.historyPolarPoint(mid, 244).x,
        labelY:
          this.historyPolarPoint(mid, 244).y -
          (labelLines[key].length > 1 ? 7 : 0)
      };
    });
  }

  formatPercent(value: number): string {
    const rounded = Number(this.clampOverviewPercent(value).toFixed(1));

    return Number.isInteger(rounded)
      ? String(rounded)
      : rounded.toFixed(1);
  }

  private clampOverviewPercent(value: number): number {
    if (!Number.isFinite(value)) return 0;
    return Math.max(0, Math.min(100, value));
  }

  private historyPolarPoint(
    angleDegrees: number,
    radius: number
  ): { x: number; y: number } {
    const angle = angleDegrees * (Math.PI / 180);

    return {
      x: this.overviewCenter + Math.cos(angle) * radius,
      y: this.overviewCenter + Math.sin(angle) * radius
    };
  }

  private buildHistoryAnnularSectorPath(
    startAngle: number,
    endAngle: number,
    innerRadius: number,
    outerRadius: number
  ): string {
    const outerStart = this.historyPolarPoint(startAngle, outerRadius);
    const outerEnd = this.historyPolarPoint(endAngle, outerRadius);
    const innerEnd = this.historyPolarPoint(endAngle, innerRadius);
    const innerStart = this.historyPolarPoint(startAngle, innerRadius);
    const largeArcFlag = endAngle - startAngle > 180 ? 1 : 0;

    return [
      `M ${outerStart.x} ${outerStart.y}`,
      `A ${outerRadius} ${outerRadius} 0 ${largeArcFlag} 1 ${outerEnd.x} ${outerEnd.y}`,
      `L ${innerEnd.x} ${innerEnd.y}`,
      `A ${innerRadius} ${innerRadius} 0 ${largeArcFlag} 0 ${innerStart.x} ${innerStart.y}`,
      'Z'
    ].join(' ');
  }

  private buildHistoryProgressArcPath(
    startAngle: number,
    endAngle: number,
    radius: number,
    percent: number
  ): string {
    const safePercent = this.clampOverviewPercent(percent);

    if (safePercent <= 0) return '';

    const progressEnd =
      startAngle + (endAngle - startAngle) * (safePercent / 100);

    const start = this.historyPolarPoint(startAngle, radius);
    const end = this.historyPolarPoint(progressEnd, radius);
    const largeArcFlag = progressEnd - startAngle > 180 ? 1 : 0;

    return [
      `M ${start.x} ${start.y}`,
      `A ${radius} ${radius} 0 ${largeArcFlag} 1 ${end.x} ${end.y}`
    ].join(' ');
  }

}