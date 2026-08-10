import {
  Component,
  OnInit,
  OnDestroy,
  ElementRef,
  ViewChild,
  NgZone,
  ChangeDetectorRef,
} from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Router, RouterModule } from '@angular/router';
import { finalize } from 'rxjs/operators';
import { ResultApiService } from '../../services/result-api.service';
import {
  PackageAdminService,
  TestPackage,
} from '../../features/admin/services/package-admin.service';
import { UserPortalService } from '../../services/user-portal.service';
import * as QRCode from 'qrcode';

type MbtiAxis = 'E/I' | 'S/N' | 'T/F' | 'J/P';

type MbtiQuestionApiItem = {
  id?: number;
  order?: number;

  question?: string;
  content?: string;

  optionA?: string;
  optionB?: string;
  option_a?: string;
  option_b?: string;
  label_a?: string;
  label_b?: string;

  axis?: string;
  axisLabel?: string;
  axis_label?: string;

  dirA?: string;
  dirB?: string;
  dir_a?: string;
  dir_b?: string;

  package_type?: string;
  packageType?: string;
};

type MbtiQuestionsResponse = {
  questions?: MbtiQuestionApiItem[];
  data?: MbtiQuestionApiItem[];
  items?: MbtiQuestionApiItem[];
};

type MbtiQuestion = {
  id: number;
  order: number;

  question: string;
  optionA: string;
  optionB: string;

  axis: MbtiAxis;
  axisLabel?: string;

  dirA: 'E' | 'S' | 'T' | 'J' | 'I' | 'N' | 'F' | 'P';
  dirB: 'E' | 'S' | 'T' | 'J' | 'I' | 'N' | 'F' | 'P';

  section?: 'mbti';
};

type AbilityQuestion = {
  id: number;
  order: number;

  question: string;
  optionA: string;
  optionB: string;

  axis: string;
  axisLabel?: string;

  dirA?: string;
  dirB?: string;

  section?: 'ability';
};

type TestQuestion = MbtiQuestion | AbilityQuestion;

type MbtiResult = {
  type: string;
  scores: {
    E: number;
    I: number;
    S: number;
    N: number;
    T: number;
    F: number;
    J: number;
    P: number;
  };
};

type UpgradePlanKey = 'interest' | 'combo';

type UpgradePackage = {
  id: number;
  name: string;
  subtitle: string;
  description: string;
  price: number;
  priceLabel: string;
  chipText: string;
  selectedText: string;
  kind: UpgradePlanKey;
  themeClass: string;
  qrSrc: string;
  sortOrder: number;
  raw?: TestPackage;
};

type TestMode = 'free' | 'basic_package' | 'full_package';
type UserRole = 'premium' | 'user' | 'student' | string | null;

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

type AbilityScores = Record<AbilityKey, number>;
type InterestGroupKey = 'creative' | 'analytic' | 'social' | 'business';
type QuestionPackageType = 'free' | 'plus' | 'premium';

@Component({
  selector: 'app-mbti-test',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './mbti-test.html',
  styleUrl: './mbti-test.css',
})
export class MbtiTest implements OnInit, OnDestroy {
  @ViewChild('adVideo') adVideoRef?: ElementRef<HTMLVideoElement>;

  toastMessage = '';
  showToast = false;
  private toastTimer: ReturnType<typeof setTimeout> | null = null;

  readonly pageSize = 10;
  readonly maxAdSeconds = 30;
  readonly adVideoSrc = '/images/quangcao1.mp4';
  readonly mbtiQuestionsApiUrl = '/api/mbti/questions';

  currentPage = 1;
  pageError = '';

  answers: Record<number, 'A' | 'B'> = {};

  showUpgradeModal = false;
  showPaymentModal = false;
  showAdModal = false;

  paymentQrSrc = '';
  paymentCheckoutUrl = '';
  paymentOrderCode: number | null = null;
  paymentStatus: 'PENDING' | 'PAID' | 'PROCESSING' | 'CANCELLED' | 'EXPIRED' | '' = '';
  paymentCreating = false;
  paymentChecking = false;

  selectedPackageId: number | null = null;

  upgradePackages: UpgradePackage[] = [];
  loadingPackages = false;
  packageError = '';

  currentUserPackage: TestPackage | null = null;
  currentUserRole: UserRole = null;
  loadingUserRole = false;

  testMode: TestMode = 'free';

  plusQuestions: AbilityQuestion[] = [];
  loadingPlusQuestions = false;
  plusQuestionsError = '';

  premiumQuestions: AbilityQuestion[] = [];
  loadingPremiumQuestions = false;
  premiumQuestionsError = '';

  adCountdown = 0;
  adDuration = 0;
  adReady = false;
  adStarted = false;
  adErrorMessage = '';

  loadingQuestions = false;
  questionsError = '';

  private adFinished = false;
  private fallbackTimer: ReturnType<typeof setInterval> | null = null;
  private paymentPollTimer: ReturnType<typeof setInterval> | null = null;

  mbtiQuestions: MbtiQuestion[] = [];
  questions: TestQuestion[] = [];

  constructor(
    private http: HttpClient,
    private router: Router,
    private ngZone: NgZone,
    private cdr: ChangeDetectorRef,
    private resultApi: ResultApiService,
    private packageAdminService: PackageAdminService,
    private userPortal: UserPortalService,
  ) {}

  ngOnInit(): void {
    this.loadingQuestions = true;
    this.questionsError = '';

    this.userPortal.getOrCreateTestSessionId();
    this.loadUpgradePackages();
    this.loadCurrentUserRoleAndMode();
    this.loadMbtiQuestions();

    if (typeof window !== 'undefined') {
      setTimeout(() => {
        this.restorePendingUpgradeFlow();
      }, 400);
    }
  }

  ngOnDestroy(): void {
    this.stopPaymentPolling();

    if (this.fallbackTimer) {
      clearInterval(this.fallbackTimer);
      this.fallbackTimer = null;
    }

    if (this.toastTimer) {
      clearTimeout(this.toastTimer);
      this.toastTimer = null;
    }
  }

  private showSuccessToast(message: string): void {
    this.toastMessage = message;
    this.showToast = true;

    if (this.toastTimer) {
      clearTimeout(this.toastTimer);
      this.toastTimer = null;
    }

    this.toastTimer = setTimeout(() => {
      this.showToast = false;
      this.toastMessage = '';
    }, 2600);
  }

  closeToast(): void {
    this.showToast = false;
    this.toastMessage = '';

    if (this.toastTimer) {
      clearTimeout(this.toastTimer);
      this.toastTimer = null;
    }
  }

  private restorePurchasedStateFromStorage(): boolean {
    if (typeof window === 'undefined') return false;

    const token = localStorage.getItem('auth_token');
    if (!token) return false;

    try {
      const rawUpgrades = localStorage.getItem('selected_upgrades');
      const rawPackage = localStorage.getItem('selected_package');

      if (!rawUpgrades) return false;

      const upgrades = JSON.parse(rawUpgrades);
      const storedPackage = rawPackage ? JSON.parse(rawPackage) : null;

      if (upgrades?.ability && upgrades?.paid === true) {
        this.testMode = 'full_package';
        this.currentUserRole = 'premium';

        if (storedPackage) {
          this.currentUserPackage = storedPackage;
        }

        return true;
      }

      if (upgrades?.interest && upgrades?.paid === true) {
        this.testMode = 'basic_package';

        if (storedPackage) {
          this.currentUserPackage = storedPackage;
        }

        return true;
      }

      return false;
    } catch {
      return false;
    }
  }

  private restorePendingUpgradeFlow(): void {
    if (typeof window === 'undefined') return;

    const shouldReturn = localStorage.getItem('return_after_login_upgrade');
    const pendingPackageId = localStorage.getItem('pending_upgrade_package_id');
    const token = localStorage.getItem('auth_token');

    if (shouldReturn !== '1' || !pendingPackageId || !token) {
      return;
    }

    const packageId = Number(pendingPackageId);
    if (!packageId) {
      localStorage.removeItem('return_after_login_upgrade');
      localStorage.removeItem('pending_upgrade_package_id');
      localStorage.removeItem('pending_upgrade_plan_kind');
      return;
    }

    const pkg = this.upgradePackages.find((item) => item.id === packageId);
    if (!pkg) return;

    this.selectedPackageId = pkg.id;
    this.packageError = '';
    this.showUpgradeModal = true;
    this.showPaymentModal = false;
    this.cdr.detectChanges();

    this.continueWithUpgrades();

    setTimeout(() => {
      localStorage.removeItem('return_after_login_upgrade');
    }, 1000);
  }

