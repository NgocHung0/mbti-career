import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterModule } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { timeout } from 'rxjs/operators';
import { ResultApiService } from '../../services/result-api.service';

type Question = {
  id: number;
  question: string;
  optionA: string;
  optionB: string;
  axis: string;
  dirA: string;
  dirB: string;
};

type RawKey =
  | 'CREATIVE'
  | 'ANALYTIC'
  | 'SOCIAL'
  | 'TECH'
  | 'FREEDOM'
  | 'STRUCTURE'
  | 'MEDIA'
  | 'HUMAN'
  | 'PRODUCT'
  | 'TEAM'
  | 'INDIVIDUAL'
  | 'LOGIC'
  | 'ART'
  | 'BUSINESS'
  | 'FLEXIBLE'
  | 'STABLE'
  | 'EXPLORE'
  | 'OPTIMIZE';

type InterestRawScores = Record<RawKey, number>;
type InterestGroupKey = 'creative' | 'analytic' | 'social' | 'business';
type InterestGroupScores = Record<InterestGroupKey, number>;

@Component({
  selector: 'app-interest-test',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './interest-test.html',
  styleUrl: './interest-test.css'
})
export class InterestTest implements OnInit {
  readonly pageSize = 10;
  readonly basicQuestionCount = 30;
  readonly totalQuestionCount = 55;
  readonly questionsApiUrl = '/api/interest/questions?package_type=plus';

  activePlanLabel = 'Gói Plus - Test sở thích';
  currentPage = 1;
  pageError = '';
  loadingQuestions = false;
  questionsError = '';

  answers: Record<number, 'A' | 'B'> = {};
  questions: Question[] = [];

  constructor(
    private router: Router,
    private http: HttpClient,
    private resultApi: ResultApiService
  ) {}

  ngOnInit(): void {
    if (typeof window === 'undefined') return;

    const raw = localStorage.getItem('selected_upgrades');
    if (!raw) {
      this.router.navigateByUrl('/mbti-test');
      return;
    }

    try {
      const upgrades = JSON.parse(raw);
      if (!upgrades?.interest) {
        this.router.navigateByUrl('/mbti-test');
        return;
      }
    } catch (error) {
      console.error('selected_upgrades parse error:', error);
      localStorage.removeItem('selected_upgrades');
      this.router.navigateByUrl('/mbti-test');
      return;
    }

    this.currentPage = 1;
    this.pageError = '';
    this.questionsError = '';
    this.clearDraftPageOnly();

    const cachedQuestions = this.restoreQuestionCache();
    if (cachedQuestions.length) {
      this.questions = cachedQuestions;
      this.loadingQuestions = false;
      this.questionsError = '';
    }

    this.loadPlusQuestions();
  }

  private mapApiQuestion(item: any, index: number): Question | null {
    if (!item || typeof item !== 'object') {
      return null;
    }

    const id = Number(item.id ?? item.question_id ?? index + 1);

    const question = String(
      item.question ?? item.content ?? item.text ?? ''
    ).trim();

    const optionA = String(
      item.optionA ?? item.option_a ?? item.a ?? item.label_a ?? ''
    ).trim();

    const optionB = String(
      item.optionB ?? item.option_b ?? item.b ?? item.label_b ?? ''
    ).trim();

    const axis = String(
      item.axis ?? item.dimension ?? ''
    ).trim().toUpperCase();

    const dirA = String(
      item.dirA ?? item.dir_a ?? ''
    ).trim().toUpperCase();

    const dirB = String(
      item.dirB ?? item.dir_b ?? ''
    ).trim().toUpperCase();

    if (!question || !optionA || !optionB) {
      return null;
    }

    return {
      id,
      question,
      optionA,
      optionB,
      axis,
      dirA,
      dirB
    };
  }

  loadPlusQuestions(): void {
    this.loadingQuestions = this.questions.length === 0;
    this.questionsError = '';
    this.pageError = '';

    this.http.get<any>(this.questionsApiUrl)
      .pipe(timeout(4000))
      .subscribe({
        next: (res) => {
          try {
            const rawList: any[] =
              Array.isArray(res?.questions) ? res.questions :
              Array.isArray(res?.data) ? res.data :
              Array.isArray(res?.items) ? res.items :
              Array.isArray(res) ? res :
              [];

            const mapped = rawList
              .map((item: any, index: number) => this.mapApiQuestion(item, index))
              .filter((item: Question | null): item is Question => !!item);

            if (!mapped.length) {
              this.loadingQuestions = false;
              this.questionsError = 'API có dữ liệu nhưng frontend map ra rỗng.';
              return;
            }

            this.questions = mapped;
            this.saveQuestionCache(mapped);

            this.restoreDraftAnswers();
            this.currentPage = 1;
            this.loadingQuestions = false;

            console.log('plus questions mapped = ', mapped);
          } catch (error) {
            console.error('[interest] process error:', error);
            this.loadingQuestions = false;
            this.questionsError = 'Có lỗi khi xử lý dữ liệu câu hỏi.';
          }
        },
        error: (error) => {
          console.error('[interest] load error:', error);
          this.loadingQuestions = false;

          if (!this.questions.length) {
            this.questionsError =
              error?.name === 'TimeoutError'
                ? 'Tải câu hỏi quá lâu. Vui lòng thử lại.'
                : 'Không tải được câu hỏi sở thích từ Admin.';
          }
        }
      });
  }

