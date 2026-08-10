import {
  Component,
  OnDestroy,
  OnInit,
  computed,
  inject,
  signal,
} from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { DomSanitizer, SafeResourceUrl } from '@angular/platform-browser';
import { finalize } from 'rxjs/operators';
import { forkJoin, of } from 'rxjs';
import { catchError, map } from 'rxjs/operators';
import { API_ORIGIN } from '../../core/api.config';

declare global {
  interface Window {
    YT?: any;
    onYouTubeIframeAPIReady?: () => void;
  }
}

type QuestionOptionItem = {
  id?: number;
  content: string;
  is_correct?: boolean;
};

type QuestionItem = {
  id?: number;
  question: string;
  explanation?: string | null;
  options: QuestionOptionItem[];
};

type LessonItem = {
  id?: number;
  service_package_id?: number;
  title?: string;
  description?: string | null;
  video_url?: string | null;
  duration?: string | null;
  sort_order?: number;
  is_active?: boolean;
  questions?: QuestionItem[];
};

type CourseItem = {
  id: number;
  name: string;
  thumbnail?: string | null;
  short_description?: string | null;
  description?: string | null;
  course_major?: string | null;
  price?: number;
  lessons?: LessonItem[];
  is_purchased?: boolean;
};

type HistoryQuestionItem = {
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
  questions: HistoryQuestionItem[];
};

type LessonHistoryStore = Record<string, LessonHistoryItem>;

@Component({
  selector: 'app-courses',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './courses.html',
  styleUrl: './courses.css',
})
export class Courses implements OnInit, OnDestroy {
  private router = inject(Router);
  private http = inject(HttpClient);
  private sanitizer = inject(DomSanitizer);

  private readonly apiUrl = API_ORIGIN;

  private readonly youtubePlayerElementId = 'youtube-player-host';
  private readonly purchasedPreviewLimit = 12;
  private readonly otherCoursesPageSize = 8;

  private youtubeApiPromise: Promise<void> | null = null;
  private player: any = null;
  private alertTimer: ReturnType<typeof setInterval> | null = null;
  private pendingPlayerInitTimer: ReturnType<typeof setTimeout> | null = null;
  private currentYoutubeLessonId: number | null = null;

  keyword = signal('');
  selectedMajor = signal('Tất cả');

  loadingCourses = signal(false);
  loadError = signal('');

  showPreviewModal = signal(false);
  showPaymentModal = signal(false);
  confirmingPayment = signal(false);

  showLearningModal = signal(false);
  learningCourse = signal<CourseItem | null>(null);
  selectedLesson = signal<LessonItem | null>(null);

  showPurchasedPopup = signal(false);
  coursePage = signal(1);
  readonly coursePageSize = 12;
  otherCoursesPage = signal(1);

  showAlert = signal(false);
  showSubmitConfirmModal = signal(false);
  submittingLessonQuiz = signal(false);
  alertType = signal<'success' | 'error' | 'info'>('info');
  alertTitle = signal('');
  alertMessage = signal('');
  alertCountdown = signal(0);

  selectedCourse = signal<CourseItem | null>(null);
  isUserLoggedIn = signal(true);
  canAccessCourses = signal(false);
  accessMessage = signal(
    'Khóa học chỉ dành cho tài khoản đã đăng ký gói nâng cao 99k.'
  );

  allCourses = signal<CourseItem[]>([]);
  purchasedCourseIds = signal<number[]>([]);
  completedLessonIds = signal<number[]>(this.readCompletedLessonIdsFromStorage());

  selectedAnswers = signal<Record<string, number>>({});
  lockedQuestions = signal<Record<string, boolean>>({});
  lessonHistories = signal<LessonHistoryStore>({});

  totalCoursePages = computed(() => {
    return Math.max(1, Math.ceil(this.purchasedCoursesList().length / this.coursePageSize));
  });

  paginatedPurchasedCourses = computed(() => {
    const start = (this.coursePage() - 1) * this.coursePageSize;
    return this.purchasedCoursesList().slice(start, start + this.coursePageSize);
  });

  coursePageNumbers = computed(() =>
    Array.from({ length: this.totalCoursePages() }, (_, i) => i + 1)
  );

  filteredLessons = computed(() => {
    const keyword = this.keyword().trim().toLowerCase();
    const major = this.selectedMajor();

    return this.allCourses()
      .flatMap((course) =>
        (course.lessons || []).map((lesson) => ({
          ...lesson,
          course_major: course.course_major || 'Chưa phân loại',
          course_name: course.name || '',
        }))
      )
      .filter((lesson) => {
        const title = (lesson.title || '').toLowerCase();
        const description = (lesson.description || '').toLowerCase();
        const courseName = (lesson.course_name || '').toLowerCase();
        const courseMajor = lesson.course_major || 'Chưa phân loại';

        const matchKeyword =
          !keyword ||
          title.includes(keyword) ||
          description.includes(keyword) ||
          courseName.includes(keyword);

        const matchMajor = major === 'Tất cả' || courseMajor === major;

        return matchKeyword && matchMajor;
      });
  });

  filteredCourses = computed(() => {
    const keyword = this.keyword().trim().toLowerCase();
    const major = this.selectedMajor();

    return this.allCourses().filter((course) => {
      const name = (course.name || '').toLowerCase();
      const description = (
        course.short_description ||
        course.description ||
        ''
      ).toLowerCase();
      const courseMajor = course.course_major || 'Chưa phân loại';

      const matchKeyword =
        !keyword ||
        name.includes(keyword);

      const matchMajor = major === 'Tất cả' || courseMajor === major;

      return matchKeyword && matchMajor;
    });
  });