  private getAuthHeaders(): HttpHeaders {
    const token = typeof window !== 'undefined' ? localStorage.getItem('auth_token') : null;

    if (!token) return new HttpHeaders();

    return new HttpHeaders({
      Authorization: `Bearer ${token}`,
      Accept: 'application/json',
    });
  }

  private normalizeDirection(
    value: unknown
  ): 'E' | 'I' | 'S' | 'N' | 'T' | 'F' | 'J' | 'P' | null {
    const direction = String(value ?? '')
      .trim()
      .toUpperCase();

    if (
      direction === 'E' ||
      direction === 'I' ||
      direction === 'S' ||
      direction === 'N' ||
      direction === 'T' ||
      direction === 'F' ||
      direction === 'J' ||
      direction === 'P'
    ) {
      return direction;
    }

    return null;
  }

  private normalizeAxis(
    axis: unknown,
    dirA?: unknown,
    dirB?: unknown
  ): MbtiAxis | null {
    const left = this.normalizeDirection(dirA);
    const right = this.normalizeDirection(dirB);

    // Ưu tiên dir_a và dir_b vì đây là mã ổn định trong DB.
    if (left && right) {
      const pair = `${left}/${right}`;

      if (pair === 'E/I' || pair === 'I/E') return 'E/I';
      if (pair === 'S/N' || pair === 'N/S') return 'S/N';
      if (pair === 'T/F' || pair === 'F/T') return 'T/F';
      if (pair === 'J/P' || pair === 'P/J') return 'J/P';
    }

    const value = String(axis ?? '')
      .trim()
      .replace(/\s+/g, ' ')
      .toLocaleLowerCase('vi-VN');

    if (
      value === 'ei' ||
      value === 'e/i' ||
      value === 'hướng ngoại / hướng nội'
    ) {
      return 'E/I';
    }

    if (
      value === 'sn' ||
      value === 's/n' ||
      value === 'giác quan / trực giác'
    ) {
      return 'S/N';
    }

    if (
      value === 'tf' ||
      value === 't/f' ||
      value === 'lý trí / cảm xúc'
    ) {
      return 'T/F';
    }

    if (
      value === 'jp' ||
      value === 'j/p' ||
      value === 'nguyên tắc / linh hoạt'
    ) {
      return 'J/P';
    }

    return null;
  }

  private extractQuestionList(response: any): any[] {
    if (Array.isArray(response?.questions)) {
      return response.questions;
    }

    if (Array.isArray(response?.data)) {
      return response.data;
    }

    if (Array.isArray(response?.items)) {
      return response.items;
    }

    if (Array.isArray(response)) {
      return response;
    }

    return [];
  }

  private mapApiQuestion(
    item: MbtiQuestionApiItem
  ): MbtiQuestion | null {
    const id = Number(item?.id ?? 0);
    const order = Number(item?.order ?? id);

    const question = String(
      item?.question ??
      item?.content ??
      ''
    ).trim();

    const optionA = String(
      item?.optionA ??
      item?.option_a ??
      item?.label_a ??
      ''
    ).trim();

    const optionB = String(
      item?.optionB ??
      item?.option_b ??
      item?.label_b ??
      ''
    ).trim();

    const rawDirA =
      item?.dirA ??
      item?.dir_a ??
      '';

    const rawDirB =
      item?.dirB ??
      item?.dir_b ??
      '';

    const dirA = this.normalizeDirection(rawDirA);
    const dirB = this.normalizeDirection(rawDirB);

    const axis = this.normalizeAxis(
      item?.axis,
      dirA,
      dirB
    );

    const axisLabel = String(
      item?.axisLabel ??
      item?.axis_label ??
      item?.axis ??
      axis ??
      ''
    ).trim();

    if (
      !id ||
      !order ||
      !question ||
      !optionA ||
      !optionB ||
      !dirA ||
      !dirB ||
      !axis
    ) {
      console.warn('Câu MBTI bị loại khi map:', {
        item,
        id,
        order,
        question,
        optionA,
        optionB,
        dirA,
        dirB,
        axis
      });

      return null;
    }

    return {
      id,
      order,
      question,
      optionA,
      optionB,
      axis,
      axisLabel,
      dirA,
      dirB,
      section: 'mbti'
    };
  }

  private mapAbilityApiQuestion(
    item: any
  ): AbilityQuestion | null {
    const rawId = Number(
      item?.id ??
      item?.question_id ??
      0
    );

    const order = Number(
      item?.order ??
      rawId
    );

    const packageType = String(
      item?.package_type ??
      item?.packageType ??
      ''
    )
      .trim()
      .toLowerCase();

    let id = rawId;

    // ID nội bộ dùng để tránh trùng đáp án.
    // Số câu hiển thị vẫn sử dụng order trong DB.
    if (packageType === 'plus') {
      id = 100000 + rawId;
    }

    if (packageType === 'premium') {
      id = 200000 + rawId;
    }

    const question = String(
      item?.question ??
      item?.content ??
      item?.title ??
      ''
    ).trim();

    const optionA = String(
      item?.optionA ??
      item?.option_a ??
      item?.label_a ??
      item?.a_label ??
      item?.answer_a ??
      ''
    ).trim();

    const optionB = String(
      item?.optionB ??
      item?.option_b ??
      item?.label_b ??
      item?.b_label ??
      item?.answer_b ??
      ''
    ).trim();

    const dirA = String(
      item?.dirA ??
      item?.dir_a ??
      ''
    )
      .trim()
      .toUpperCase();

    const dirB = String(
      item?.dirB ??
      item?.dir_b ??
      ''
    )
      .trim()
      .toUpperCase();

    const rawAxis = String(
      item?.axisLabel ??
      item?.axis_label ??
      item?.axis ??
      ''
    ).trim();

    // Mã dùng để tính điểm.
    const axis =
      dirA && dirB
        ? `${dirA}/${dirB}`
        : rawAxis.toUpperCase();

    // Tên tiếng Việt dùng để hiển thị.
    const axisLabel = rawAxis || axis;

    if (
      !rawId ||
      !id ||
      !order ||
      !question ||
      !optionA ||
      !optionB ||
      !dirA ||
      !dirB
    ) {
      console.warn('Câu Plus/Premium bị loại khi map:', {
        item,
        rawId,
        id,
        order,
        question,
        optionA,
        optionB,
        dirA,
        dirB
      });

      return null;
    }

    return {
      id,
      order,
      question,
      optionA,
      optionB,
      axis,
      axisLabel,
      dirA,
      dirB,
      section: 'ability'
    };
  }

  private readPaymentString(obj: any, keys: string[]): string {
    for (const key of keys) {
      const value = key.split('.').reduce((acc: any, part: string) => acc?.[part], obj);
      const text = String(value ?? '').trim();
      if (text) return text;
    }
    return '';
  }

  private readPaymentNumber(obj: any, keys: string[]): number | null {
    for (const key of keys) {
      const value = key.split('.').reduce((acc: any, part: string) => acc?.[part], obj);
      const num = Number(value);
      if (Number.isFinite(num) && num > 0) return num;
    }
    return null;
  }

  private async buildQrDataUrl(value: string): Promise<string> {
    const raw = String(value || '').trim();
    if (!raw) return '';

    return `https://api.qrserver.com/v1/create-qr-code/?size=280x280&data=${encodeURIComponent(raw)}`;
  }

  private resolveBestQrSource(qrRaw: string, checkoutRaw: string): string {
    if (qrRaw) return qrRaw;
    if (checkoutRaw) return checkoutRaw;
    return '';
  }

