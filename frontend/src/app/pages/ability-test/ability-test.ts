import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterModule } from '@angular/router';
import { ResultApiService } from '../../services/result-api.service';
import { UserPortalService } from '../../services/user-portal.service';

type AbilityQuestion = {
  id: number;
  question: string;
  optionA: string;
  optionB: string;
  axis: string;
};

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

type MbtiStoredResult = {
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

type InterestGroupKey = 'creative' | 'analytic' | 'social' | 'business';

type InterestFallback = {
  groupScores: Record<InterestGroupKey, number>;
  topGroups: Array<{ key: InterestGroupKey; value: number }>;
};

@Component({
  selector: 'app-ability-test',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './ability-test.html',
  styleUrl: './ability-test.css'
})
export class AbilityTest implements OnInit {
  readonly pageSize = 5;
  readonly basicQuestionCount = 10;
  readonly interestQuestionCount = 10;
  readonly totalQuestionCount = 30;
  readonly draftKey = 'ability_answers_draft';

  currentPage = 1;
  pageError = '';

  answers: Record<number, 'A' | 'B'> = {};

  questions: AbilityQuestion[] = [
    {
      id: 21,
      question: 'Khi tiếp cận một vấn đề mới, bạn mạnh hơn ở:',
      optionA: 'Diễn đạt ý tưởng bằng lời, viết hoặc nói',
      optionB: 'Phân tích logic để tìm quy luật',
      axis: 'LANGUAGE/LOGIC'
    },
    {
      id: 22,
      question: 'Bạn thường được khen về:',
      optionA: 'Sự sáng tạo, nhiều ý tưởng mới',
      optionB: 'Khả năng làm việc với công nghệ, công cụ',
      axis: 'CREATIVE/TECH'
    },
    {
      id: 23,
      question: 'Trong một nhóm, bạn thường:',
      optionA: 'Chủ động dẫn dắt, phân chia việc',
      optionB: 'Hỗ trợ, phối hợp để cả nhóm làm tốt',
      axis: 'LEADERSHIP/TEAMWORK'
    },
    {
      id: 24,
      question: 'Khi làm bài hoặc làm việc, bạn mạnh hơn ở:',
      optionA: 'Chú ý chi tiết, tránh sai sót',
      optionB: 'Thích ứng nhanh khi yêu cầu thay đổi',
      axis: 'DETAIL/ADAPT'
    },
    {
      id: 25,
      question: 'Bạn thấy mình giỏi hơn trong việc:',
      optionA: 'Làm ra thứ áp dụng được ngay',
      optionB: 'Nhìn bức tranh lớn và định hướng lâu dài',
      axis: 'PRACTICAL/STRATEGIC'
    },
    {
      id: 26,
      question: 'Nếu phải trình bày trước lớp, bạn:',
      optionA: 'Tự tin nói và diễn đạt',
      optionB: 'Thích chuẩn bị lập luận logic chặt chẽ',
      axis: 'LANGUAGE/LOGIC'
    },
    {
      id: 27,
      question: 'Khi nhận một nhiệm vụ mới, bạn thích:',
      optionA: 'Nghĩ ra cách làm khác biệt',
      optionB: 'Tìm công cụ hoặc giải pháp kỹ thuật hiệu quả',
      axis: 'CREATIVE/TECH'
    },
    {
      id: 28,
      question: 'Trong một dự án chung, bạn phù hợp hơn với:',
      optionA: 'Vai trò điều phối, ra quyết định',
      optionB: 'Vai trò cộng tác và kết nối mọi người',
      axis: 'LEADERSHIP/TEAMWORK'
    },
    {
      id: 29,
      question: 'Khi làm việc dưới áp lực, bạn thường:',
      optionA: 'Giữ sự cẩn thận và kiểm tra kỹ',
      optionB: 'Linh hoạt xoay cách làm để kịp tiến độ',
      axis: 'DETAIL/ADAPT'
    },
    {
      id: 30,
      question: 'Bạn thấy mình mạnh hơn ở:',
      optionA: 'Xử lý tình huống thực tế, triển khai nhanh',
      optionB: 'Lập kế hoạch dài hạn, định hướng chiến lược',
      axis: 'PRACTICAL/STRATEGIC'
    }
  ];

  constructor(
    private router: Router,
    private resultApi: ResultApiService,
    private userPortal: UserPortalService
  ) {}

  ngOnInit(): void {
    if (typeof window === 'undefined') return;

    const raw = localStorage.getItem('selected_upgrades');

    if (!raw) {
      this.router.navigateByUrl('/mbti-test');
      return;
    }

    const upgrades = JSON.parse(raw);

    if (!upgrades.ability) {
      this.router.navigateByUrl('/mbti-test');
      return;
    }

    this.userPortal.getOrCreateTestSessionId();
    this.restoreDraftAnswers();
    setTimeout(() => this.scrollToQuestionSection(), 120);
  }

  get totalPages(): number {
    return Math.ceil(this.questions.length / this.pageSize);
  }

  get pagedQuestions(): AbilityQuestion[] {
    const start = (this.currentPage - 1) * this.pageSize;
    return this.questions.slice(start, start + this.pageSize);
  }

  get answeredCount(): number {
    return Object.keys(this.answers).length;
  }

  get progressPercent(): number {
    return (
      (this.basicQuestionCount + this.interestQuestionCount + this.answeredCount) /
      this.totalQuestionCount
    ) * 100;
  }

  get currentPageAnsweredCount(): number {
    return this.pagedQuestions.filter(q => !!this.answers[q.id]).length;
  }
  get selectedPackageName(): string {
    const selectedPackage = this.userPortal.getSelectedPackageFromStorage();
    return String(selectedPackage?.name || '').trim();
  }

  get activePlanLabel(): string {
    if (this.selectedPackageName) {
      return this.selectedPackageName;
    }

    return 'Premium';
  }

  get activePlanChip(): string {
    if (this.selectedPackageName) {
      const normalized = this.selectedPackageName.toLowerCase();

      if (normalized.includes('premium')) return 'Premium';
      if (normalized.includes('plus')) return 'Plus';
    }

    return 'Premium';
  }
  get activePlanClass(): string {
    const chip = this.activePlanChip.toLowerCase();

    if (chip === 'plus') return 'plus';
    if (chip === 'premium') return 'premium';

    return 'premium';
  }
  restoreDraftAnswers(): void {
    if (typeof window === 'undefined') return;

    const raw = localStorage.getItem(this.draftKey);
    if (!raw) return;

    try {
      this.answers = JSON.parse(raw);
    } catch {
      this.answers = {};
    }
  }

  persistDraftAnswers(): void {
    if (typeof window === 'undefined') return;
    localStorage.setItem(this.draftKey, JSON.stringify(this.answers));
  }

  clearDraftAnswers(): void {
    if (typeof window === 'undefined') return;
    localStorage.removeItem(this.draftKey);
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
    if (this.currentPageAnsweredCount < this.pagedQuestions.length) {
      this.pageError = 'Bạn cần trả lời hết các câu trên trang này trước khi tiếp tục.';
      this.scrollToQuestionSection();
      return;
    }

    this.pageError = '';

    if (this.currentPage < this.totalPages) {
      this.currentPage++;
      setTimeout(() => this.scrollToQuestionSection(), 120);
    }
  }

  prevPage(): void {
    this.pageError = '';

    if (this.currentPage > 1) {
      this.currentPage--;
      setTimeout(() => this.scrollToQuestionSection(), 120);
    }
  }

  private buildScores(): AbilityScores {
    const scores: AbilityScores = {
      LANGUAGE: 0,
      LOGIC: 0,
      CREATIVE: 0,
      TECH: 0,
      LEADERSHIP: 0,
      TEAMWORK: 0,
      DETAIL: 0,
      ADAPT: 0,
      PRACTICAL: 0,
      STRATEGIC: 0
    };

    for (const q of this.questions) {
      const answer = this.answers[q.id];
      if (!answer) continue;

      const [left, right] = q.axis.split('/') as [AbilityKey, AbilityKey];

      if (answer === 'A') {
        scores[left] = scores[left] + 1;
      } else {
        scores[right] = scores[right] + 1;
      }
    }

    return scores;
  }

  private buildInterestFallback(scores: AbilityScores): InterestFallback {
    const groupScores: Record<InterestGroupKey, number> = {
      creative: (scores.CREATIVE || 0) + (scores.LANGUAGE || 0),
      analytic: (scores.LOGIC || 0) + (scores.TECH || 0),
      social: (scores.TEAMWORK || 0) + (scores.LANGUAGE || 0),
      business: (scores.LEADERSHIP || 0) + (scores.STRATEGIC || 0)
    };

    const topGroups = Object.entries(groupScores)
      .map(([key, value]) => ({ key: key as InterestGroupKey, value }))
      .sort((a, b) => b.value - a.value);

    return { groupScores, topGroups };
  }

  submit(): void {
    if (this.currentPageAnsweredCount < this.pagedQuestions.length) {
      this.pageError = 'Bạn cần trả lời hết các câu trên trang này trước khi nộp.';
      this.scrollToQuestionSection();
      return;
    }

    const abilityScores = this.buildScores();

    const rawMbti = typeof window !== 'undefined'
      ? localStorage.getItem('mbti_result')
      : null;

    let parsedMbti: MbtiStoredResult | null = null;
    try {
      parsedMbti = rawMbti ? JSON.parse(rawMbti) as MbtiStoredResult : null;
    } catch {
      parsedMbti = null;
    }

    const interestFallback = this.buildInterestFallback(abilityScores);

    if (typeof window !== 'undefined') {
      localStorage.setItem(
        'ability_result',
        JSON.stringify({
          mbti_type: parsedMbti?.type ?? null,
          mbti_scores: parsedMbti?.scores ?? null,
          answers: this.answers,
          scores: abilityScores,
          interest_group_scores: interestFallback.groupScores,
          interest_top_groups: interestFallback.topGroups
        })
      );
    }

    const selectedPackage = this.userPortal.getSelectedPackageFromStorage();
    const sessionId = this.userPortal.getOrCreateTestSessionId();

    if (typeof window !== 'undefined') {
      const token = localStorage.getItem('auth_token');

      if (token) {
        this.resultApi.saveAbilityResult({
          answers: this.answers,
          scores: abilityScores
        }).subscribe();

        this.userPortal.storeHistory({
          test_session_id: sessionId,
          test_type: 'full',
          result_code: parsedMbti?.type ?? this.pickTopAbility(abilityScores).join(' + '),
          answers: this.answers,
          questions: this.questions,
          scores: {
            ...(parsedMbti?.scores ?? {}),
            ...abilityScores
          },
          result_payload: {
            kind: 'full',
            title: 'Kết quả năng lực + sở thích',
            summary: 'Báo cáo đầy đủ sau khi hoàn thành gói nâng cao.',
            mbti_type: parsedMbti?.type ?? null,
            mbti_scores: parsedMbti?.scores ?? null,
            top_abilities: this.pickTopAbility(abilityScores),
            ability_scores: abilityScores,
            interest_group_scores: interestFallback.groupScores,
            interest_top_groups: interestFallback.topGroups
          },
          package_id: selectedPackage?.id ?? null,
          package_name: selectedPackage?.name ?? null
        }).subscribe();
      }
    }

    this.clearDraftAnswers();
    this.userPortal.clearTestSessionId();
    this.router.navigateByUrl('/ability-result');
  }

  pickTopAbility(scores: AbilityScores): string[] {
    return Object.entries(scores)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 3)
      .map(([key]) => this.labelForAbility(key as AbilityKey));
  }

  labelForAbility(key: AbilityKey): string {
    const map: Record<AbilityKey, string> = {
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

    return map[key];
  }

  scrollToQuestionSection(): void {
    if (typeof window === 'undefined') return;

    const el = document.getElementById('questionSection');

    if (!el) {
      window.scrollTo({
        top: 0,
        behavior: 'smooth'
      });
      return;
    }

    const headerOffset = 110;
    const y = el.getBoundingClientRect().top + window.scrollY - headerOffset;

    window.scrollTo({
      top: y,
      behavior: 'smooth'
    });
  }
}