  private scrollToFirstQuestion(): void {
    if (typeof window === 'undefined') return;

    setTimeout(() => {
      const firstQuestion = document.querySelector('.first-question-item') as HTMLElement | null;
      const fallback =
        document.getElementById('questionCardTop') ||
        document.getElementById('questionSection');

      const target = firstQuestion || fallback;
      if (!target) return;

      const headerOffset = 140;
      const y = target.getBoundingClientRect().top + window.scrollY - headerOffset;

      window.scrollTo({
        top: Math.max(0, y),
        behavior: 'smooth'
      });
    }, 80);
  }

  get totalPages(): number {
    return this.questions.length
      ? Math.ceil(this.questions.length / this.pageSize)
      : 1;
  }

  get pagedQuestions(): Question[] {
    const start = (this.currentPage - 1) * this.pageSize;
    return this.questions.slice(start, start + this.pageSize);
  }

  get answeredCount(): number {
    return Object.keys(this.answers).length;
  }

  get progressPercent(): number {
    if (!this.totalQuestionCount) return 0;
    const value = ((this.basicQuestionCount + this.answeredCount) / this.totalQuestionCount) * 100;
    return Math.max(0, Math.min(100, value));
  }

  getQuestionDisplayNumber(indexOnPage: number): number {
    return this.basicQuestionCount + ((this.currentPage - 1) * this.pageSize) + indexOnPage + 1;
  }

  trackQuestion(_: number, q: Question): number {
    return q.id;
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
      this.scrollToQuestion(unanswered.id);
      return;
    }