  loadMbtiQuestions(): void {
    this.loadingQuestions = true;
    this.questionsError = '';

    this.http
      .get<any>(
        `${this.mbtiQuestionsApiUrl}?package_type=free`
      )
      .subscribe({
        next: (res: any) => {
          this.loadingQuestions = false;

          const rawList = this.filterQuestionsByPackage(
            res,
            'free'
          );

          console.log('FREE RAW QUESTIONS:', rawList);

          this.mbtiQuestions = rawList
            .map((item: MbtiQuestionApiItem) =>
              this.mapApiQuestion(item)
            )
            .filter(
              (
                item: MbtiQuestion | null
              ): item is MbtiQuestion => item !== null
            );

          console.log(
            'FREE MAPPED QUESTIONS:',
            this.mbtiQuestions
          );

          if (!this.mbtiQuestions.length) {
            this.questionsError =
              'API trả dữ liệu nhưng frontend không đọc được cấu trúc câu hỏi.';

            this.questions = [];
            this.currentPage = 1;
            this.cdr.detectChanges();
            return;
          }

          this.restoreDraftAnswers();
          this.rebuildQuestionFlow();
          this.restoreDraftPage();

          this.pageError = '';
          this.questionsError = '';
          this.cdr.detectChanges();
        },

        error: (error) => {
          console.error(
            'LOAD MBTI QUESTIONS ERROR:',
            error
          );

          this.loadingQuestions = false;
          this.mbtiQuestions = [];
          this.questions = [];
          this.currentPage = 1;

          this.questionsError =
            'Không tải được bộ câu hỏi MBTI từ Admin.';

          this.cdr.detectChanges();
        }
      });
  }

  private loadPlusQuestions(
    callback?: () => void
  ): void {
    this.loadingPlusQuestions = true;
    this.plusQuestionsError = '';

    this.http
      .get<any>(
        `${this.mbtiQuestionsApiUrl}?package_type=plus`
      )
      .pipe(
        finalize(() => {
          this.loadingPlusQuestions = false;
        })
      )
      .subscribe({
        next: (res: any) => {
          const rawList = this.filterQuestionsByPackage(
            res,
            'plus'
          );

          console.log(
            'PLUS RAW QUESTIONS:',
            rawList
          );

          this.plusQuestions = rawList
            .map((item: any) =>
              this.mapAbilityApiQuestion({
                ...item,
                package_type: 'plus'
              })
            )
            .filter(
              (
                item: AbilityQuestion | null
              ): item is AbilityQuestion =>
                item !== null
            );

          console.log(
            'PLUS MAPPED QUESTIONS:',
            this.plusQuestions
          );

          if (!this.plusQuestions.length) {
            this.plusQuestionsError =
              'Không có câu hỏi Plus từ Admin.';
          } else {
            this.plusQuestionsError = '';
          }

          this.rebuildQuestionFlow();
          this.cdr.detectChanges();

          callback?.();
        },

        error: (error) => {
          console.error(
            'LOAD PLUS QUESTIONS ERROR:',
            error
          );

          this.plusQuestions = [];
          this.plusQuestionsError =
            'Không tải được câu hỏi Plus.';

          this.rebuildQuestionFlow();
          this.cdr.detectChanges();

          callback?.();
        }
      });
  }

  private loadPremiumQuestions(
    callback?: () => void
  ): void {
    this.loadingPremiumQuestions = true;
    this.premiumQuestionsError = '';

    this.http
      .get<any>(
        `${this.mbtiQuestionsApiUrl}?package_type=premium`
      )
      .pipe(
        finalize(() => {
          this.loadingPremiumQuestions = false;
        })
      )
      .subscribe({
        next: (res: any) => {
          const rawList = this.filterQuestionsByPackage(
            res,
            'premium'
          );

          console.log(
            'PREMIUM RAW QUESTIONS:',
            rawList
          );

          this.premiumQuestions = rawList
            .map((item: any) =>
              this.mapAbilityApiQuestion({
                ...item,
                package_type: 'premium'
              })
            )
            .filter(
              (
                item: AbilityQuestion | null
              ): item is AbilityQuestion =>
                item !== null
            );

          console.log(
            'PREMIUM MAPPED QUESTIONS:',
            this.premiumQuestions
          );

          if (!this.premiumQuestions.length) {
            this.premiumQuestionsError =
              'Không có câu hỏi Premium từ Admin.';
          } else {
            this.premiumQuestionsError = '';
          }

          this.rebuildQuestionFlow();
          this.cdr.detectChanges();

          callback?.();
        },

        error: (error) => {
          console.error(
            'LOAD PREMIUM QUESTIONS ERROR:',
            error
          );

          this.premiumQuestions = [];
          this.premiumQuestionsError =
            'Không tải được câu hỏi Premium.';

          this.rebuildQuestionFlow();
          this.cdr.detectChanges();

          callback?.();
        }
      });
  }

  private loadFullPackageQuestions(callback?: () => void): void {
    this.loadPlusQuestions(() => {
      this.loadPremiumQuestions(() => {
        this.rebuildQuestionFlow();
        this.cdr.detectChanges();

        if (callback) callback();
      });
    });
  }

  private getDraftStorageKey(): string {
    if (typeof window === 'undefined') {
      return 'mbti_answers_draft_guest';
    }

    const sessionId = this.userPortal.getOrCreateTestSessionId();
    return `mbti_answers_draft_${sessionId}`;
  }

  private getDraftPageStorageKey(): string {
    return `${this.getDraftStorageKey()}__page`;
  }

  private restoreDraftPage(): void {
    if (typeof window === 'undefined') return;

    const raw = localStorage.getItem(this.getDraftPageStorageKey());
    const page = Number(raw || 1);

    if (!Number.isFinite(page) || page < 1) {
      this.currentPage = 1;
      return;
    }

    this.currentPage = Math.min(page, this.totalPages || 1);
  }

  private persistDraftPage(): void {
    if (typeof window === 'undefined') return;
    localStorage.setItem(this.getDraftPageStorageKey(), String(this.currentPage));
  }

  private getValidQuestionIds(): Set<number> {
    return new Set([
      ...this.mbtiQuestions.map((q) => q.id),
      ...this.plusQuestions.map((q) => q.id),
      ...this.premiumQuestions.map((q) => q.id),
    ]);
  }

  private rebuildQuestionFlow(): void {
    let selectedQuestions: TestQuestion[] = [];

    if (this.testMode === 'full_package') {
      selectedQuestions = [
        ...this.mbtiQuestions,
        ...this.plusQuestions,
        ...this.premiumQuestions
      ];
    } else if (this.testMode === 'basic_package') {
      selectedQuestions = [
        ...this.mbtiQuestions,
        ...this.plusQuestions
      ];
    } else {
      selectedQuestions = [
        ...this.mbtiQuestions
      ];
    }

    // Mỗi giá trị order chỉ được xuất hiện một lần.
    const uniqueByOrder =
      new Map<number, TestQuestion>();

    selectedQuestions.forEach((question) => {
      const order = Number(question.order ?? 0);

      if (
        Number.isFinite(order) &&
        order > 0 &&
        !uniqueByOrder.has(order)
      ) {
        uniqueByOrder.set(order, question);
      }
    });

    this.questions = Array
      .from(uniqueByOrder.values())
      .sort((a, b) => {
        const orderA = Number(a.order ?? 0);
        const orderB = Number(b.order ?? 0);

        if (orderA !== orderB) {
          return orderA - orderB;
        }

        return a.id - b.id;
      });

    const validIds = this.getValidQuestionIds();
    const cleanedAnswers:
      Record<number, 'A' | 'B'> = {};

    Object.entries(this.answers).forEach(
      ([key, value]) => {
        const questionId = Number(key);

        if (
          validIds.has(questionId) &&
          (value === 'A' || value === 'B')
        ) {
          cleanedAnswers[questionId] = value;
        }
      }
    );

    this.answers = cleanedAnswers;

    const maxPage = this.totalPages;

    if (this.currentPage > maxPage) {
      this.currentPage = maxPage || 1;
    }
  }