  purchasedCoursesList = computed(() =>
    this.filteredCourses().filter((item) => this.isPurchased(item.id))
  );

  visiblePurchasedCourses = computed(() =>
    this.purchasedCoursesList().slice(0, this.purchasedPreviewLimit)
  );

  otherCoursesList = computed(() =>
    this.filteredCourses().filter((item) => !this.isPurchased(item.id))
  );

  totalOtherPages = computed(() => {
    const total = this.otherCoursesList().length;
    return Math.max(1, Math.ceil(total / this.otherCoursesPageSize));
  });

  paginatedOtherCourses = computed(() => {
    const page = this.otherCoursesPage();
    const start = (page - 1) * this.otherCoursesPageSize;

    return this.otherCoursesList().slice(
      start,
      start + this.otherCoursesPageSize
    );
  });

  otherPageNumbers = computed(() =>
    Array.from({ length: this.totalOtherPages() }, (_, i) => i + 1)
  );

  majorOptions = computed(() => {
    const majors = this.allCourses()
      .map((item) => item.course_major || 'Chưa phân loại')
      .filter(Boolean);

    return ['Tất cả', ...Array.from(new Set(majors))];
  });

  selectedLessonQuestions = computed<QuestionItem[]>(() => {
    const lesson = this.selectedLesson();
    return Array.isArray(lesson?.questions) ? lesson!.questions! : [];
  });

  ngOnInit(): void {
    this.resolveCourseAccess();
  }

  ngOnDestroy(): void {
    this.destroyPlayer();
    this.clearAlertTimer();

    if (this.pendingPlayerInitTimer) {
      clearTimeout(this.pendingPlayerInitTimer);
      this.pendingPlayerInitTimer = null;
    }
  }

  private resolveCourseAccess(): void {
    if (typeof window === 'undefined') {
      this.isUserLoggedIn.set(false);
      this.canAccessCourses.set(false);
      return;
    }

    const token = localStorage.getItem('auth_token');
    this.isUserLoggedIn.set(!!token);

    this.loadingCourses.set(true);
    this.loadError.set('');

    this.http
      .get<{ courses?: any[]; has_full_course_access?: boolean }>(
        `${this.apiUrl}/api/courses`,
        {
          withCredentials: true,
          headers: this.getAuthHeaders(),
        }
      )
      .pipe(finalize(() => this.loadingCourses.set(false)))
      .subscribe({
        next: (res) => {
          const allow = !!res?.has_full_course_access;
          this.canAccessCourses.set(allow);

          const rawCourses = res?.courses ?? [];
          const normalizedCourses = rawCourses.map((item) =>
            this.normalizeCourse(item)
          );

          this.allCourses.set(normalizedCourses);
          this.mergePurchasedIdsFromApi(normalizedCourses);

          if (allow && normalizedCourses.length) {
            this.loadLessonsForCourses(normalizedCourses);
          } else {
            this.lessonHistories.set({});
            this.selectedAnswers.set({});
            this.lockedQuestions.set({});
          }
        },
        error: (error) => {
          console.error('Resolve course access error:', error);

          this.canAccessCourses.set(false);
          this.allCourses.set([]);
          this.purchasedCourseIds.set([]);
          this.lessonHistories.set({});
          this.selectedAnswers.set({});
          this.lockedQuestions.set({});
          this.loadError.set('Không tải được danh sách khóa học từ hệ thống.');
        },
      });
  }

  goUpgradePlan(): void {
    if (typeof window !== 'undefined') {
      localStorage.setItem('pending_upgrade_plan_kind', 'combo');
      localStorage.setItem('return_after_login_upgrade', '1');
      localStorage.setItem('return_after_login_path', '/courses');
    }

    this.router.navigateByUrl('/mbti-test');
  }

  setKeyword(value: string): void {
    this.keyword.set(value);
    this.otherCoursesPage.set(1);
    this.coursePage.set(1);
  }

  setMajor(value: string): void {
    this.selectedMajor.set(value);
    this.otherCoursesPage.set(1);
    this.coursePage.set(1);
  }

  isLoggedIn(): boolean {
    return this.isUserLoggedIn();
  }

  hasPurchasedOverflow(): boolean {
    return this.purchasedCoursesList().length > this.purchasedPreviewLimit;
  }

  openPurchasedPopup(): void {
    this.showPurchasedPopup.set(true);
  }

  closePurchasedPopup(): void {
    this.showPurchasedPopup.set(false);
  }

  goToOtherPage(page: number): void {
    const total = this.totalOtherPages();

    if (page < 1 || page > total) {
      return;
    }

    this.otherCoursesPage.set(page);
  }

  goToPrevOtherPage(): void {
    this.goToOtherPage(this.otherCoursesPage() - 1);
  }

  goToNextOtherPage(): void {
    this.goToOtherPage(this.otherCoursesPage() + 1);
  }

  loadCourses(): void {
    this.loadingCourses.set(true);
    this.loadError.set('');

    this.http
      .get<{ courses?: any[] }>(`${this.apiUrl}/api/courses`, {
        withCredentials: true,
        headers: this.getAuthHeaders(),
      })
      .pipe(finalize(() => this.loadingCourses.set(false)))
      .subscribe({
        next: (res) => {
          const rawCourses = res?.courses ?? [];
          const normalizedCourses = rawCourses.map((item) =>
            this.normalizeCourse(item)
          );

          if (!normalizedCourses.length) {
            this.allCourses.set([]);
            this.purchasedCourseIds.set([]);
            this.lessonHistories.set({});
            this.selectedAnswers.set({});
            this.lockedQuestions.set({});
            return;
          }

          this.loadLessonsForCourses(normalizedCourses);
        },
        error: (error) => {
          console.error('Load courses error:', error);
          this.allCourses.set([]);
          this.purchasedCourseIds.set([]);
          this.lessonHistories.set({});
          this.selectedAnswers.set({});
          this.lockedQuestions.set({});
          this.loadError.set('Không tải được danh sách khóa học từ hệ thống.');
        },
      });
  }

