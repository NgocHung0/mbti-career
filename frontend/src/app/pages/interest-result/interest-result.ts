import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterModule } from '@angular/router';
import { ResultApiService } from '../../services/result-api.service';
import { MbtiProfileService } from '../../services/mbti-profile.service';
import { forkJoin, of } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { UserPortalService } from '../../services/user-portal.service';

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

type InterestGroupKey = 'creative' | 'analytic' | 'social' | 'business';

type RawScores = {
  ART: number;
  TECH: number;
  HUMAN: number;
  TEAM: number;
};

type InterestResultData = {
  answers: Record<number, 'A' | 'B'>;
  rawScores: RawScores;
  groupScores: Record<InterestGroupKey, number>;
  topGroups: Array<{ key: InterestGroupKey; value: number }>;
};

type SchoolItem = {
  id?: number;
  name: string;
  featured: boolean;
  imageUrl?: string;
  city?: string;
  majorName?: string;
  shortDescription?: string;
  registerLink?: string;
};

type CareerItem = {
  name: string;
  description: string;
  mbtiTypes: string[];
  groups: InterestGroupKey[];
  schools: SchoolItem[];
  score?: number;
  reasons?: string[];
};

type MbtiProfile = {
  id?: number;
  code: string;
  name: string;
  description: string;
};

@Component({
  selector: 'app-interest-result',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './interest-result.html',
  styleUrl: './interest-result.css'
})
export class InterestResult implements OnInit {
  mbti: MbtiResult | null = null;
  interest: InterestResultData | null = null;
  profile: MbtiProfile | null = null;
  topCareers: CareerItem[] = [];
  isLoading = true;