  private loadCurrentUserRoleAndMode(): void {
    if (typeof window === 'undefined') {
      this.currentUserRole = 'user';
      this.testMode = 'free';
      this.currentUserPackage = null;
      this.rebuildQuestionFlow();
      return;
    }

    const token = localStorage.getItem('auth_token');

    if (!token) {
      localStorage.removeItem('selected_upgrades');
      localStorage.removeItem('selected_package');
      localStorage.removeItem('pending_upgrade_package_id');
      localStorage.removeItem('pending_upgrade_plan_kind');
      localStorage.removeItem('return_after_login_upgrade');
      localStorage.removeItem('return_after_login_path');

      // FIX reset draft cũ
      Object.keys(localStorage).forEach((key) => {
        if (
          key.startsWith('mbti_answers_draft_') ||
          key.includes('__page')
        ) {
          localStorage.removeItem(key);
        }
      });

      this.answers = {};
      this.currentPage = 1;

      this.currentUserRole = 'user';
      this.testMode = 'free';
      this.currentUserPackage = null;

      this.rebuildQuestionFlow();
      return;
    }

    this.loadingUserRole = true;

    this.http
      .get<any>('/api/me', {
        headers: this.getAuthHeaders(),
        withCredentials: true,
      })
      .pipe(finalize(() => (this.loadingUserRole = false)))
      .subscribe({
        next: (user) => {
          const role = String(user?.user?.role || user?.role || '')
          .trim()
          .toLowerCase();

          this.currentUserRole = role || 'user';
          this.currentUserPackage = null;

          if (this.currentUserRole === 'premium') {
            this.testMode = 'full_package';
          } else if (this.currentUserRole === 'plus') {
            this.testMode = 'basic_package';
          } else {
            this.testMode = 'free';
          }

          if (this.testMode === 'full_package') {
            this.loadFullPackageQuestions(() => {
              this.rebuildQuestionFlow();
              this.cdr.markForCheck();
            });
          } else if (this.testMode === 'basic_package') {
            this.loadPlusQuestions(() => {
              this.rebuildQuestionFlow();
              this.cdr.markForCheck();
            });
          } else {
            this.rebuildQuestionFlow();
            this.cdr.markForCheck();
          }
        },
        error: () => {
          this.currentUserRole = 'user';
          this.testMode = 'free';
          this.currentUserPackage = null;
          this.rebuildQuestionFlow();
          this.cdr.markForCheck();
        },
      });
  }

  private normalizeTheme(theme: string | null | undefined, kind: UpgradePlanKey): string {
    const value = String(theme ?? '')
      .trim()
      .toLowerCase();

    if (value === 'orange') return 'orange';
    if (value === 'purple') return 'purple';
    if (value === 'blue') return 'blue';
    if (value === 'green') return 'green';
    if (value === 'premium') return 'purple';
    if (value === 'basic') return 'blue';

    return kind === 'combo' ? 'purple' : 'blue';
  }

  getThemeClass(pkg: UpgradePackage): string[] {
    return ['theme-' + pkg.themeClass];
  }

  get selectedPackage(): UpgradePackage | null {
    return this.upgradePackages.find((pkg) => pkg.id === this.selectedPackageId) ?? null;
  }

  get paymentTitle(): string {
    return this.selectedPackage
      ? `Thanh toán ${this.selectedPackage.name}`
      : 'Thanh toán gói nâng cao';
  }

  get paymentPrice(): string {
    return this.selectedPackage?.priceLabel || '';
  }

  get totalPages(): number {
    return this.questions.length ? Math.ceil(this.questions.length / this.pageSize) : 1;
  }

  get pagedQuestions(): TestQuestion[] {
    const start = (this.currentPage - 1) * this.pageSize;
    return this.questions.slice(start, start + this.pageSize);
  }

  get answeredCount(): number {
    return Object.keys(this.answers).length;
  }

  get progressPercent(): number {
    if (!this.questions.length) return 0;
    return (this.answeredCount / this.questions.length) * 100;
  }

  get currentPageAnsweredCount(): number {
    return this.pagedQuestions.filter((q) => !!this.answers[q.id]).length;
  }

  get activePlanLabel(): string {
    if (this.selectedPackage?.name?.trim()) {
      return this.selectedPackage.name.trim();
    }

    if (this.currentUserPackage?.name?.trim()) {
      return this.currentUserPackage.name.trim();
    }

    if (this.testMode === 'full_package') return 'Premium';
    if (this.testMode === 'basic_package') return 'Plus';
    return 'Miễn phí';
  }

  get activePlanChip(): string {
    if (this.testMode === 'full_package') return 'Premium';
    if (this.testMode === 'basic_package') return 'Plus';
    return 'Free';
  }

  trackPackage(_: number, item: UpgradePackage): number {
    return item.id;
  }

  restoreDraftAnswers(): void {
    if (typeof window === 'undefined') return;

    const raw = localStorage.getItem(this.getDraftStorageKey());
    if (!raw) {
      this.answers = {};
      return;
    }

    try {
      const parsed = JSON.parse(raw);
      const validIds = this.getValidQuestionIds();
      const restored: Record<number, 'A' | 'B'> = {};

      Object.entries(parsed || {}).forEach(([key, value]) => {
        const questionId = Number(key);
        if (validIds.has(questionId) && (value === 'A' || value === 'B')) {
          restored[questionId] = value;
        }
      });

      this.answers = restored;
    } catch {
      this.answers = {};
    }
  }

  persistDraftAnswers(): void {
    if (typeof window === 'undefined') return;
    localStorage.setItem(this.getDraftStorageKey(), JSON.stringify(this.answers));
  }

  clearDraftAnswers(): void {
    if (typeof window === 'undefined') return;
    localStorage.removeItem(this.getDraftStorageKey());
    localStorage.removeItem(this.getDraftPageStorageKey());
  }

  loadUpgradePackages(): void {
    this.loadingPackages = true;
    this.packageError = '';

    this.packageAdminService
      .getPackages()
      .pipe(finalize(() => (this.loadingPackages = false)))
      .subscribe({
        next: (res) => {
          const rawList = Array.isArray(res?.packages) ? res.packages : [];

          this.upgradePackages = rawList
            .filter((item) => !!item && !!item.is_active)
            .map((item) => this.normalizePackage(item))
            .filter((item: UpgradePackage | null): item is UpgradePackage => !!item)
            .sort((a, b) => {
              if (a.kind === 'interest' && b.kind === 'combo') return -1;
              if (a.kind === 'combo' && b.kind === 'interest') return 1;
              return a.sortOrder - b.sortOrder;
            });

          this.restorePendingUpgradeFlow();
        },
        error: () => {
          this.packageError = 'Không tải được gói dịch vụ từ Admin.';
        },
      });
  }

  normalizePackage(item: TestPackage): UpgradePackage | null {
    const id = Number(item.id || 0);
    const name = String(item.name || '').trim();
    if (!id || !name) return null;

    const kind: UpgradePlanKey = item.include_ability_test ? 'combo' : 'interest';

    return {
      id,
      name,
      subtitle:
        item.short_description?.trim() ||
        (kind === 'combo'
          ? 'Đầy đủ hơn, chính xác hơn, mở khóa sâu hơn'
          : 'Gói cơ bản nâng cao cho MBTI'),
      description:
        item.description?.trim() ||
        (kind === 'combo'
          ? 'Làm MBTI + test năng lực, không quảng cáo và mở khóa toàn bộ khóa học.'
          : 'Làm MBTI + câu hỏi Plus, không quảng cáo và xem kết quả ngay.'),
      price: Number(item.price ?? 0),
      priceLabel: this.formatPrice(Number(item.price ?? 0)),
      chipText: item.badge_text?.trim() || (kind === 'combo' ? 'Full quyền lợi' : 'Cơ bản'),
      selectedText: 'Chọn gói này',
      kind,
      themeClass: this.normalizeTheme(item.theme, kind),
      qrSrc: kind === 'combo' ? '/images/qrgoi2.jpg' : '/images/qrgoi1.jpg',
      sortOrder: Number(item.sort_order ?? id),
      raw: item,
    };
  }

  private formatPrice(value: number): string {
    if (!value || value <= 0) return 'Miễn phí';
    return `${value.toLocaleString('vi-VN')}đ`;
  }

  getQuestionDisplayLabel(q: TestQuestion): string {
    const order = Number(q.order ?? 0);

    if (Number.isFinite(order) && order > 0) {
      return `Câu ${order}`;
    }

    // Chỉ dùng dự phòng khi API không trả order.
    const index = this.questions.findIndex(
      (item) => item.id === q.id
    );

    return `Câu ${index >= 0 ? index + 1 : q.id}`;
  }