  private loadLessonsForCourses(courses: CourseItem[]): void {
    const lessonRequests = courses.map((course) =>
      this.http
        .get<any>(`${this.apiUrl}/api/courses/${course.id}/lessons`, {
          withCredentials: true,
          headers: this.getAuthHeaders(),
        })
        .pipe(
          map((res) => ({
            courseId: course.id,
            lessons: (res?.lessons || []).map((lesson: any) =>
              this.normalizeLesson(lesson, course.id)
            ),
          })),
          catchError((error) => {
            console.error(
              `Load public lessons error for course ${course.id}:`,
              error
            );

            return of({
              courseId: course.id,
              lessons: [] as LessonItem[],
            });
          })
        )
    );

    forkJoin(lessonRequests).subscribe({
      next: (lessonResults) => {
        const lessonMap = new Map<number, LessonItem[]>();

        lessonResults.forEach((item) => {
          lessonMap.set(item.courseId, item.lessons);
        });

        const mergedCourses = courses.map((course) => ({
          ...course,
          lessons: lessonMap.get(course.id) || [],
        }));

        this.allCourses.set(mergedCourses);
        this.mergePurchasedIdsFromApi(mergedCourses);
        this.applyPurchasedStateFromApi();
        this.loadQuizHistoriesFromApi(false);
        this.normalizeCurrentPage();
      },
      error: (error) => {
        console.error('Load course lessons error:', error);

        this.allCourses.set(courses);
        this.mergePurchasedIdsFromApi(courses);
        this.applyPurchasedStateFromApi();
        this.loadQuizHistoriesFromApi(false);
        this.normalizeCurrentPage();
      },
    });
  }

  reloadCourses(): void {
    this.resolveCourseAccess();
  }

  private normalizeCurrentPage(): void {
    const total = this.totalOtherPages();

    if (this.otherCoursesPage() > total) {
      this.otherCoursesPage.set(total);
    }

    if (this.otherCoursesPage() < 1) {
      this.otherCoursesPage.set(1);
    }
  }

  purchasedCourses(): CourseItem[] {
    return this.purchasedCoursesList();
  }

  otherCourses(): CourseItem[] {
    return this.otherCoursesList();
  }

  isPurchased(courseId?: number | null): boolean {
    if (!courseId) return false;

    if (this.canAccessCourses()) {
      return true;
    }

    const normalizedId = Number(courseId);
    const course = this.allCourses().find(
      (item) => Number(item.id) === normalizedId
    );

    return Boolean(course?.is_purchased);
  }

  getCourseLessons(course: CourseItem | null): LessonItem[] {
    if (!course || !Array.isArray(course.lessons)) {
      return [];
    }

    return [...course.lessons].sort(
      (a, b) => (a.sort_order || 0) - (b.sort_order || 0)
    );
  }

  openPreview(item: CourseItem): void {
    if (!this.canAccessCourses()) {
      this.notify(
        'info',
        'Chưa mở khóa khóa học',
        'Chỉ tài khoản thuộc gói nâng cao 99k mới xem và học khóa học.'
      );
      return;
    }

    this.selectedCourse.set(item);
    this.showPreviewModal.set(true);
  }

  closePreview(): void {
    this.showPreviewModal.set(false);
    this.selectedCourse.set(null);
  }

  openPayment(): void {
    if (!this.canAccessCourses()) {
      return;
    }

    this.showPreviewModal.set(false);
    this.showPaymentModal.set(true);
  }

  closePayment(): void {
    this.showPaymentModal.set(false);
  }

  confirmPaid(): void {
    this.notify(
      'info',
      'Thanh toán gói học',
      'Khóa học được mở khi bạn mua gói học đầy đủ.'
    );

    this.showPaymentModal.set(false);
  }

  openLearningPopup(course: CourseItem): void {
    if (!this.canAccessCourses()) {
      this.notify(
        'info',
        'Chưa mở khóa khóa học',
        'Chỉ tài khoản thuộc gói nâng cao 99k mới có thể học các khóa học.'
      );
      return;
    }

    const lessons = this.getCourseLessons(course);

    this.learningCourse.set(course);
    this.selectedLesson.set(lessons.length ? lessons[0] : null);
    this.showLearningModal.set(true);

    this.schedulePlayerInit();
    this.restoreAnswersForSelectedLesson();
  }

  closeLearningPopup(): void {
    this.showLearningModal.set(false);
    this.learningCourse.set(null);
    this.selectedLesson.set(null);
    this.currentYoutubeLessonId = null;
    this.destroyPlayer();
  }

  learningLessons(): LessonItem[] {
    return this.getCourseLessons(this.learningCourse());
  }

  selectLesson(lesson: LessonItem): void {
    this.selectedLesson.set(lesson);
    this.schedulePlayerInit();
    this.restoreAnswersForSelectedLesson();
  }

  isLessonCompleted(lessonId?: number | null): boolean {
    if (!lessonId) {
      return false;
    }

    return this.completedLessonIds().includes(Number(lessonId));
  }