    if (this.currentPage < this.totalPages) {
      this.pageError = '';
      this.currentPage++;
      this.persistDraftPage();

      setTimeout(() => {
        this.scrollToFirstQuestion();
      }, 50);
    }
  }

  prevPage(): void {
    if (this.currentPage > 1) {
      this.pageError = '';
      this.currentPage--;
      this.persistDraftPage();

      setTimeout(() => {
        this.scrollToFirstQuestion();
      }, 50);
    }
  }

  private buildRawScores(): InterestRawScores {

    const rawScores: InterestRawScores = {
      CREATIVE: 0,
      ANALYTIC: 0,
      SOCIAL: 0,
      TECH: 0,
      FREEDOM: 0,
      STRUCTURE: 0,
      MEDIA: 0,
      HUMAN: 0,
      PRODUCT: 0,
      TEAM: 0,
      INDIVIDUAL: 0,
      LOGIC: 0,
      ART: 0,
      BUSINESS: 0,
      FLEXIBLE: 0,
      STABLE: 0,
      EXPLORE: 0,
      OPTIMIZE: 0
    };

    for (const q of this.questions) {

      const answer = this.answers[q.id];
      if (!answer) continue;

      const axisParts = String(q.axis || '')
        .split('/')
        .map(v => v.trim().toUpperCase());

      if (axisParts.length < 2) continue;

      const selectedKey =
        answer === 'A'
          ? axisParts[0]
          : axisParts[1];

      if (selectedKey in rawScores) {
        rawScores[selectedKey as RawKey] += 1;
      }
    }

    console.log('interest rawScores FIXED = ', rawScores);

    return rawScores;
  }

  private buildGroupScores(rawScores: InterestRawScores): InterestGroupScores {
    const groupScores: InterestGroupScores = {
      creative:
        rawScores.CREATIVE +
        rawScores.ART +
        rawScores.MEDIA +
        rawScores.FREEDOM +
        rawScores.EXPLORE,

      analytic:
        rawScores.ANALYTIC +
        rawScores.TECH +
        rawScores.LOGIC +
        rawScores.OPTIMIZE +
        rawScores.INDIVIDUAL,

      social:
        rawScores.SOCIAL +
        rawScores.HUMAN +
        rawScores.TEAM,

      business:
        rawScores.BUSINESS +
        rawScores.STRUCTURE +
        rawScores.PRODUCT +
        rawScores.STABLE
    };

    console.log('interest groupScores = ', groupScores);

    return groupScores;
  }

  private getTopGroups(groupScores: InterestGroupScores): Array<{ key: InterestGroupKey; value: number }> {
    return Object.entries(groupScores)
      .map(([key, value]) => ({
        key: key as InterestGroupKey,
        value
      }))
      .sort((a, b) => b.value - a.value);
  }

  submit(): void {
    const unansweredOnPage = this.pagedQuestions.find((q) => !this.answers[q.id]);

    if (unansweredOnPage) {
      this.pageError = 'Bạn cần trả lời hết các câu trên trang này trước khi nộp.';
      this.scrollToQuestion(unansweredOnPage.id);
      return;
    }

    const unansweredAll = this.questions.find((q) => !this.answers[q.id]);

    if (unansweredAll) {
      this.pageError = 'Bạn chưa trả lời hết tất cả câu hỏi sở thích.';

      const pageIndex = Math.floor(this.questions.findIndex((q) => q.id === unansweredAll.id) / this.pageSize);
      this.currentPage = pageIndex + 1;
      this.persistDraftPage();

      setTimeout(() => {
        this.scrollToQuestion(unansweredAll.id);
      }, 120);

      return;
    }

    const rawScores = this.buildRawScores();
    const groupScores = this.buildGroupScores(rawScores);
    const topGroups = this.getTopGroups(groupScores);

    console.log('interest submit payload = ', {
      answers: this.answers,
      rawScores,
      groupScores,
      topGroups
    });

    if (typeof window !== 'undefined') {
      localStorage.setItem(
        'interest_result',
        JSON.stringify({
          answers: this.answers,
          rawScores,
          groupScores,
          topGroups
        })
      );
    }

    if (typeof window !== 'undefined') {
      const token = localStorage.getItem('auth_token');

      if (token) {
        this.resultApi.saveInterestResult({
          answers: this.answers,
          raw_scores: rawScores,
          group_scores: groupScores,
          top_groups: topGroups
        }).subscribe({
          next: (res: any) => console.log('Saved interest result', res),
          error: (err: any) => console.error('Save interest failed', err)
        });
      }
    }

    this.clearDraftState();
    this.router.navigateByUrl('/interest-result');
  }

  private getDraftStorageKey(): string {
    if (typeof window === 'undefined') return 'interest_answers_draft';
    const sessionId = localStorage.getItem('test_session_id') || 'guest';
    return `interest_answers_draft_${sessionId}`;
  }

  private getDraftPageStorageKey(): string {
    return `${this.getDraftStorageKey()}__page`;
  }

  private getQuestionCacheKey(): string {
    return 'interest_plus_questions_cache';
  }

  private saveQuestionCache(questions: Question[]): void {
    if (typeof window === 'undefined') return;
    localStorage.setItem(this.getQuestionCacheKey(), JSON.stringify(questions));
  }

  private restoreQuestionCache(): Question[] {
    if (typeof window === 'undefined') return [];

    const raw = localStorage.getItem(this.getQuestionCacheKey());
    if (!raw) return [];

    try {
      const parsed = JSON.parse(raw);
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return [];
    }
  }

  private restoreDraftAnswers(): void {
    if (typeof window === 'undefined') return;

    const raw = localStorage.getItem(this.getDraftStorageKey());
    if (!raw) {
      this.answers = {};
      return;
    }

    try {
      const parsed = JSON.parse(raw);
      this.answers = parsed && typeof parsed === 'object' ? parsed : {};
    } catch {
      this.answers = {};
    }
  }

  private persistDraftAnswers(): void {
    if (typeof window === 'undefined') return;
    localStorage.setItem(this.getDraftStorageKey(), JSON.stringify(this.answers));
  }

  private persistDraftPage(): void {
    if (typeof window === 'undefined') return;
    localStorage.setItem(this.getDraftPageStorageKey(), String(this.currentPage));
  }

  private clearDraftPageOnly(): void {
    if (typeof window === 'undefined') return;
    localStorage.removeItem(this.getDraftPageStorageKey());
  }

  private clearDraftState(): void {
    if (typeof window === 'undefined') return;
    localStorage.removeItem(this.getDraftStorageKey());
    localStorage.removeItem(this.getDraftPageStorageKey());
  }

  private scrollToQuestion(questionId: number): void {
  if (typeof window === 'undefined') return;

  setTimeout(() => {
    const el = document.getElementById(`interest-question-${questionId}`);

    if (!el) {
      this.scrollToFirstQuestion();
      return;
    }

    const headerOffset = 140;
    const y = el.getBoundingClientRect().top + window.scrollY - headerOffset;

    window.scrollTo({
      top: Math.max(0, y),
      behavior: 'smooth'
    });

    el.classList.add('question-highlight');

    setTimeout(() => {
      el.classList.remove('question-highlight');
    }, 1800);
  }, 80);
}
}