  selectAnswer(id: number, val: 'A' | 'B'): void {
    this.answers[id] = val;
    this.pageError = '';
    this.persistDraftAnswers();
  }

  isSelected(id: number, val: 'A' | 'B'): boolean {
    return this.answers[id] === val;
  }

  nextPage(): void {
    const unanswered = this.pagedQuestions.find((q) => !this.answers[q.id]);

    if (unanswered) {
      this.pageError = 'Bạn cần trả lời hết các câu trên trang này trước khi tiếp tục.';

      setTimeout(() => {
        const el = document.getElementById(`question-${unanswered.id}`);

        if (el) {
          el.scrollIntoView({
            behavior: 'smooth',
            block: 'center',
          });

          el.classList.add('question-highlight');

          setTimeout(() => {
            el.classList.remove('question-highlight');
          }, 1800);
        }
      }, 50);

      return;
    }

    this.pageError = '';

    if (this.currentPage < this.totalPages) {
      this.currentPage++;
      this.persistDraftPage();

      setTimeout(() => this.scrollToQuestionSection(), 120);
    }
  }

  prevPage(): void {
    this.pageError = '';

    if (this.currentPage > 1) {
      this.currentPage--;
      this.persistDraftPage();
      setTimeout(() => this.scrollToQuestionSection(), 120);
    }
  }

  private buildMbtiResult(): MbtiResult {
    const result: MbtiResult = {
      type: '',
      scores: {
        E: 0,
        I: 0,
        S: 0,
        N: 0,
        T: 0,
        F: 0,
        J: 0,
        P: 0,
      },
    };

    for (const q of this.mbtiQuestions) {
      const answer = this.answers[q.id];
      if (!answer) continue;

      if (answer === 'A') {
        result.scores[q.dirA] += 1;
      } else {
        result.scores[q.dirB] += 1;
      }
    }

    result.type = [
      result.scores.E >= result.scores.I ? 'E' : 'I',
      result.scores.S >= result.scores.N ? 'S' : 'N',
      result.scores.T >= result.scores.F ? 'T' : 'F',
      result.scores.J >= result.scores.P ? 'J' : 'P',
    ].join('');

    return result;
  }

  private buildAbilityScores(): AbilityScores {
    const selectedCounts: AbilityScores = {
      LANGUAGE: 0,
      LOGIC: 0,
      CREATIVE: 0,
      TECH: 0,
      LEADERSHIP: 0,
      TEAMWORK: 0,
      DETAIL: 0,
      ADAPT: 0,
      PRACTICAL: 0,
      STRATEGIC: 0,
    };

    const appearanceCounts: AbilityScores = {
      LANGUAGE: 0,
      LOGIC: 0,
      CREATIVE: 0,
      TECH: 0,
      LEADERSHIP: 0,
      TEAMWORK: 0,
      DETAIL: 0,
      ADAPT: 0,
      PRACTICAL: 0,
      STRATEGIC: 0,
    };

    const percentages: AbilityScores = {
      LANGUAGE: 0,
      LOGIC: 0,
      CREATIVE: 0,
      TECH: 0,
      LEADERSHIP: 0,
      TEAMWORK: 0,
      DETAIL: 0,
      ADAPT: 0,
      PRACTICAL: 0,
      STRATEGIC: 0,
    };

    const abilityKeys = Object.keys(
      selectedCounts
    ) as AbilityKey[];

    const validKeys = new Set<string>(abilityKeys);

    const normalizeKey = (
      value: unknown
    ): AbilityKey | null => {
      const key = String(value ?? '')
        .trim()
        .toUpperCase();

      return validKeys.has(key)
        ? key as AbilityKey
        : null;
    };

    /*
    * Chỉ duyệt 30 câu Premium.
    * Không dùng this.questions vì mảng đó còn chứa
    * MBTI và Plus.
    */
    for (const question of this.premiumQuestions) {
      const axisParts = String(question.axis ?? '')
        .split('/')
        .map((value) => value.trim().toUpperCase());

      const left = normalizeKey(
        question.dirA ?? axisParts[0]
      );

      const right = normalizeKey(
        question.dirB ?? axisParts[1]
      );

      /*
      * Mỗi câu làm hai tiêu chí xuất hiện.
      */
      if (left) {
        appearanceCounts[left] += 1;
      }

      if (right) {
        appearanceCounts[right] += 1;
      }

      const answer = this.answers[question.id];

      if (!answer) {
        continue;
      }

      const selectedKey =
        answer === 'A' ? left : right;

      if (selectedKey) {
        selectedCounts[selectedKey] += 1;
      }
    }

    /*
    * Tỷ lệ = số lần được chọn / số lần xuất hiện × 100.
    * Theo dữ liệu chuẩn, mỗi năng lực xuất hiện 6 lần.
    */
    for (const key of abilityKeys) {
      const appearances = appearanceCounts[key];
      const selected = selectedCounts[key];

      percentages[key] =
        appearances > 0
          ? Number(
              (
                (selected / appearances) *
                100
              ).toFixed(2)
            )
          : 0;
    }

    console.log(
      'PREMIUM APPEARANCE COUNTS:',
      appearanceCounts
    );

    console.log(
      'PREMIUM SELECTED COUNTS:',
      selectedCounts
    );

    console.log(
      'PREMIUM PERCENTAGES:',
      percentages
    );

    return percentages;
  }

  private buildInterestFallback(scores: AbilityScores): {
    groupScores: Record<InterestGroupKey, number>;
    topGroups: Array<{ key: InterestGroupKey; value: number }>;
  } {
    const groupScores: Record<InterestGroupKey, number> = {
      creative: (scores['CREATIVE'] || 0) + (scores['LANGUAGE'] || 0),
      analytic: (scores['LOGIC'] || 0) + (scores['TECH'] || 0),
      social: (scores['TEAMWORK'] || 0) + (scores['LANGUAGE'] || 0),
      business: (scores['LEADERSHIP'] || 0) + (scores['STRATEGIC'] || 0),
    };

    const topGroups = Object.entries(groupScores)
      .map(([key, value]) => ({ key: key as InterestGroupKey, value }))
      .sort((a, b) => b.value - a.value);

    return { groupScores, topGroups };
  }

  private buildPlusInterestResult(): {
    rawScores: Record<string, number>;

    appearanceCounts:
      Record<InterestGroupKey, number>;

    groupScores:
      Record<InterestGroupKey, number>;

    topGroups: Array<{
      key: InterestGroupKey;
      value: number;
    }>;
  } {
    const selectedCounts:
      Record<InterestGroupKey, number> = {
        creative: 0,
        analytic: 0,
        social: 0,
        business: 0,
      };

    const appearanceCounts:
      Record<InterestGroupKey, number> = {
        creative: 0,
        analytic: 0,
        social: 0,
        business: 0,
      };

    const codeMap:
      Record<string, InterestGroupKey> = {
        CREATIVE: 'creative',
        ANALYTIC: 'analytic',
        SOCIAL: 'social',
        BUSINESS: 'business',
      };

    const normalizeInterestKey = (
      value: unknown
    ): InterestGroupKey | null => {
      const code = String(value ?? '')
        .trim()
        .toUpperCase();

      return codeMap[code] ?? null;
    };

    for (const question of this.plusQuestions) {
      const axisParts = String(question.axis ?? '')
        .split('/')
        .map((value) => value.trim().toUpperCase());

      const left = normalizeInterestKey(
        question.dirA ?? axisParts[0]
      );

      const right = normalizeInterestKey(
        question.dirB ?? axisParts[1]
      );

      /*
      * Hai tiêu chí trong câu đều được tính
      * một lần xuất hiện.
      */
      if (left) {
        appearanceCounts[left] += 1;
      }

      if (right) {
        appearanceCounts[right] += 1;
      }

      const answer = this.answers[question.id];

      if (!answer) {
        continue;
      }

      const selectedKey =
        answer === 'A' ? left : right;

      if (selectedKey) {
        selectedCounts[selectedKey] += 1;
      }
    }

    const groupScores:
      Record<InterestGroupKey, number> = {
        creative: 0,
        analytic: 0,
        social: 0,
        business: 0,
      };

    (
      Object.keys(groupScores) as
        InterestGroupKey[]
    ).forEach((key) => {
      const appearances = appearanceCounts[key];
      const selected = selectedCounts[key];

      groupScores[key] =
        appearances > 0
          ? Number(
              (
                (selected / appearances) *
                100
              ).toFixed(2)
            )
          : 0;
    });

    const topGroups = (
      Object.entries(groupScores) as Array<
        [InterestGroupKey, number]
      >
    )
      .map(([key, value]) => ({
        key,
        value,
      }))
      .sort((a, b) => b.value - a.value);

    /*
    * rawScores lưu số lần tiêu chí được chọn.
    */
    const rawScores: Record<string, number> = {
      CREATIVE: selectedCounts.creative,
      ANALYTIC: selectedCounts.analytic,
      SOCIAL: selectedCounts.social,
      BUSINESS: selectedCounts.business,
    };

    console.log(
      'PLUS APPEARANCE COUNTS:',
      appearanceCounts
    );

    console.log(
      'PLUS SELECTED COUNTS:',
      selectedCounts
    );

    console.log(
      'PLUS PERCENTAGES:',
      groupScores
    );

    return {
      rawScores,
      appearanceCounts,
      groupScores,
      topGroups,
    };
  }