  selectedLessonCompleted(): boolean {
    return this.isLessonCompleted(this.selectedLesson()?.id);
  }

  hasPlayableVideo(): boolean {
    const lesson = this.selectedLesson();
    const rawUrl = lesson?.video_url?.trim();

    if (!rawUrl) {
      return false;
    }

    return Boolean(this.parseYoutubeVideoId(rawUrl) || this.toEmbedUrl(rawUrl));
  }

  isSelectedLessonYoutube(): boolean {
    const lesson = this.selectedLesson();
    const rawUrl = lesson?.video_url?.trim();

    if (!rawUrl) {
      return false;
    }

    return Boolean(this.parseYoutubeVideoId(rawUrl));
  }

  fallbackVideoUrl(): SafeResourceUrl | null {
    const lesson = this.selectedLesson();
    const rawUrl = lesson?.video_url?.trim();

    if (!rawUrl) {
      return null;
    }

    const embedUrl = this.toEmbedUrl(rawUrl);

    if (!embedUrl) {
      return null;
    }

    return this.sanitizer.bypassSecurityTrustResourceUrl(embedUrl);
  }

  hasLessonQuestions(): boolean {
    return this.selectedLessonQuestions().length > 0;
  }

  trackByQuestionIndex(index: number): number {
    return index;
  }

  trackByOptionIndex(index: number): number {
    return index;
  }

  goLogin(): void {
    this.router.navigateByUrl('/login');
  }

  closeAlert(): void {
    this.showAlert.set(false);
    this.alertCountdown.set(0);
    this.clearAlertTimer();
  }

  private buildQuestionKey(question: QuestionItem, qIndex: number): string {
    const lessonId = this.selectedLesson()?.id ?? 'lesson';
    const questionId = question?.id ?? qIndex;

    return `${lessonId}_${questionId}`;
  }

  private buildHistoryQuestionId(question: QuestionItem, qIndex: number): string {
    return String(question?.id ?? qIndex);
  }

  isQuestionLocked(question: QuestionItem, qIndex: number): boolean {
    const key = this.buildQuestionKey(question, qIndex);
    return Boolean(this.lockedQuestions()[key]);
  }

  selectQuestionOption(
    question: QuestionItem,
    qIndex: number,
    optionIndex: number
  ): void {
    if (this.isQuestionLocked(question, qIndex)) {
      return;
    }

    const key = this.buildQuestionKey(question, qIndex);

    this.selectedAnswers.update((current) => ({
      ...current,
      [key]: optionIndex,
    }));
  }

  getSelectedOptionIndex(question: QuestionItem, qIndex: number): number | null {
    const key = this.buildQuestionKey(question, qIndex);
    const value = this.selectedAnswers()[key];

    return typeof value === 'number' ? value : null;
  }

  hasAnsweredQuestion(question: QuestionItem, qIndex: number): boolean {
    return this.getSelectedOptionIndex(question, qIndex) !== null;
  }

  isOptionSelected(
    question: QuestionItem,
    qIndex: number,
    optionIndex: number
  ): boolean {
    return this.getSelectedOptionIndex(question, qIndex) === optionIndex;
  }

  isOptionCorrect(
    question: QuestionItem,
    qIndex: number,
    optionIndex: number
  ): boolean {
    if (!this.isQuestionLocked(question, qIndex)) {
      return false;
    }

    return Boolean(question.options?.[optionIndex]?.is_correct);
  }

  isSelectedOptionWrong(
    question: QuestionItem,
    qIndex: number,
    optionIndex: number
  ): boolean {
    if (!this.isQuestionLocked(question, qIndex)) {
      return false;
    }

    const selectedIndex = this.getSelectedOptionIndex(question, qIndex);

    return (
      selectedIndex === optionIndex &&
      !Boolean(question.options?.[optionIndex]?.is_correct)
    );
  }

  getQuestionResultText(question: QuestionItem, qIndex: number): string {
    if (!this.isQuestionLocked(question, qIndex)) {
      return '';
    }

    return this.isQuestionAnsweredCorrectly(question, qIndex)
      ? 'Chính xác'
      : 'Chưa đúng';
  }

  getQuestionResultClass(
    question: QuestionItem,
    qIndex: number
  ): 'is-correct' | 'is-wrong' | '' {
    if (!this.isQuestionLocked(question, qIndex)) {
      return '';
    }

    return this.isQuestionAnsweredCorrectly(question, qIndex)
      ? 'is-correct'
      : 'is-wrong';
  }

  isQuestionAnsweredCorrectly(question: QuestionItem, qIndex: number): boolean {
    const selectedIndex = this.getSelectedOptionIndex(question, qIndex);

    if (selectedIndex === null) {
      return false;
    }

    return Boolean(question.options?.[selectedIndex]?.is_correct);
  }

  selectedLessonQuestionCount(): number {
    return this.selectedLessonQuestions().length;
  }

  selectedLessonAnsweredCount(): number {
    const questions = this.selectedLessonQuestions();

    return questions.filter((question, qIndex) => {
      return this.getSelectedOptionIndex(question, qIndex) !== null;
    }).length;
  }

  selectedLessonSubmitted(): boolean {
    const questions = this.selectedLessonQuestions();

    if (!questions.length) {
      return false;
    }

    return questions.every((question, qIndex) =>
      this.isQuestionLocked(question, qIndex)
    );
  }

  canSubmitSelectedLesson(): boolean {
    const questions = this.selectedLessonQuestions();

    if (
      !questions.length ||
      this.selectedLessonSubmitted() ||
      this.submittingLessonQuiz()
    ) {
      return false;
    }

    return questions.every((question, qIndex) => {
      return this.getSelectedOptionIndex(question, qIndex) !== null;
    });
  }