  readonly fallbackMbtiTitles: Record<string, string> = {
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

  readonly groupLabels: Record<InterestGroupKey, string> = {
    creative: 'Sáng tạo',
    analytic: 'Phân tích - Công nghệ',
    social: 'Con người - Giao tiếp',
    business: 'Kinh doanh - Tổ chức'
  };

  readonly groupDescriptions: Record<InterestGroupKey, string> = {
    creative: 'Bạn có xu hướng thích ý tưởng mới, nội dung, hình ảnh, thẩm mỹ và môi trường linh hoạt.',
    analytic: 'Bạn thiên về logic, công nghệ, tối ưu hệ thống, làm việc chiều sâu và giải quyết vấn đề bằng phân tích.',
    social: 'Bạn có xu hướng quan tâm đến con người, giao tiếp, hỗ trợ, kết nối và làm việc cộng tác.',
    business: 'Bạn phù hợp với môi trường có mục tiêu rõ, tổ chức, vận hành, chiến lược và định hướng kết quả.'
  };

  constructor(
    private router: Router,
    private resultApi: ResultApiService,
    private mbtiProfileService: MbtiProfileService,
    private userPortal: UserPortalService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    const hasFreshPlusSession =
      typeof window !== 'undefined' &&
      !!localStorage.getItem('last_plus_test_session_id');

    this.loadFromLocalStorage();

    if (hasFreshPlusSession && this.mbti && this.interest) {
      this.loadMajorRecommendationsFromApi();
      this.isLoading = false;
      return;
    }

    localStorage.removeItem('mbti_result');
    localStorage.removeItem('interest_result');

    this.router.navigateByUrl('/interest-test');
  }

  goToAdmission(school: SchoolItem): void {
    this.router.navigate(['/admissions'], {
      queryParams: {
        focus: 1,
        admission_id: school.id || '',
        school: school.name || '',
        major: school.majorName || ''
      }
    });
  }

  private normalizeSchools(item: any): SchoolItem[] {
    const rawSchools =
      Array.isArray(item?.schools) ? item.schools :
      Array.isArray(item?.universities) ? item.universities :
      Array.isArray(item?.admissions) ? item.admissions :
      Array.isArray(item?.top_schools) ? item.top_schools :
      [];

    return rawSchools
      .map((school: any) => {
        if (typeof school === 'string') {
          return {
            id: 0,
            name: school,
            featured: false,
            imageUrl: '',
            city: '',
            majorName: '',
            shortDescription: '',
            registerLink: ''
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

          imageUrl: String(
            school?.image_url ??
            school?.logo_url ??
            school?.logoUrl ??
            school?.imageUrl ??
            school?.logo ??
            ''
          ).trim(),

          city: String(school?.city ?? '').trim(),
          majorName: String(school?.major_name ?? school?.majorName ?? '').trim(),
          shortDescription: String(school?.short_description ?? school?.description ?? '').trim(),

          registerLink: String(
            school?.register_link ??
            school?.registerLink ??
            ''
          ).trim()
        };
      })
      .filter((x: SchoolItem) => x.name)
      .sort((a: SchoolItem, b: SchoolItem) => Number(b.featured) - Number(a.featured))
      .slice(0, 5);
  }

  private toBoolean(value: any): boolean {
    return value === true || value === 1 || value === '1' || value === 'true';
  }

  private loadFromLocalStorage(): void {
    if (typeof window === 'undefined') return;

    const rawMbti = localStorage.getItem('mbti_result');
    const rawInterest = localStorage.getItem('interest_result');

    if (rawMbti) {
      try {
        this.mbti = this.normalizeMbtiResult(JSON.parse(rawMbti));
        if (this.mbti?.type) {
          this.mbtiProfileService
            .getByCode(this.mbti.type)
            .subscribe({
              next: (res: any) => {
                this.profile = this.normalizeProfile(res);
              },
              error: () => {}
            });
        }
      } catch {
        this.mbti = null;
      }
    }

    if (rawInterest) {
      try {
        this.interest = this.normalizeInterestResult(JSON.parse(rawInterest));
      } catch {
        this.interest = null;
      }
    }

    this.topCareers = [];
  }

  private normalizeProfile(raw: any): MbtiProfile | null {
    if (!raw) return null;

    const source = raw?.data ?? raw;

    return {
      id: Number(source?.id ?? 0),
      code: String(source?.code ?? '').trim().toUpperCase(),
      name: String(source?.name ?? '').trim(),
      description: String(source?.description ?? '').trim()
    };
  }

  get mbtiType(): string {
    return this.mbti?.type || '----';
  }

  get mbtiTitle(): string {
    return this.profile?.name?.trim() || this.fallbackMbtiTitles[this.mbtiType] || 'Nhóm tính cách';
  }

  get mbtiDescription(): string {
    return this.profile?.description?.trim()
      || 'Kết quả này được tổng hợp từ bài MBTI cơ bản và bài test sở thích nâng cao.';
  }

  get chartTotal(): number {
    if (!this.interest) return 0;

    const g = this.interest.groupScores;

    return Number(g.creative || 0)
      + Number(g.analytic || 0)
      + Number(g.social || 0)
      + Number(g.business || 0);
  }

  private get groupValues(): Record<InterestGroupKey, number> {
    return {
      creative: Number(this.interest?.groupScores?.creative || 0),
      analytic: Number(this.interest?.groupScores?.analytic || 0),
      social: Number(this.interest?.groupScores?.social || 0),
      business: Number(this.interest?.groupScores?.business || 0)
    };
  }

  private toPercent(value: number, total: number): number {
    if (!total) return 0;
    return Math.round((value / total) * 100);
  }

  private clampPercent(value: unknown): number {
    const numberValue = Number(value ?? 0);

    if (!Number.isFinite(numberValue)) {
      return 0;
    }

    return Math.max(
      0,
      Math.min(100, numberValue)
    );
  }

  get creativePercent(): number {
    return this.clampPercent(
      this.interest?.groupScores?.creative
    );
  }

  get analyticPercent(): number {
    return this.clampPercent(
      this.interest?.groupScores?.analytic
    );
  }

  get socialPercent(): number {
    return this.clampPercent(
      this.interest?.groupScores?.social
    );
  }

  get businessPercent(): number {
    return this.clampPercent(
      this.interest?.groupScores?.business
    );
  }

  get topInterestGroups(): Array<{ key: InterestGroupKey; value: number; label: string; description: string }> {
    if (!this.interest) return [];

    return this.interest.topGroups.slice(0, 2).map(item => ({
      ...item,
      label: this.groupLabels[item.key],
      description: this.groupDescriptions[item.key]
    }));
  }

  get mbtiBars(): Array<{
    left: string;
    right: string;
    dominant: string;
    percent: number;
    label: string;
  }> {
    if (!this.mbti) return [];

    const s = this.mbti.scores;

    return [
      this.buildMbtiBar('E', 'I', s.E, s.I, 'Hướng ngoại / Hướng nội'),
      this.buildMbtiBar('S', 'N', s.S, s.N, 'Thực tế / Trực giác'),
      this.buildMbtiBar('T', 'F', s.T, s.F, 'Lý trí / Cảm xúc'),
      this.buildMbtiBar('J', 'P', s.J, s.P, 'Kế hoạch / Linh hoạt')
    ];
  }

  private buildMbtiBar(
    left: string,
    right: string,
    leftValue: number,
    rightValue: number,
    label: string
  ) {
    const total = Number(leftValue || 0) + Number(rightValue || 0);
    const leftPercent = total ? Math.round((Number(leftValue || 0) / total) * 100) : 50;
    const rightPercent = 100 - leftPercent;

    if (leftValue >= rightValue) {
      return { left, right, dominant: left, percent: leftPercent, label };
    }

    return { left, right, dominant: right, percent: rightPercent, label };
  }

  private buildGroupScoresFromRawScores(rawScores: RawScores): Record<InterestGroupKey, number> {
    return {
      creative: Number(rawScores?.ART ?? 0),
      analytic: Number(rawScores?.TECH ?? 0),
      social: Number(rawScores?.HUMAN ?? 0),
      business: Number(rawScores?.TEAM ?? 0)
    };
  }

  private normalizeInterestResult(raw: any): InterestResultData | null {
    if (!raw) return null;

    const source =
      raw?.data?.result_payload ??
      raw?.data?.result ??
      raw?.data ??
      raw?.result_payload ??
      raw?.result ??
      raw;

    const directRawScores = source?.rawScores ?? source?.raw_scores ?? {};

    const rawScores: RawScores = {
      ART: Number(directRawScores?.ART ?? 0),
      TECH: Number(directRawScores?.TECH ?? 0),
      HUMAN: Number(directRawScores?.HUMAN ?? 0),
      TEAM: Number(directRawScores?.TEAM ?? 0)
    };

    const directGroupScores =
      source?.groupScores ??
      source?.group_scores ??
      source?.interest_group_scores ??
      source?.scores ??
      {};

    let groupScores: Record<InterestGroupKey, number> = {
      creative: Number(directGroupScores?.creative ?? 0),
      analytic: Number(directGroupScores?.analytic ?? 0),
      social: Number(directGroupScores?.social ?? 0),
      business: Number(directGroupScores?.business ?? 0)
    };

    const totalGroupScore =
      groupScores.creative +
      groupScores.analytic +
      groupScores.social +
      groupScores.business;

    if (!totalGroupScore) {
      groupScores = this.buildGroupScoresFromRawScores(rawScores);
    }

    const topGroupsSource = Array.isArray(source?.topGroups)
      ? source.topGroups
      : Array.isArray(source?.top_groups)
        ? source.top_groups
        : [];

    const safeTopGroups: Array<{ key: InterestGroupKey; value: number }> = [];

    for (const rawItem of topGroupsSource) {
      const key = this.normalizeGroupKey(rawItem?.key);
      if (!key) continue;

      safeTopGroups.push({
        key,
        value: Number(rawItem?.value ?? groupScores[key] ?? 0)
      });
    }

    const fallbackTopGroups =
      Object.entries(groupScores)
        .map(([key, value]) => ({
          key: key as InterestGroupKey,
          value: Number(value)
        }))
        .sort((a, b) => b.value - a.value);

    return {
      answers: source?.answers ?? {},
      rawScores,
      groupScores,
      topGroups: safeTopGroups.length ? safeTopGroups : fallbackTopGroups
    };
  }

  private normalizeGroupKey(value: any): InterestGroupKey | null {
    const key = String(value || '').trim().toLowerCase();

    if (key === 'creative' || key === 'analytic' || key === 'social' || key === 'business') {
      return key;
    }

    return null;
  }

  private loadMajorRecommendationsFromApi(): void {
    if (!this.mbti || !this.interest) {
      console.warn('NO MBTI OR INTEREST', {
        mbti: this.mbti,
        interest: this.interest
      });
      return;
    }

    const payload = {
      level: 'plus' as const,
      mbti_type: this.mbti.type,
      mbti_scores: this.mbti.scores,
      interest_group_scores: this.interest.groupScores,
      top_interest_groups: this.interest.topGroups.map(g => g.key).slice(0, 2),
      limit: 5
    };

    console.log('PLUS RECOMMENDATION PAYLOAD', payload);

    this.resultApi.calculateMajorRecommendations(payload).subscribe({
      next: (res: any) => {
        console.log('PLUS RECOMMENDATION RESPONSE', res);

        const source = res?.data ?? res?.result ?? res;
        const majors = Array.isArray(source?.top_majors)
          ? source.top_majors
          : [];

        console.log('PLUS MAJORS', majors);

        if (!majors.length) {
          this.topCareers = [];
          return;
        }

        this.topCareers = majors.map((item: any) => ({
          name: String(item?.name ?? ''),
          description: String(item?.description ?? ''),
          mbtiTypes: Array.isArray(item?.suitable_mbti) ? item.suitable_mbti : [],
          groups: [],
          schools: this.normalizeSchools(item),
          score: Number(item?.score ?? 0),
          reasons: Array.isArray(item?.reasons) ? item.reasons : []
        }));

        this.cdr.detectChanges();

        console.log('PLUS TOP CAREERS', this.topCareers);

        this.savePlusHistorySnapshot();
      },
      error: (err) => {
        console.error('Load major recommendations failed', err);
        this.topCareers = [];
      }
    });
  }
  
  private normalizeMbtiResult(raw: any): MbtiResult | null {
    if (!raw) return null;

    const source =
      raw?.data?.result_payload ??
      raw?.data?.result ??
      raw?.data ??
      raw?.result_payload ??
      raw?.result ??
      raw;

    const type = String(
      source?.type ??
      source?.mbti_type ??
      source?.mbti ??
      ''
    ).toUpperCase().trim();

    const scores = {
      E: Number(source?.scores?.E ?? source?.score_e ?? 0),
      I: Number(source?.scores?.I ?? source?.score_i ?? 0),
      S: Number(source?.scores?.S ?? source?.score_s ?? 0),
      N: Number(source?.scores?.N ?? source?.score_n ?? 0),
      T: Number(source?.scores?.T ?? source?.score_t ?? 0),
      F: Number(source?.scores?.F ?? source?.score_f ?? 0),
      J: Number(source?.scores?.J ?? source?.score_j ?? 0),
      P: Number(source?.scores?.P ?? source?.score_p ?? 0)
    };

    return {
      type: type || this.buildTypeFromScores(scores),
      scores
    };
  }

  private buildTypeFromScores(scores: MbtiResult['scores']): string {
    const e = scores.E >= scores.I ? 'E' : 'I';
    const s = scores.S >= scores.N ? 'S' : 'N';
    const t = scores.T >= scores.F ? 'T' : 'F';
    const j = scores.J >= scores.P ? 'J' : 'P';

    return `${e}${s}${t}${j}`;
  }

  redoTest(): void {
    this.router.navigateByUrl('/mbti-test');
  }

  private getSelectedPackageFromStorage(): any {
  if (typeof window === 'undefined') return null;

  const raw = localStorage.getItem('selected_package');
  if (!raw) return null;

  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

private savePlusHistorySnapshot(): void {
  if (!this.mbti || !this.interest) return;

  const sessionId = localStorage.getItem('last_plus_test_session_id');
  if (!sessionId) return;

  const selectedPackage = this.getSelectedPackageFromStorage();

  this.userPortal.storeHistory({
    test_session_id: sessionId,
    test_type: 'plus',
    result_code: this.mbtiType,
    answers: this.interest.answers,
    scores: this.mbti.scores,
    result_payload: {
      package_name: 'plus',
      mbti_type: this.mbtiType,
      mbti_scores: this.mbti.scores,

      raw_interest_scores: this.interest.rawScores,
      interest_group_scores: this.interest.groupScores,
      interest_top_groups: this.interest.topGroups,

      top_majors: this.topCareers,
      ai_analysis: this.buildPlusAiAnalysis()
    },
    package_id: selectedPackage?.id ?? null,
    package_name: selectedPackage?.name ?? 'Plus'
  }).subscribe({
    next: () => {
      console.log('PLUS HISTORY SNAPSHOT UPDATED');
      localStorage.removeItem('last_plus_test_session_id');
    },
    error: err => {
      console.error('SAVE PLUS HISTORY SNAPSHOT ERROR', err);
    }
  });
}

private buildPlusAiAnalysis(): string {
  if (!this.interest) return '';

  const top = this.topInterestGroups?.[0];
  const label = top?.label ?? 'nhóm sở thích nổi bật';

  return `AI nhận thấy nhóm ${this.mbtiType} của bạn kết hợp nổi bật với ${label}. Kết quả Plus tập trung vào việc đối chiếu tính cách MBTI và sở thích cá nhân để gợi ý nhóm ngành, trường tuyển sinh phù hợp hơn.`;
}
}