  private buildCombinedChartHistoryPayload(
    interestGroupScores: Record<InterestGroupKey, number>,
    abilityScores: AbilityScores
  ) {
    const abilityRows = {
      creative: Number(abilityScores.CREATIVE || 0),
      analytic: Number((abilityScores.LOGIC || 0) + (abilityScores.TECH || 0)),
      communication: Number((abilityScores.LANGUAGE || 0) + (abilityScores.TEAMWORK || 0)),
      leadership: Number(abilityScores.LEADERSHIP || 0),
      technology: Number((abilityScores.TECH || 0) + (abilityScores.PRACTICAL || 0)),
      strategy: Number((abilityScores.STRATEGIC || 0) + (abilityScores.ADAPT || 0)),
    };

    const totalAbility =
      Object.values(abilityRows).reduce((sum, value) => sum + value, 0) || 1;

    return [
      {
        key: 'creative',
        label: 'Sáng tạo',
        interestRaw: Number(interestGroupScores.creative || 0),
        abilityRaw: Math.round((abilityRows.creative / totalAbility) * 100),
      },
      {
        key: 'analytic',
        label: 'Phân tích',
        interestRaw: Number(interestGroupScores.analytic || 0),
        abilityRaw: Math.round((abilityRows.analytic / totalAbility) * 100),
      },
      {
        key: 'communication',
        label: 'Giao tiếp',
        interestRaw: Number(interestGroupScores.social || 0),
        abilityRaw: Math.round((abilityRows.communication / totalAbility) * 100),
      },
      {
        key: 'leadership',
        label: 'Lãnh đạo',
        interestRaw: Number(interestGroupScores.business || 0),
        abilityRaw: Math.round((abilityRows.leadership / totalAbility) * 100),
      },
      {
        key: 'technology',
        label: 'Công nghệ',
        interestRaw: Number(interestGroupScores.analytic || 0),
        abilityRaw: Math.round((abilityRows.technology / totalAbility) * 100),
      },
      {
        key: 'strategy',
        label: 'Chiến lược',
        interestRaw: Number(interestGroupScores.business || 0),
        abilityRaw: Math.round((abilityRows.strategy / totalAbility) * 100),
      },
    ];
  }

  submitTest(): void {
    if (this.currentPageAnsweredCount < this.pagedQuestions.length) {
      this.pageError = 'Bạn cần trả lời hết các câu trên trang này trước khi nộp.';

      this.scrollToQuestionSection();
      return;
    }

    const mbtiResult = this.buildMbtiResult();

    if (typeof window !== 'undefined') {
      localStorage.setItem('mbti_result', JSON.stringify(mbtiResult));
    }

    if (this.resultApi.isLoggedIn()) {
      this.resultApi.saveMbtiResult({
        mbti_type: mbtiResult.type,
        scores: mbtiResult.scores,
        answers: this.answers,
        upgrades: {
          interest: this.testMode === 'basic_package' || this.testMode === 'full_package',
          ability: this.testMode === 'full_package',
        },
      }).subscribe({
        error: (err) => console.error('SAVE MBTI RESULT ERROR', err),
      });
    }

    const sessionId = this.userPortal.getOrCreateTestSessionId();

    if (this.testMode === 'basic_package' || this.testMode === 'full_package') {
      const interestFallback = this.buildPlusInterestResult();

      localStorage.setItem(
        'interest_result',
        JSON.stringify({
          answers: this.answers,
          rawScores: interestFallback.rawScores,
          groupScores: interestFallback.groupScores,
          topGroups: interestFallback.topGroups,
        }),
      );
    }

    if (this.testMode === 'full_package') {
      const abilityScores = this.buildAbilityScores();
      const interestFallback = this.buildPlusInterestResult();

      if (typeof window !== 'undefined') {
        localStorage.setItem(
          'ability_result',
          JSON.stringify({
            mbti_type: mbtiResult.type,
            mbti_scores: mbtiResult.scores,
            answers: this.answers,
            scores: abilityScores,
            interest_group_scores: interestFallback.groupScores,
            interest_top_groups: interestFallback.topGroups,
          }),
        );

        localStorage.setItem(
          'interest_result',
          JSON.stringify({
            answers: this.answers,
            rawScores: interestFallback.rawScores,
            groupScores: interestFallback.groupScores,
            topGroups: interestFallback.topGroups,
          }),
        );
      }

      this.userPortal.storeHistory({
        test_session_id: sessionId,
        test_type: 'full',
        result_code: mbtiResult.type,
        answers: this.answers,
        questions: this.questions,
        scores: {
          ...mbtiResult.scores,
          ...abilityScores,
        },
        result_payload: {
          mbti_type: mbtiResult.type,
          mbti_scores: mbtiResult.scores,

          raw_interest_scores: interestFallback.rawScores,

          ability_scores: abilityScores,
          interest_group_scores: interestFallback.groupScores,
          interest_top_groups: interestFallback.topGroups,

          combined_chart_data: this.buildCombinedChartHistoryPayload(
            interestFallback.groupScores,
            abilityScores
          ),
        },
        package_id: this.currentUserPackage?.id ?? null,
        package_name: this.currentUserPackage?.name ?? 'Premium',
      }).subscribe({
        next: () => {
          this.clearDraftAnswers();

          Object.keys(localStorage).forEach((key) => {
            if (
              key.startsWith('mbti_answers_draft_') ||
              key.includes('__page')
            ) {
              localStorage.removeItem(key);
            }
          });

          this.answers = {};
          this.currentPage = 1;

          localStorage.setItem('last_full_test_session_id', sessionId);

          this.userPortal.clearTestSessionId();

          this.router.navigateByUrl('/ability-result');
        },
      });

      return;
    }

    if (this.testMode === 'basic_package') {
      const interestFallback = this.buildPlusInterestResult();

      this.userPortal.storeHistory({
        test_session_id: sessionId,
        test_type: 'plus',
        result_code: mbtiResult.type,
        answers: this.answers,
        questions: this.questions,
        scores: {
          ...mbtiResult.scores,
        },
        result_payload: {
          mbti_type: mbtiResult.type,
          mbti_scores: mbtiResult.scores,

          raw_interest_scores: interestFallback.rawScores,

          interest_group_scores: interestFallback.groupScores,
          interest_top_groups: interestFallback.topGroups,
        },
        package_id: this.currentUserPackage?.id ?? null,
        package_name: this.currentUserPackage?.name ?? 'Plus',
      }).subscribe({
        next: () => {
          this.clearDraftAnswers();

          Object.keys(localStorage).forEach((key) => {
            if (
              key.startsWith('mbti_answers_draft_') ||
              key.includes('__page')
            ) {
              localStorage.removeItem(key);
            }
          });

          this.answers = {};
          this.currentPage = 1;

          localStorage.setItem('last_plus_test_session_id', sessionId);
          this.userPortal.clearTestSessionId();

          this.router.navigateByUrl('/interest-result');
        },
        error: (err) => {
          console.error('SAVE HISTORY ERROR', err);
          this.clearDraftAnswers();
          this.answers = {};
          this.currentPage = 1;
          this.userPortal.clearTestSessionId();
          this.router.navigateByUrl('/interest-result');
        }
      });

      return;
    }

    this.selectedPackageId = null;
    this.packageError = '';
    this.showPaymentModal = false;
    this.showAdModal = false;
    this.showUpgradeModal = true;
    this.cdr.detectChanges();
  }