  confirmSubmitSelectedLesson(): void {
    const questions = this.selectedLessonQuestions();

    if (!questions.length) {
      this.notify(
        'info',
        'Chưa có câu hỏi',
        'Bài học này chưa có câu hỏi để nộp.'
      );
      return;
    }

    if (!this.canSubmitSelectedLesson()) {
      this.notify(
        'info',
        'Chưa hoàn thành bài làm',
        `Bạn đã chọn ${this.selectedLessonAnsweredCount()}/${this.selectedLessonQuestionCount()} câu. Vui lòng chọn đủ đáp án trước khi nộp bài.`
      );
      return;
    }

    this.showSubmitConfirmModal.set(true);
  }

  closeSubmitConfirmModal(): void {
    if (this.submittingLessonQuiz()) {
      return;
    }

    this.showSubmitConfirmModal.set(false);
  }

  confirmSubmitFromPopup(): void {
    if (this.submittingLessonQuiz()) {
      return;
    }

    this.showSubmitConfirmModal.set(false);
    this.submitSelectedLesson();
  }

  private submitSelectedLesson(): void {
    const lesson = this.selectedLesson();
    const questions = this.selectedLessonQuestions();

    if (!lesson?.id || !questions.length) {
      return;
    }

    this.submittingLessonQuiz.set(true);

    const requests = questions.map((question, qIndex) => {
      const selectedIndex = this.getSelectedOptionIndex(question, qIndex);

      if (selectedIndex === null || !question?.id) {
        return of(null);
      }

      const selectedLabel = this.optionIndexToLabel(selectedIndex);

      return this.http.post(
        `${this.apiUrl}/api/course-quiz-history/answer`,
        {
          lesson_id: Number(lesson.id),
          quiz_id: Number(question.id),
          selected_answer: selectedLabel,
        },
        {
          withCredentials: true,
          headers: this.getAuthHeaders(),
        }
      );
    });

    forkJoin(requests)
      .pipe(
        finalize(() => {
          this.submittingLessonQuiz.set(false);
        })
      )
      .subscribe({
        next: () => {
          const nextLocks = { ...this.lockedQuestions() };

          questions.forEach((question, qIndex) => {
            const key = this.buildQuestionKey(question, qIndex);
            nextLocks[key] = true;
          });

          this.lockedQuestions.set(nextLocks);
          this.loadQuizHistoriesFromApi(false);

          this.notify(
            'success',
            'Nộp bài thành công',
            'Hệ thống đã lưu câu trả lời của bạn.'
          );
        },
        error: (error) => {
          console.error('Submit lesson quiz error:', error);

          this.notify(
            'error',
            'Không nộp được bài',
            error?.error?.message || 'Không lưu được bài làm lên hệ thống.'
          );
        },
      });
  }

  private saveQuestionAnswerToHistory(
    question: QuestionItem,
    qIndex: number,
    optionIndex: number
  ): void {
    const lesson = this.selectedLesson();
    const option = question.options?.[optionIndex];

    if (!lesson?.id || !question?.id || !option) {
      return;
    }

    const selectedLabel = this.optionIndexToLabel(optionIndex);
    const key = this.buildQuestionKey(question, qIndex);

    this.http
      .post(
        `${this.apiUrl}/api/course-quiz-history/answer`,
        {
          lesson_id: Number(lesson.id),
          quiz_id: Number(question.id),
          selected_answer: selectedLabel,
        },
        {
          withCredentials: true,
          headers: this.getAuthHeaders(),
        }
      )
      .subscribe({
        next: () => {
          this.loadQuizHistoriesFromApi(false);
        },
        error: (error) => {
          console.error('Save course quiz answer error:', error);

          this.selectedAnswers.update((current) => {
            const next = { ...current };
            delete next[key];
            return next;
          });

          this.lockedQuestions.update((current) => {
            const next = { ...current };
            delete next[key];
            return next;
          });

          this.notify(
            'error',
            'Chưa đồng bộ được lịch sử',
            error?.error?.message || 'Không lưu được câu trả lời lên hệ thống.'
          );
        },
      });
  }

  private loadQuizHistoriesFromApi(showError = false): void {
    if (typeof window === 'undefined') {
      return;
    }

    const token = localStorage.getItem('auth_token');

    if (!token) {
      this.lessonHistories.set({});
      this.selectedAnswers.set({});
      this.lockedQuestions.set({});
      return;
    }

    this.http
      .get<any>(`${this.apiUrl}/api/course-quiz-history`, {
        withCredentials: true,
        headers: this.getAuthHeaders(),
      })
      .subscribe({
        next: (res) => {
          const rawItems = Array.isArray(res?.histories)
            ? res.histories
            : Array.isArray(res?.data)
              ? res.data
              : Array.isArray(res)
                ? res
                : [];

          const store: LessonHistoryStore = {};

          rawItems.forEach((item: any) => {
            const history = this.normalizeLessonHistory(item);

            if (history?.lessonId) {
              store[String(history.lessonId)] = history;
            }
          });

          this.lessonHistories.set(store);
          this.restoreAllAnswersAndLocksFromHistory();
          this.restoreAnswersForSelectedLesson();
        },
        error: (error) => {
          console.error('Load course quiz history error:', error);

          if (showError) {
            this.notify(
              'error',
              'Không tải được lịch sử học tập',
              error?.error?.message || 'Vui lòng thử lại sau.'
            );
          }
        },
      });
  }