  selectPlan(pkg: UpgradePackage): void {
    this.selectedPackageId = pkg.id;
  }

  private activateBasicFlow(): void {
    this.showUpgradeModal = false;
    this.showPaymentModal = false;
    this.packageError = '';
    this.paymentStatus = '';
    this.paymentQrSrc = '';
    this.paymentCheckoutUrl = '';
    this.paymentOrderCode = null;

    this.testMode = 'free';
    this.currentUserRole = 'user';

    if (this.selectedPackage?.raw) {
      this.currentUserPackage = this.selectedPackage.raw;
    }

    if (typeof window !== 'undefined') {
      localStorage.setItem(
        'selected_upgrades',
        JSON.stringify({
          interest: true,
          ability: false,
          package_id: this.selectedPackage?.id ?? null,
          paid: true,
          paid_at: Date.now(),
        }),
      );

      if (this.selectedPackage?.raw) {
        localStorage.setItem('selected_package', JSON.stringify(this.selectedPackage.raw));
      }

      localStorage.removeItem('pending_upgrade_package_id');
      localStorage.removeItem('pending_upgrade_plan_kind');
      localStorage.removeItem('return_after_login_upgrade');
      localStorage.removeItem('return_after_login_path');
    }

    this.testMode = 'basic_package';

    this.loadPlusQuestions(() => {

  
  this.plusQuestions.forEach(q => {
    delete this.answers[q.id];
  });

  this.persistDraftAnswers();

  const mbtiPageCount = Math.ceil(this.mbtiQuestions.length / this.pageSize);
    this.currentPage = mbtiPageCount + 1;

    this.persistDraftPage();
    this.cdr.detectChanges();

    setTimeout(() => this.scrollToQuestionSection(), 120);
  });
  }

  private activatePremiumFlow(): void {
    this.showUpgradeModal = false;
    this.showPaymentModal = false;
    this.packageError = '';
    this.paymentStatus = '';
    this.paymentQrSrc = '';
    this.paymentCheckoutUrl = '';
    this.paymentOrderCode = null;

    this.testMode = 'full_package';
    this.currentUserRole = 'premium';

    if (this.selectedPackage?.raw) {
      this.currentUserPackage = this.selectedPackage.raw;
    }

    this.loadFullPackageQuestions(() => {
      const mbtiPageCount = Math.ceil(this.mbtiQuestions.length / this.pageSize);
      this.currentPage = mbtiPageCount + 1;

      this.persistDraftAnswers();
      this.persistDraftPage();
      this.cdr.detectChanges();

      setTimeout(() => this.scrollToQuestionSection(), 120);
    });

    if (typeof window !== 'undefined') {
      localStorage.removeItem('pending_upgrade_package_id');
      localStorage.removeItem('pending_upgrade_plan_kind');
      localStorage.removeItem('return_after_login_upgrade');
      localStorage.removeItem('return_after_login_path');
    }
  }

  continueWithUpgrades(): void {
    if (!this.selectedPackage || this.paymentCreating) return;
    if (typeof window === 'undefined') return;

    const pkg = this.selectedPackage;
    const token = localStorage.getItem('auth_token');

    localStorage.setItem('pending_upgrade_package_id', String(pkg.id));
    localStorage.setItem('pending_upgrade_plan_kind', pkg.kind);

    if (pkg.raw) {
      localStorage.setItem('selected_package', JSON.stringify(pkg.raw));
    }

    if (!token) {
      localStorage.setItem('return_after_login_upgrade', '1');
      localStorage.setItem('return_after_login_path', '/mbti-test');
      this.router.navigateByUrl('/login');
      return;
    }

    if (this.currentUserRole === 'premium' && pkg.kind === 'combo') {
      this.currentUserPackage = pkg.raw ?? null;

      localStorage.setItem(
        'selected_upgrades',
        JSON.stringify({
          interest: true,
          ability: true,
          package_id: pkg.id,
          paid: true,
          paid_at: Date.now(),
        }),
      );

      this.activatePremiumFlow();
      return;
    }

    this.packageError = '';
    this.paymentCreating = true;
    this.showUpgradeModal = false;
    this.showPaymentModal = true;

    this.paymentQrSrc = '';
    this.paymentCheckoutUrl = '';
    this.paymentOrderCode = null;
    this.paymentStatus = 'PENDING';

    this.userPortal
      .createPaymentLink(pkg.id)
      .pipe(
        finalize(() => {
          this.paymentCreating = false;
        }),
      )
      .subscribe({
        next: async (res: any) => {
          console.log('PAYMENT CREATE RESPONSE = ', res);

          const qrRaw = this.readPaymentString(res, [
            'qr_code',
            'qrCode',
            'data.qr_code',
            'data.qrCode',
            'payment.qr_code',
            'payment.qrCode',
            'data.bin_qr',
            'bin_qr',
            'payment.bin_qr',
          ]);

          const checkoutRaw = this.readPaymentString(res, [
            'checkout_url',
            'checkoutUrl',
            'data.checkout_url',
            'data.checkoutUrl',
            'payment.checkout_url',
            'payment.checkoutUrl',
          ]);

          const orderCodeRaw = this.readPaymentNumber(res, [
            'order_code',
            'orderCode',
            'data.order_code',
            'data.orderCode',
            'payment.order_code',
            'payment.orderCode',
          ]);

          const statusRaw = this.readPaymentString(res, [
            'status',
            'data.status',
            'payment.status',
          ]);

          console.log('qrRaw = ', qrRaw);
          console.log('checkoutRaw = ', checkoutRaw);
          console.log('orderCodeRaw = ', orderCodeRaw);
          console.log('statusRaw = ', statusRaw);

          this.paymentCheckoutUrl = checkoutRaw;
          this.paymentOrderCode = orderCodeRaw;
          this.paymentStatus = (statusRaw as any) || 'PENDING';

          const qrSource = qrRaw || checkoutRaw;
          this.paymentQrSrc = await this.buildQrDataUrl(qrSource);

          if (!this.paymentQrSrc && !this.paymentCheckoutUrl) {
            this.packageError = 'Backend chưa trả về QR hoặc link thanh toán.';
          } else if (!qrRaw && this.paymentCheckoutUrl) {
            this.packageError = 'Chưa có QR ngân hàng hợp lệ, bạn hãy bấm mở trang thanh toán.';
          } else {
            this.packageError = '';
          }

          if (this.paymentOrderCode) {
            this.startPaymentPolling();
          }

          this.cdr.detectChanges();
        },
        error: () => {
          this.packageError = 'Không tạo được mã thanh toán.';
          this.showPaymentModal = false;
          this.showUpgradeModal = true;
        },
      });
  }

  private startPaymentPolling(): void {
    this.stopPaymentPolling();

    if (!this.paymentOrderCode) return;

    this.paymentPollTimer = setInterval(() => {
      if (!this.paymentOrderCode) return;

      this.userPortal.getPaymentStatus(this.paymentOrderCode).subscribe({
        next: (res) => {
          this.paymentStatus = res.status || '';

          if (res.status === 'PAID') {
            this.confirmPaymentSuccess();
          }
        },
        error: () => {},
      });
    }, 3000);
  }

  private stopPaymentPolling(): void {
    if (this.paymentPollTimer) {
      clearInterval(this.paymentPollTimer);
      this.paymentPollTimer = null;
    }
  }

  confirmPayment(): void {
    if (!this.paymentOrderCode || this.paymentChecking) return;

    this.paymentChecking = true;

    this.userPortal
      .getPaymentStatus(this.paymentOrderCode)
      .pipe(finalize(() => (this.paymentChecking = false)))
      .subscribe({
        next: (res) => {
          this.paymentStatus = res.status || '';

          if (res.status === 'PAID') {
            this.confirmPaymentSuccess();
            return;
          }

          this.packageError = 'Hệ thống chưa ghi nhận thanh toán. Bạn thử lại sau vài giây nhé.';
        },
        error: () => {
          this.packageError = 'Không kiểm tra được trạng thái thanh toán.';
        },
      });
  }

  private confirmPaymentSuccess(): void {
    this.stopPaymentPolling();

    if (this.selectedPackage?.raw) {
      this.currentUserPackage = this.selectedPackage.raw;
      this.userPortal.setSelectedPackageToStorage(this.selectedPackage.raw);
    }

    if (typeof window !== 'undefined') {
      if (this.selectedPackage?.kind === 'combo') {
        localStorage.setItem(
          'selected_upgrades',
          JSON.stringify({
            interest: true,
            ability: true,
            package_id: this.selectedPackage?.id ?? null,
            paid: true,
            paid_at: Date.now(),
          }),
        );
      } else {
        localStorage.setItem(
          'selected_upgrades',
          JSON.stringify({
            interest: true,
            ability: false,
            package_id: this.selectedPackage?.id ?? null,
            paid: true,
            paid_at: Date.now(),
          }),
        );
      }

      if (this.selectedPackage?.raw) {
        localStorage.setItem('selected_package', JSON.stringify(this.selectedPackage.raw));
      }
    }

    this.showSuccessToast('Thanh toán thành công');

    this.ngZone.run(() => {
      if (this.selectedPackage?.kind === 'combo') {
        this.currentUserRole = 'premium';
        this.activatePremiumFlow();
      } else {
        this.currentUserRole = 'user';
        this.activateBasicFlow();
      }
    });
  }

  cancelPayment(): void {
    this.stopPaymentPolling();

    this.paymentQrSrc = '';
    this.paymentCheckoutUrl = '';
    this.paymentOrderCode = null;
    this.paymentStatus = '';
    this.packageError = '';

    this.showPaymentModal = false;
    this.showUpgradeModal = true;

    if (typeof window !== 'undefined') {
      localStorage.removeItem('pending_upgrade_package_id');
      localStorage.removeItem('pending_upgrade_plan_kind');
      localStorage.removeItem('return_after_login_upgrade');
    }
  }

  closeUpgradeModal(): void {
    this.paymentCreating = false;
    this.showUpgradeModal = false;
    this.selectedPackageId = null;
  }

  closePaymentModal(): void {
    this.stopPaymentPolling();
    this.paymentCreating = false;
    this.paymentChecking = false;
    this.paymentQrSrc = '';
    this.paymentCheckoutUrl = '';
    this.paymentOrderCode = null;
    this.paymentStatus = '';
    this.packageError = '';
    this.showPaymentModal = false;

    if (typeof window !== 'undefined') {
      localStorage.removeItem('pending_upgrade_package_id');
      localStorage.removeItem('pending_upgrade_plan_kind');
      localStorage.removeItem('return_after_login_upgrade');
    }
  }

  skipToAd(): void {
    this.testMode = 'free';
    this.currentUserRole = 'user';
    this.currentUserPackage = null;
    this.rebuildQuestionFlow();
    this.selectedPackageId = null;
    this.showUpgradeModal = false;
    this.startAdFlow();
  }

  startAdFlow(): void {
    this.adFinished = false;
    this.adReady = false;
    this.adStarted = false;
    this.adErrorMessage = '';
    this.adCountdown = 0;
    this.adDuration = 0;
    this.showAdModal = true;

    setTimeout(() => {
      const video = this.adVideoRef?.nativeElement;
      if (!video) {
        this.onAdError();
        return;
      }

      video.pause();
      video.currentTime = 0;
      video.muted = false;
      video.volume = 1;
      video.load();
    }, 150);
  }

  onAdLoadedMetadata(video: HTMLVideoElement): void {
    const rawDuration = Math.ceil(video.duration || 0);
    this.adDuration =
      rawDuration > 0 ? Math.min(rawDuration, this.maxAdSeconds) : this.maxAdSeconds;
    this.adCountdown = this.adDuration;
    this.adReady = true;
    this.adErrorMessage = '';
  }

  playAd(): void {
    const video = this.adVideoRef?.nativeElement;
    if (!video) {
      this.onAdError();
      return;
    }

    video
      .play()
      .then(() => {
        this.adStarted = true;
        this.adErrorMessage = '';
      })
      .catch(() => {
        this.adErrorMessage = 'Không thể phát video. Bạn bấm thử lại nhé.';
      });
  }

  onAdTimeUpdate(video: HTMLVideoElement): void {
    if (!this.adStarted || this.adFinished) return;

    const remaining = Math.max(
      0,
      Math.ceil((this.adDuration || this.maxAdSeconds) - video.currentTime),
    );
    this.adCountdown = remaining;

    if (video.currentTime >= (this.adDuration || this.maxAdSeconds)) {
      this.onAdEnded();
    }
  }

  onAdEnded(): void {
    if (this.adFinished) return;

    this.adFinished = true;
    this.showAdModal = false;

    if (typeof window !== 'undefined') {
      localStorage.setItem('result_basic_access', 'ad');
      localStorage.setItem('result_basic_access_at', String(Date.now()));
    }

    const rawResult = localStorage.getItem('mbti_result');
    const mbtiResult = rawResult ? JSON.parse(rawResult) : null;
    const sessionId = this.userPortal.getOrCreateTestSessionId();

    if (mbtiResult) {
      this.userPortal.storeHistory({
        test_session_id: sessionId,
        test_type: 'mbti',
        result_code: mbtiResult.type,
        answers: this.answers,
        questions: this.questions,
        scores: mbtiResult.scores,
        result_payload: {
          mbti_type: mbtiResult.type,
          mbti_scores: mbtiResult.scores,
        },
        package_id: null,
        package_name: 'Free',
      }).subscribe({
        next: () => {},
        error: (err) => console.error('SAVE FREE HISTORY ERROR', err),
      });
    }

    // FIX clear draft
    this.clearDraftAnswers();

    Object.keys(localStorage).forEach((key) => {
      if (
        key.startsWith('mbti_answers_draft_') ||
        key.includes('__page')
      ) {
        localStorage.removeItem(key);
      }
    });

    this.answers = {};
    this.currentPage = 1;

    this.userPortal.clearTestSessionId();

    this.router.navigateByUrl('/result-basic');
  }

  onAdError(): void {
    this.adErrorMessage = 'Không tải được video quảng cáo. Bạn bấm phát lại giúp mình.';
  }

  getCheckoutQrUrl(): string {
    if (!this.paymentCheckoutUrl) return '';
    return `https://api.qrserver.com/v1/create-qr-code/?size=260x260&data=${encodeURIComponent(this.paymentCheckoutUrl)}`;
  }

  scrollToQuestionSection(): void {
    if (typeof window === 'undefined') return;

    const el = document.getElementById('questionSection');

    if (!el) {
      window.scrollTo({
        top: 0,
        behavior: 'smooth',
      });
      return;
    }

    const headerOffset = 110;
    const y = el.getBoundingClientRect().top + window.scrollY - headerOffset;

    window.scrollTo({
      top: y,
      behavior: 'smooth',
    });
  }

  private normalizeQuestionPackage(
    value: unknown
  ): QuestionPackageType | null {
    const packageType = String(value ?? '')
      .trim()
      .toLowerCase();

    if (
      packageType === 'free' ||
      packageType === 'plus' ||
      packageType === 'premium'
    ) {
      return packageType;
    }

    return null;
  }

  private belongsToPackage(
    item: any,
    expectedPackage: QuestionPackageType
  ): boolean {
    const packageType = this.normalizeQuestionPackage(
      item?.package_type ??
      item?.packageType
    );

    // Ưu tiên package_type từ DB.
    if (packageType) {
      return packageType === expectedPackage;
    }

    // Dự phòng nếu API chưa trả package_type:
    // dựa vào cột order của bộ 86 câu hiện tại.
    const order = Number(item?.order ?? 0);

    if (!Number.isFinite(order) || order <= 0) {
      return false;
    }

    if (expectedPackage === 'free') {
      return order >= 1 && order <= 36;
    }

    if (expectedPackage === 'plus') {
      return order >= 37 && order <= 56;
    }

    return order >= 57 && order <= 86;
  }

  private filterQuestionsByPackage(
    response: any,
    expectedPackage: QuestionPackageType
  ): any[] {
    return this.extractQuestionList(response)
      .filter((item: any) =>
        this.belongsToPackage(item, expectedPackage)
      );
  }
}