  private normalizeLessonHistory(item: any): LessonHistoryItem | null {
    const lessonId = Number(item?.lesson_id ?? item?.lessonId ?? 0);

    if (!lessonId) {
      return null;
    }

    const rawQuestions = Array.isArray(item?.questions) ? item.questions : [];

    const questions: HistoryQuestionItem[] = rawQuestions.map((question: any) => {
      const rawOptions = Array.isArray(question?.options)
        ? question.options
        : [];

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

  private restoreAnswersForSelectedLesson(): void {
    const lesson = this.selectedLesson();

    if (!lesson?.id) {
      return;
    }

    const lessonHistory = this.lessonHistories()[String(lesson.id)];

    if (!lessonHistory?.questions?.length) {
      return;
    }

    const lessonQuestions = this.selectedLessonQuestions();

    if (!lessonQuestions.length) {
      return;
    }

    const restoredAnswers = { ...this.selectedAnswers() };
    const restoredLocks = { ...this.lockedQuestions() };

    lessonQuestions.forEach((question, qIndex) => {
      const questionId = this.buildHistoryQuestionId(question, qIndex);
      const historyItem = lessonHistory.questions.find(
        (item) => item.questionId === questionId
      );

      if (historyItem) {
        const key = this.buildQuestionKey(question, qIndex);
        restoredAnswers[key] = historyItem.selectedOptionIndex;
        restoredLocks[key] = true;
      }
    });

    this.selectedAnswers.set(restoredAnswers);
    this.lockedQuestions.set(restoredLocks);
  }

  private restoreAllAnswersAndLocksFromHistory(): void {
    const restoredAnswers: Record<string, number> = {};
    const restoredLocks: Record<string, boolean> = {};

    const courses = this.allCourses();
    const histories = this.lessonHistories();

    courses.forEach((course) => {
      (course.lessons || []).forEach((lesson) => {
        if (!lesson?.id || !lesson.questions?.length) {
          return;
        }

        const lessonHistory = histories[String(lesson.id)];

        if (!lessonHistory?.questions?.length) {
          return;
        }

        lesson.questions.forEach((question, qIndex) => {
          const questionId = this.buildHistoryQuestionId(question, qIndex);
          const historyItem = lessonHistory.questions.find(
            (item) => item.questionId === questionId
          );

          if (historyItem) {
            const key = `${lesson.id}_${question.id ?? qIndex}`;
            restoredAnswers[key] = historyItem.selectedOptionIndex;
            restoredLocks[key] = true;
          }
        });
      });
    });

    this.selectedAnswers.set(restoredAnswers);
    this.lockedQuestions.set(restoredLocks);
  }

  private schedulePlayerInit(): void {
    if (this.pendingPlayerInitTimer) {
      clearTimeout(this.pendingPlayerInitTimer);
      this.pendingPlayerInitTimer = null;
    }

    if (!this.showLearningModal()) {
      return;
    }

    this.pendingPlayerInitTimer = setTimeout(() => {
      this.pendingPlayerInitTimer = null;
      this.initPlayerForSelectedLesson();
    }, 0);
  }

  private initPlayerForSelectedLesson(): void {
    const lesson = this.selectedLesson();
    const rawUrl = lesson?.video_url?.trim();

    if (!rawUrl) {
      this.currentYoutubeLessonId = null;
      this.destroyPlayer();
      return;
    }

    const youtubeId = this.parseYoutubeVideoId(rawUrl);

    if (!youtubeId) {
      this.currentYoutubeLessonId = null;
      this.destroyPlayer();
      return;
    }

    this.ensureYoutubeApiLoaded()
      .then(() => {
        if (!this.showLearningModal()) {
          return;
        }

        const currentLesson = this.selectedLesson();
        const currentRawUrl = currentLesson?.video_url?.trim() || '';
        const currentVideoId = this.parseYoutubeVideoId(currentRawUrl);

        if (!currentLesson?.id || !currentVideoId) {
          this.destroyPlayer();
          return;
        }

        this.currentYoutubeLessonId = Number(currentLesson.id);

        if (this.player && typeof this.player.loadVideoById === 'function') {
          this.player.loadVideoById(currentVideoId);
          return;
        }

        this.createYoutubePlayer(currentVideoId);
      })
      .catch((error) => {
        console.error('YouTube API load error:', error);
      });
  }

  private ensureYoutubeApiLoaded(): Promise<void> {
    if (window.YT && window.YT.Player) {
      return Promise.resolve();
    }

    if (this.youtubeApiPromise) {
      return this.youtubeApiPromise;
    }

    this.youtubeApiPromise = new Promise<void>((resolve, reject) => {
      const existingScript = document.querySelector(
        'script[src="https://www.youtube.com/iframe_api"]'
      ) as HTMLScriptElement | null;

      if (!existingScript) {
        const script = document.createElement('script');
        script.src = 'https://www.youtube.com/iframe_api';
        script.async = true;
        script.onerror = () =>
          reject(new Error('Không tải được YouTube Iframe API.'));
        document.body.appendChild(script);
      }

      const previousReady = window.onYouTubeIframeAPIReady;

      window.onYouTubeIframeAPIReady = () => {
        previousReady?.();
        resolve();
      };

      const waitUntilReady = window.setInterval(() => {
        if (window.YT && window.YT.Player) {
          clearInterval(waitUntilReady);
          resolve();
        }
      }, 120);

      window.setTimeout(() => {
        if (window.YT && window.YT.Player) {
          clearInterval(waitUntilReady);
          resolve();
        }
      }, 1500);
    });

    return this.youtubeApiPromise;
  }

  private createYoutubePlayer(videoId: string): void {
    this.destroyPlayer();

    const hostElement = document.getElementById(this.youtubePlayerElementId);

    if (!hostElement || !(window.YT && window.YT.Player)) {
      return;
    }

    this.player = new window.YT.Player(this.youtubePlayerElementId, {
      videoId,
      width: '100%',
      height: '100%',
      playerVars: {
        rel: 0,
        modestbranding: 1,
        playsinline: 1,
      },
      events: {
        onStateChange: (event: any) => this.onYoutubePlayerStateChange(event),
      },
    });
  }

  private onYoutubePlayerStateChange(event: any): void {
    if (!window.YT || !window.YT.PlayerState) {
      return;
    }

    if (event?.data !== window.YT.PlayerState.ENDED) {
      return;
    }

    if (!this.currentYoutubeLessonId) {
      return;
    }

    const alreadyCompleted = this.isLessonCompleted(this.currentYoutubeLessonId);

    this.markLessonAsCompleted(this.currentYoutubeLessonId);

    if (!alreadyCompleted) {
      this.notify(
        'success',
        'Đã hoàn thành bài học',
        'Video đã xem xong. Bạn có thể trả lời câu hỏi, mỗi câu chỉ chọn 1 lần.'
      );
    }
  }

  private markLessonAsCompleted(lessonId: number): void {
    const normalizedId = Number(lessonId);

    if (!normalizedId || this.completedLessonIds().includes(normalizedId)) {
      return;
    }

    const nextIds = [...this.completedLessonIds(), normalizedId];
    this.completedLessonIds.set(nextIds);
    this.writeCompletedLessonIdsToStorage(nextIds);
  }

  private destroyPlayer(): void {
    if (this.player && typeof this.player.destroy === 'function') {
      this.player.destroy();
    }

    this.player = null;
  }

  private normalizeCourse(item: any): CourseItem {
    const thumbnailValue =
      item?.thumbnail_url ||
      item?.thumbnail ||
      item?.image ||
      item?.image_url ||
      null;

    return {
      id: Number(item?.id || 0),
      name: item?.name || item?.title || 'Chưa có tên khóa học',
      thumbnail: this.normalizeAssetUrl(thumbnailValue),
      short_description:
        item?.short_description ||
        item?.summary ||
        item?.excerpt ||
        null,
      description:
        item?.description ||
        item?.content ||
        item?.details ||
        null,
      course_major:
        item?.course_major ||
        item?.major_name ||
        item?.major ||
        item?.category ||
        null,
      price: Number(item?.price || 0),
      is_purchased:
        Boolean(item?.is_purchased) ||
        Boolean(item?.purchased) ||
        Boolean(item?.has_access) ||
        this.purchasedCourseIds().includes(Number(item?.id || 0)),
      lessons: [],
    };
  }

  private normalizeLesson(lesson: any, courseId: number): LessonItem {
    return {
      id: Number(lesson?.id || 0),
      service_package_id: Number(
        lesson?.service_package_id || lesson?.course_id || courseId || 0
      ),
      title: lesson?.title || lesson?.name || 'Chưa có tên bài học',
      description: lesson?.description || lesson?.content || null,
      video_url:
        lesson?.video_url || lesson?.video || lesson?.video_link || null,
      duration: lesson?.duration || lesson?.time || null,
      sort_order: Number(lesson?.sort_order || lesson?.order || 0),
      is_active:
        typeof lesson?.is_active === 'boolean'
          ? lesson.is_active
          : lesson?.status === 'active' || lesson?.status === 'published',
      questions: this.normalizeQuestions(
        lesson?.questions ||
          lesson?.quiz_questions ||
          lesson?.lesson_questions ||
          lesson?.quizzes ||
          []
      ),
    };
  }

  private normalizeQuestions(rawQuestions: any[]): QuestionItem[] {
    if (!Array.isArray(rawQuestions)) {
      return [];
    }

    return rawQuestions.map((question: any) => {
      let rawOptions =
        question?.options ||
        question?.answers ||
        question?.choices ||
        [];

      if (
        (!Array.isArray(rawOptions) || rawOptions.length === 0) &&
        question?.option_a
      ) {
        const correctAnswer = String(question?.correct_answer || '').toUpperCase();

        rawOptions = [
          {
            label: 'A',
            content: question?.option_a || '',
            is_correct: correctAnswer === 'A',
          },
          {
            label: 'B',
            content: question?.option_b || '',
            is_correct: correctAnswer === 'B',
          },
          {
            label: 'C',
            content: question?.option_c || '',
            is_correct: correctAnswer === 'C',
          },
          {
            label: 'D',
            content: question?.option_d || '',
            is_correct: correctAnswer === 'D',
          },
        ].filter((option) => String(option.content || '').trim().length > 0);
      }

      return {
        id: Number(question?.id || 0) || undefined,
        question:
          question?.question ||
          question?.content ||
          question?.title ||
          'Câu hỏi chưa có nội dung',
        explanation:
          question?.explanation ||
          question?.description ||
          question?.note ||
          null,
        options: this.normalizeQuestionOptions(rawOptions),
      };
    });
  }

  private normalizeQuestionOptions(rawOptions: any[]): QuestionOptionItem[] {
    if (!Array.isArray(rawOptions)) {
      return [];
    }

    return rawOptions.map((option: any) => ({
      id: Number(option?.id || 0) || undefined,
      content:
        option?.content ||
        option?.answer ||
        option?.text ||
        option?.label ||
        'Đáp án chưa có nội dung',
      is_correct:
        typeof option?.is_correct === 'boolean'
          ? option.is_correct
          : Boolean(option?.isCorrect),
    }));
  }

  private normalizeAssetUrl(path: string | null): string | null {
    if (!path) {
      return null;
    }

    if (/^https?:\/\//i.test(path)) {
      return path;
    }

    if (path.startsWith('/storage/') || path.startsWith('storage/')) {
      return path.startsWith('/') ? path : `/${path}`;
    }

    return path;
  }

  private mergePurchasedIdsFromApi(courses: CourseItem[]): void {
    const apiIds = courses
      .filter((item) => item.is_purchased)
      .map((item) => Number(item.id))
      .filter((id) => id > 0);

    this.purchasedCourseIds.set(Array.from(new Set(apiIds)));
  }

  private applyPurchasedStateFromApi(): void {
    const purchasedIds = new Set(this.purchasedCourseIds());

    this.allCourses.update((courses) =>
      courses.map((item) => ({
        ...item,
        is_purchased:
          Boolean(item.is_purchased) || purchasedIds.has(Number(item.id)),
      }))
    );
  }

  private readCompletedLessonIdsFromStorage(): number[] {
    try {
      const raw = localStorage.getItem(this.completedLessonIdsStorageKey);

      if (!raw) {
        return [];
      }

      const parsed = JSON.parse(raw);

      if (!Array.isArray(parsed)) {
        return [];
      }

      return parsed
        .map((item) => Number(item))
        .filter((item) => Number.isFinite(item) && item > 0);
    } catch {
      return [];
    }
  }

  private writeCompletedLessonIdsToStorage(ids: number[]): void {
    try {
      localStorage.setItem(
        this.completedLessonIdsStorageKey,
        JSON.stringify(ids)
      );
    } catch {
      // ignore
    }
  }

  private getCurrentUserId(): number | string {
    if (typeof window === 'undefined') {
      return 'guest';
    }

    try {
      const raw = localStorage.getItem('auth_user');

      if (!raw) {
        return 'guest';
      }

      const user = JSON.parse(raw);

      return user?.id || 'guest';
    } catch {
      return 'guest';
    }
  }

  private get completedLessonIdsStorageKey(): string {
    return `completedCourseLessonIds_${this.getCurrentUserId()}`;
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

  private optionIndexToLabel(index: number): 'A' | 'B' | 'C' | 'D' {
    return (['A', 'B', 'C', 'D'][index] || 'A') as 'A' | 'B' | 'C' | 'D';
  }

  private labelToOptionIndex(label: string): number {
    const normalizedLabel = String(label || '').toUpperCase();
    const index = ['A', 'B', 'C', 'D'].indexOf(normalizedLabel);

    return index >= 0 ? index : 0;
  }

  private parseYoutubeVideoId(url: string): string | null {
    try {
      const trimmed = url.trim();

      if (!trimmed) {
        return null;
      }

      if (/^[a-zA-Z0-9_-]{11}$/.test(trimmed)) {
        return trimmed;
      }

      if (trimmed.includes('youtu.be/')) {
        const id = trimmed.split('youtu.be/')[1]?.split(/[?&/]/)[0];
        return id || null;
      }

      if (trimmed.includes('youtube.com/watch')) {
        const urlObj = new URL(trimmed);
        return urlObj.searchParams.get('v');
      }

      if (trimmed.includes('youtube.com/embed/')) {
        const match = trimmed.match(/embed\/([^?&/]+)/);
        return match?.[1] || null;
      }

      if (trimmed.includes('youtube.com/shorts/')) {
        const match = trimmed.match(/shorts\/([^?&/]+)/);
        return match?.[1] || null;
      }

      return null;
    } catch {
      return null;
    }
  }

  private toEmbedUrl(url: string): string | null {
    try {
      const youtubeId = this.parseYoutubeVideoId(url);

      if (youtubeId) {
        return `https://www.youtube.com/embed/${youtubeId}`;
      }

      if (url.includes('drive.google.com/file/d/')) {
        const match = url.match(/\/file\/d\/([^/]+)/);
        const id = match?.[1];

        return id ? `https://drive.google.com/file/d/${id}/preview` : null;
      }

      if (url.includes('drive.google.com/open?id=')) {
        const urlObj = new URL(url);
        const id = urlObj.searchParams.get('id');

        return id ? `https://drive.google.com/file/d/${id}/preview` : null;
      }

      return url;
    } catch {
      return null;
    }
  }

  private clearAlertTimer(): void {
    if (this.alertTimer) {
      clearInterval(this.alertTimer);
      this.alertTimer = null;
    }
  }

  private notify(
    type: 'success' | 'error' | 'info',
    title: string,
    message: string
  ): void {
    this.clearAlertTimer();

    this.alertType.set(type);
    this.alertTitle.set(title);
    this.alertMessage.set(message);
    this.showAlert.set(true);
    this.alertCountdown.set(3);

    this.alertTimer = setInterval(() => {
      const next = this.alertCountdown() - 1;
      this.alertCountdown.set(next);

      if (next <= 0) {
        this.clearAlertTimer();
        this.showAlert.set(false);
      }
    }, 1000);
  }

  goToCoursePage(page: number): void {
    if (page < 1 || page > this.totalCoursePages()) return;

    this.coursePage.set(page);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  prevCoursePage(): void {
    this.goToCoursePage(this.coursePage() - 1);
  }

  nextCoursePage(): void {
    this.goToCoursePage(this.coursePage() + 1);
  }
}