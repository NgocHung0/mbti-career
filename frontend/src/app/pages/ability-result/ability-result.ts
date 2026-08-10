import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterModule } from '@angular/router';
import { ResultApiService } from '../../services/result-api.service';
import { UserPortalService } from '../../services/user-portal.service';
import { API_ORIGIN, STORAGE_URL } from '../../core/api.config';

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

type InterestResultData = {
  answers: Record<number, 'A' | 'B'>;
  rawScores: Record<string, number>;
  groupScores: Record<InterestGroupKey, number>;
  topGroups: Array<{ key: InterestGroupKey; value: number }>;
};

type AbilityResultData = {
  answers: Record<number, 'A' | 'B'>;
  scores: Record<AbilityKey, number>;
};

type AbilityStoredResult = {
  mbti_type?: string | null;
  mbti_scores?: Record<string, number> | null;
  answers?: Record<number, 'A' | 'B'>;
  scores?: Record<AbilityKey, number>;
  interest_group_scores?: Record<InterestGroupKey, number>;
  interest_top_groups?: Array<{ key: InterestGroupKey; value: number }>;
};

type SchoolItem = {
  name: string;
  image_url: string | null;
  short_description: string;
  major_name: string;
  register_link: string | null;
  featured: boolean;
};

type CareerItem = {
  name: string;
  description: string;
  mbtiTypes: string[];
  interestGroups: InterestGroupKey[];
  abilityKeys: AbilityKey[];
  schools: SchoolItem[];
  score?: number;
  reasons?: string[];
};

type CombinedAxisKey =
  | 'creative'
  | 'analytic'
  | 'communication'
  | 'leadership'
  | 'technology'
  | 'strategy';

type CombinedDatum = {
  key: CombinedAxisKey;
  label: string;
  interestRaw: number;
  abilityRaw: number;
  interestScale: number;
  abilityScale: number;
  interestBarPercent: number;
  abilityBarPercent: number;
};

type RadarPoint = {
  x: number;
  y: number;
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
  selector: 'app-ability-result',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './ability-result.html',
  styleUrl: './ability-result.css'
})
export class AbilityResult implements OnInit {
  mbti: MbtiResult | null = null;
  interest: InterestResultData | null = null;
  ability: AbilityResultData | null = null;

  topCareers: CareerItem[] = [];
  aiCareerAnalysis = '';

  private premiumMajorsReady = false;

  readonly mbtiTitles: Record<string, string> = {
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

  readonly abilityLabels: Record<AbilityKey, string> = {
    LANGUAGE: 'Ngôn ngữ - Diễn đạt',
    LOGIC: 'Logic - Lập luận',
    CREATIVE: 'Sáng tạo',
    TECH: 'Công nghệ',
    LEADERSHIP: 'Lãnh đạo',
    TEAMWORK: 'Làm việc nhóm',
    DETAIL: 'Chi tiết - Cẩn thận',
    ADAPT: 'Thích ứng',
    PRACTICAL: 'Thực hành',
    STRATEGIC: 'Chiến lược'
  };

  readonly abilityDescriptions: Record<AbilityKey, string> = {
    LANGUAGE: 'Bạn có khả năng diễn đạt ý tưởng, trình bày và truyền tải thông tin khá tốt.',
    LOGIC: 'Bạn mạnh về tư duy phân tích, lập luận và nhìn ra cấu trúc của vấn đề.',
    CREATIVE: 'Bạn có xu hướng nghĩ ra ý tưởng mới, cách làm mới và góc nhìn khác biệt.',
    TECH: 'Bạn tiếp cận tốt với công cụ, công nghệ và môi trường kỹ thuật.',
    LEADERSHIP: 'Bạn có xu hướng dẫn dắt, định hướng và chủ động ra quyết định.',
    TEAMWORK: 'Bạn phối hợp tốt với người khác, kết nối và hỗ trợ nhóm hiệu quả.',
    DETAIL: 'Bạn chú ý chi tiết, cẩn thận và có xu hướng hạn chế sai sót.',
    ADAPT: 'Bạn linh hoạt, phản ứng nhanh và thích nghi tốt với thay đổi.',
    PRACTICAL: 'Bạn nghiêng về triển khai thực tế, áp dụng nhanh và xử lý tình huống thật.',
    STRATEGIC: 'Bạn có xu hướng nhìn dài hạn, định hướng mục tiêu và lên kế hoạch tốt.'
  };

  readonly abilityOverviewLabels: Record<AbilityKey, string> = {
    LANGUAGE: 'Ngôn ngữ',
    LOGIC: 'Tư duy logic',
    CREATIVE: 'Sáng tạo',
    TECH: 'Công nghệ',
    LEADERSHIP: 'Lãnh đạo',
    TEAMWORK: 'Làm việc nhóm',
    DETAIL: 'Chi tiết - Cẩn thận',
    ADAPT: 'Thích nghi',
    PRACTICAL: 'Thực hành',
    STRATEGIC: 'Chiến lược'
  };

  readonly overviewSvgSize = 620;
  readonly overviewCenter = 310;
  readonly resultUpdatedAt = new Date();

  readonly svgSize = 430;
  readonly svgCenter = 215;
  readonly svgRadius = 145;

  constructor(
    private router: Router,
    private resultApi: ResultApiService,
    private cdr: ChangeDetectorRef,
    private userPortal: UserPortalService
  ) {}

  ngOnInit(): void {
    this.loadFromLocalStorage();

    if (typeof window === 'undefined') return;

    const token = localStorage.getItem('auth_token');

    if (!this.ability && !this.interest) {
      this.router.navigateByUrl('/mbti-test');
      return;
    }

    if (!token) {
      this.loadPremiumResultData();
      return;
    }

    const currentStored = this.getStoredAbilityRaw();

    if (currentStored?.mbti_type) {
      this.mbti = {
        type: String(currentStored.mbti_type).toUpperCase(),
        scores: {
          E: Number(currentStored.mbti_scores?.['E'] || 0),
          I: Number(currentStored.mbti_scores?.['I'] || 0),
          S: Number(currentStored.mbti_scores?.['S'] || 0),
          N: Number(currentStored.mbti_scores?.['N'] || 0),
          T: Number(currentStored.mbti_scores?.['T'] || 0),
          F: Number(currentStored.mbti_scores?.['F'] || 0),
          J: Number(currentStored.mbti_scores?.['J'] || 0),
          P: Number(currentStored.mbti_scores?.['P'] || 0)
        }
      };

      localStorage.setItem('mbti_result', JSON.stringify(this.mbti));
    }

    this.resultApi.getLatestAbilityResult().subscribe({
      next: (abilityRes: any) => {
        const latestStored = this.getStoredAbilityRaw();

        if (abilityRes) {
          const apiScores = this.normalizeAbilityScores(abilityRes?.scores);
          const localScores = this.normalizeAbilityScores(latestStored?.scores);

          const resolvedScores = this.hasNonZeroAbilityScores(apiScores)
            ? apiScores
            : localScores;

          this.ability = {
            answers: abilityRes?.answers || latestStored?.answers || {},
            scores: resolvedScores
          };

          const fallbackInterest = this.createFallbackInterestFromAbilityScores(this.ability.scores);

          const mergedAbilityStorage: AbilityStoredResult = {
            mbti_type: this.mbti?.type ?? latestStored?.mbti_type ?? null,
            mbti_scores: this.mbti?.scores ?? latestStored?.mbti_scores ?? null,
            answers: this.ability.answers,
            scores: this.ability.scores,
            interest_group_scores: latestStored?.interest_group_scores ?? fallbackInterest.groupScores,
            interest_top_groups: latestStored?.interest_top_groups ?? fallbackInterest.topGroups
          };

          localStorage.setItem('ability_result', JSON.stringify(mergedAbilityStorage));
        }

        this.loadFromLocalStorage();
        this.loadPremiumResultData();
      },
      error: () => {
        this.loadPremiumResultData();
      }
    });
  }

  private loadPremiumResultData(): void {
    this.topCareers = [];
    this.aiCareerAnalysis = '';
    this.premiumMajorsReady = false;

    this.loadMajorRecommendationsFromApi();
  }

  private savePremiumSnapshotAfterPartLoaded(): void {
    this.saveFullHistorySnapshot(
      this.premiumMajorsReady
    );
  }

  private normalizeSchools(item: any): SchoolItem[] {
    let rawSchools: any[] = [];

    if (Array.isArray(item?.schools)) rawSchools = item.schools;
    else if (Array.isArray(item?.universities)) rawSchools = item.universities;
    else if (Array.isArray(item?.admissions)) rawSchools = item.admissions;
    else if (Array.isArray(item?.top_schools)) rawSchools = item.top_schools;
    else if (typeof item?.top_schools === 'string') {
      const value = item.top_schools.trim();

      try {
        const parsed = JSON.parse(value);
        rawSchools = Array.isArray(parsed) ? parsed : [];
      } catch {
        rawSchools = value.split(',').map((x: string) => x.trim()).filter(Boolean);
      }
    }

    return rawSchools
      .map((school: any) => {
        if (typeof school === 'string') {
          return {
            name: school,
            image_url: null,
            short_description: 'Trường có dữ liệu tuyển sinh phù hợp với ngành này.',
            major_name: String(item?.name ?? ''),
            register_link: null,
            featured: false
          };
        }

        return {
          name: String(
            school?.school_name ??
            school?.name ??
            school?.university_name ??
            school?.title ??
            ''
          ).trim(),

          image_url: this.resolveSchoolLogo(
            school?.image_url ??
            school?.logo_url ??
            school?.logo ??
            school?.image
          ),

          short_description: String(
            school?.short_description ??
            school?.description ??
            school?.reason ??
            'Trường có dữ liệu tuyển sinh phù hợp với ngành này.'
          ).trim(),

          major_name: String(
            school?.major_name ??
            item?.name ??
            ''
          ).trim(),

          register_link: school?.register_link ?? null,

          featured: this.toBoolean(
            school?.featured ??
            school?.is_featured
          )
        };
      })
      .filter((school: SchoolItem) => school.name)
      .sort((a: SchoolItem, b: SchoolItem) => {
        if (Number(b.featured) !== Number(a.featured)) {
          return Number(b.featured) - Number(a.featured);
        }

        return a.name.localeCompare(b.name);
      })
      .slice(0, 5);
  }

  private resolveSchoolLogo(value: any): string | null {
    if (!value) return null;

    const raw = String(value).trim();
    if (!raw) return null;

    if (
      raw.startsWith('http://') ||
      raw.startsWith('https://') ||
      raw.startsWith('data:')
    ) {
      return raw;
    }

    if (
      raw.startsWith('/images/') ||
      raw.startsWith('/assets/')
    ) {
      return `${API_ORIGIN}${raw}`;
    }

    const cleaned = raw.replace(/^\/+/, '');

    if (
      cleaned.startsWith('images/') ||
      cleaned.startsWith('assets/')
    ) {
      return `${API_ORIGIN}/${cleaned}`;
    }

    if (cleaned.startsWith('storage/')) {
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

  goToAdmissionDetail(event: MouseEvent, school: SchoolItem, career: CareerItem): void {
    event.stopPropagation();

    this.router.navigate(['/admissions'], {
      queryParams: {
        school: school.name,
        major: school.major_name || career.name,
        focus: '1'
      }
    });
  }

  private toBoolean(value: any): boolean {
    return value === true || value === 1 || value === '1' || value === 'true';
  }

  private normalizeMbtiResult(raw: any): MbtiResult | null {
    if (!raw) return null;

    const source = raw?.data ?? raw?.result ?? raw;

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

  private getStoredAbilityRaw(): AbilityStoredResult | null {
    if (typeof window === 'undefined') return null;

    const rawAbility = localStorage.getItem('ability_result');
    if (!rawAbility) return null;

    try {
      return JSON.parse(rawAbility) as AbilityStoredResult;
    } catch {
      return null;
    }
  }

  private hasNonZeroAbilityScores(scores: any): boolean {
    if (!scores || typeof scores !== 'object') return false;

    return Object.values(scores).some((value: any) => Number(value || 0) > 0);
  }

  private normalizeAbilityScores(scores: any): Record<AbilityKey, number> {
    return {
      LANGUAGE: Number(scores?.LANGUAGE || 0),
      LOGIC: Number(scores?.LOGIC || 0),
      CREATIVE: Number(scores?.CREATIVE || 0),
      TECH: Number(scores?.TECH || 0),
      LEADERSHIP: Number(scores?.LEADERSHIP || 0),
      TEAMWORK: Number(scores?.TEAMWORK || 0),
      DETAIL: Number(scores?.DETAIL || 0),
      ADAPT: Number(scores?.ADAPT || 0),
      PRACTICAL: Number(scores?.PRACTICAL || 0),
      STRATEGIC: Number(scores?.STRATEGIC || 0)
    };
  }

  private createFallbackInterestFromAbilityScores(
    abilityScores: Record<AbilityKey, number>
  ): InterestResultData {
    const creative = (abilityScores.CREATIVE || 0) + (abilityScores.LANGUAGE || 0);
    const analytic = (abilityScores.LOGIC || 0) + (abilityScores.TECH || 0);
    const social = (abilityScores.TEAMWORK || 0) + (abilityScores.LANGUAGE || 0);
    const business = (abilityScores.LEADERSHIP || 0) + (abilityScores.STRATEGIC || 0);

    const groupScores: Record<InterestGroupKey, number> = {
      creative,
      analytic,
      social,
      business
    };

    const topGroups = Object.entries(groupScores)
      .map(([key, value]) => ({ key: key as InterestGroupKey, value }))
      .sort((a, b) => b.value - a.value);

    return {
      answers: {},
      rawScores: {},
      groupScores,
      topGroups
    };
  }

  private loadFromLocalStorage(): void {
    if (typeof window === 'undefined') return;

    const rawMbti = localStorage.getItem('mbti_result');
    const rawAbility = localStorage.getItem('ability_result');

    this.mbti = null;
    this.ability = null;
    this.interest = null;

    if (rawMbti) {
      try {
        this.mbti = this.normalizeMbtiResult(JSON.parse(rawMbti));
      } catch {
        this.mbti = null;
      }
    }

    if (rawAbility) {
      try {
        const parsedAbility = JSON.parse(rawAbility);

        this.ability = {
          answers: parsedAbility.answers || {},
          scores: this.normalizeAbilityScores(parsedAbility.scores)
        };

        if (!this.mbti && parsedAbility.mbti_type) {
          this.mbti = {
            type: parsedAbility.mbti_type,
            scores: {
              E: Number(parsedAbility.mbti_scores?.['E'] || 0),
              I: Number(parsedAbility.mbti_scores?.['I'] || 0),
              S: Number(parsedAbility.mbti_scores?.['S'] || 0),
              N: Number(parsedAbility.mbti_scores?.['N'] || 0),
              T: Number(parsedAbility.mbti_scores?.['T'] || 0),
              F: Number(parsedAbility.mbti_scores?.['F'] || 0),
              J: Number(parsedAbility.mbti_scores?.['J'] || 0),
              P: Number(parsedAbility.mbti_scores?.['P'] || 0)
            }
          };
        }

        const hasInterestData =
          parsedAbility.interest_group_scores &&
          Object.values(parsedAbility.interest_group_scores).some((v: any) => Number(v) > 0);

        if (hasInterestData) {
          this.interest = {
            answers: {},
            rawScores: {},
            groupScores: parsedAbility.interest_group_scores,
            topGroups: parsedAbility.interest_top_groups || []
          };
        } else if (this.ability) {
          this.interest = this.createFallbackInterestFromAbilityScores(this.ability.scores);
        }
      } catch {
        this.ability = null;
        this.interest = null;
      }
    }

    if (!this.interest && this.ability) {
      this.interest = this.createFallbackInterestFromAbilityScores(this.ability.scores);
    }

    this.topCareers = [];
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

  private saveFullHistorySnapshot(removeSessionAfterSave = false): void {
    if (!this.mbti || !this.interest || !this.ability) return;

    const sessionId = localStorage.getItem('last_full_test_session_id');
    if (!sessionId) return;

    const selectedPackage = this.getSelectedPackageFromStorage();

    this.userPortal.storeHistory({
      test_session_id: sessionId,
      test_type: 'full',
      result_code: this.mbtiType,
      answers: this.ability.answers,
      scores: {
        ...(this.mbti?.scores ?? {}),
        ...(this.ability?.scores ?? {})
      },
      result_payload: {
        mbti_type: this.mbtiType,
        mbti_scores: this.mbti?.scores ?? {},

        ability_scores: this.ability.scores,
        interest_group_scores: this.interest.groupScores,
        interest_top_groups: this.interest.topGroups,

        combined_chart_data: this.combinedChartData,
        top_majors: this.topCareers,
        ai_analysis: this.aiCareerAnalysis,

        top_abilities: this.topAbilities.map(
          (item) => ({
            title: item.label,
            percent: item.percent,
            description: item.description
          })
        )
      },
      package_id: selectedPackage?.id ?? null,
      package_name: selectedPackage?.name ?? 'Premium'
    }).subscribe({
      next: () => {
        console.log('FULL HISTORY SNAPSHOT UPDATED');

        if (removeSessionAfterSave) {
          localStorage.removeItem('last_full_test_session_id');
        }
      },
      error: err => {
        console.error('SAVE FULL HISTORY SNAPSHOT ERROR', err);
      }
    });
  }

  get mbtiType(): string {
    if (this.mbti?.type) return this.mbti.type;

    if (typeof window !== 'undefined') {
      const rawAbility = localStorage.getItem('ability_result');

      if (rawAbility) {
        try {
          const parsed = JSON.parse(rawAbility);
          if (parsed?.mbti_type) return parsed.mbti_type;
        } catch {}
      }
    }

    return '----';
  }

  get mbtiTitle(): string {
    return this.mbtiTitles[this.mbtiType] || 'Nhóm tính cách';
  }

  get topInterestLabel(): string {
    if (!this.interest?.topGroups?.length) return '--';
    if (Number(this.interest.topGroups[0].value || 0) <= 0) return '--';
    return this.groupLabels[this.interest.topGroups[0].key];
  }

  get abilityScoreEntries(): Array<{
    key: AbilityKey;
    value: number;
    label: string;
  }> {
    if (!this.ability) {
      return [];
    }

    return Object.entries(
      this.ability.scores
    )
      .map(([key, value]) => {
        const abilityKey =
          key as AbilityKey;

        return {
          key: abilityKey,
          value: Number(value || 0),

          label:
            this.abilityOverviewLabels[
              abilityKey
            ] ||
            this.abilityLabels[
              abilityKey
            ]
        };
      })
      .sort((a, b) => {
        /*
        * Điểm cao hơn đứng trước.
        */
        const scoreDifference =
          b.value - a.value;

        if (scoreDifference !== 0) {
          return scoreDifference;
        }

        /*
        * Bằng điểm thì sắp theo tên
        * để kết quả luôn ổn định.
        */
        return a.label.localeCompare(
          b.label,
          'vi',
          {
            sensitivity: 'base'
          }
        );
      });
  }

  get topAbilities(): Array<{
    key: AbilityKey;
    value: number;
    percent: number;
    label: string;
    description: string;
  }> {
    const entries =
      this.abilityScoreEntries.slice(0, 3);

    return entries.map((item) => ({
      ...item,

      percent: Math.max(
        0,
        Math.min(
          100,
          Number(
            Number(item.value || 0).toFixed(1)
          )
        )
      ),

      description:
        this.abilityDescriptions[item.key]
    }));
  }

  get topAbilityLabel(): string {
    const top = this.topAbilities[0];
    if (!top || Number(top.value || 0) <= 0) return '--';
    return top.label;
  }

  get resultUpdatedDate(): string {
    return new Intl.DateTimeFormat(
      'vi-VN'
    ).format(this.resultUpdatedAt);
  }

  get interestCircleSegments():
    CircularSegment[] {
    if (!this.interest) return [];

    const values: Array<{
      key: InterestGroupKey;
      labelLines: string[];
      percent: number;
    }> = [
      {
        key: 'creative',
        labelLines: ['Sáng tạo'],
        percent: Number(
          this.interest.groupScores.creative || 0
        )
      },
      {
        key: 'analytic',
        labelLines: [
          'Phân tích -',
          'Công nghệ'
        ],
        percent: Number(
          this.interest.groupScores.analytic || 0
        )
      },
      {
        key: 'business',
        labelLines: [
          'Kinh doanh -',
          'Tổ chức'
        ],
        percent: Number(
          this.interest.groupScores.business || 0
        )
      },
      {
        key: 'social',
        labelLines: [
          'Con người -',
          'Giao tiếp'
        ],
        percent: Number(
          this.interest.groupScores.social || 0
        )
      }
    ];

    const startAngle = -180;
    const sectorAngle = 90;

    return values.map((item, index) => {
      const start =
        startAngle + index * sectorAngle;

      const end = start + sectorAngle;
      const mid = start + sectorAngle / 2;

      const percent = this.clampPercent(
        item.percent
      );

      return {
        key: item.key,
        labelLines: item.labelLines,
        percent,

        areaPath:
          this.buildAnnularSectorPath(
            start + 1.2,
            end - 1.2,
            88,
            188
          ),

        progressPath:
          this.buildProgressArcPath(
            start + 4,
            end - 4,
            196,
            percent
          ),

        labelX:
          this.polarPoint(mid, 139).x,

        labelY:
          this.polarPoint(mid, 139).y -
          (
            item.labelLines.length > 1
              ? 8
              : 0
          )
      };
    });
  }

  get abilityCircleSegments():
    CircularSegment[] {
    if (!this.ability) return [];

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

    const labelLines:
      Record<AbilityKey, string[]> = {
        LANGUAGE: ['Ngôn ngữ'],
        LOGIC: ['Tư duy logic'],
        CREATIVE: ['Sáng tạo'],
        TECH: ['Công nghệ'],
        LEADERSHIP: ['Lãnh đạo'],
        TEAMWORK: ['Làm việc nhóm'],

        DETAIL: [
          'Chi tiết -',
          'Cẩn thận'
        ],

        ADAPT: ['Thích nghi'],
        PRACTICAL: ['Thực hành'],
        STRATEGIC: ['Chiến lược']
      };

    const startAngle = -108;
    const sectorAngle = 36;

    return orderedKeys.map(
      (key, index) => {
        const start =
          startAngle + index * sectorAngle;

        const end = start + sectorAngle;
        const mid = start + sectorAngle / 2;

        const percent =
          this.clampPercent(
            Number(
              this.ability?.scores[key] || 0
            )
          );

        return {
          key,
          labelLines: labelLines[key],
          percent,

          areaPath:
            this.buildAnnularSectorPath(
              start + 0.9,
              end - 0.9,
              208,
              282
            ),

          progressPath:
            this.buildProgressArcPath(
              start + 3,
              end - 3,
              291,
              percent
            ),

          labelX:
            this.polarPoint(mid, 244).x,

          labelY:
            this.polarPoint(mid, 244).y -
            (
              labelLines[key].length > 1
                ? 7
                : 0
            )
        };
      }
    );
  }

  formatPercent(value: number): string {
    const rounded = Number(
      this.clampPercent(value).toFixed(1)
    );

    return Number.isInteger(rounded)
      ? String(rounded)
      : rounded.toFixed(1);
  }

  private clampPercent(
    value: number
  ): number {
    if (!Number.isFinite(value)) {
      return 0;
    }

    return Math.max(
      0,
      Math.min(100, value)
    );
  }

  private polarPoint(
    angleDegrees: number,
    radius: number
  ): RadarPoint {
    const angle =
      angleDegrees * (Math.PI / 180);

    return {
      x:
        this.overviewCenter +
        Math.cos(angle) * radius,

      y:
        this.overviewCenter +
        Math.sin(angle) * radius
    };
  }

  private buildAnnularSectorPath(
    startAngle: number,
    endAngle: number,
    innerRadius: number,
    outerRadius: number
  ): string {
    const outerStart =
      this.polarPoint(
        startAngle,
        outerRadius
      );

    const outerEnd =
      this.polarPoint(
        endAngle,
        outerRadius
      );

    const innerEnd =
      this.polarPoint(
        endAngle,
        innerRadius
      );

    const innerStart =
      this.polarPoint(
        startAngle,
        innerRadius
      );

    const largeArcFlag =
      endAngle - startAngle > 180
        ? 1
        : 0;

    return [
      `M ${outerStart.x} ${outerStart.y}`,

      `A ${outerRadius} ${outerRadius} 0 ${largeArcFlag} 1 ${outerEnd.x} ${outerEnd.y}`,

      `L ${innerEnd.x} ${innerEnd.y}`,

      `A ${innerRadius} ${innerRadius} 0 ${largeArcFlag} 0 ${innerStart.x} ${innerStart.y}`,

      'Z'
    ].join(' ');
  }

  private buildProgressArcPath(
    startAngle: number,
    endAngle: number,
    radius: number,
    percent: number
  ): string {
    const safePercent =
      this.clampPercent(percent);

    if (safePercent <= 0) {
      return '';
    }

    const progressEnd =
      startAngle +
      (
        endAngle - startAngle
      ) *
      (
        safePercent / 100
      );

    const start =
      this.polarPoint(
        startAngle,
        radius
      );

    const end =
      this.polarPoint(
        progressEnd,
        radius
      );

    const largeArcFlag =
      progressEnd - startAngle > 180
        ? 1
        : 0;

    return [
      `M ${start.x} ${start.y}`,

      `A ${radius} ${radius} 0 ${largeArcFlag} 1 ${end.x} ${end.y}`
    ].join(' ');
  }

  get combinedChartData(): CombinedDatum[] {
    if (!this.interest || !this.ability) return [];

    const g = this.interest.groupScores;
    const a = this.ability.scores;

    const abilityRows = {
      creative: Number(a.CREATIVE || 0),
      analytic: Number((a.LOGIC || 0) + (a.TECH || 0)),
      communication: Number((a.LANGUAGE || 0) + (a.TEAMWORK || 0)),
      leadership: Number(a.LEADERSHIP || 0),
      technology: Number((a.TECH || 0) + (a.PRACTICAL || 0)),
      strategy: Number((a.STRATEGIC || 0) + (a.ADAPT || 0)),
    };

    const totalAbility =
      Object.values(abilityRows).reduce((sum, value) => sum + value, 0) || 1;

    const rows: Array<{ key: CombinedAxisKey; label: string; interestRaw: number; abilityRaw: number }> = [
      {
        key: 'creative',
        label: 'Sáng tạo',
        interestRaw: Number(g.creative || 0),
        abilityRaw: Math.round((abilityRows.creative / totalAbility) * 100),
      },
      {
        key: 'analytic',
        label: 'Phân tích',
        interestRaw: Number(g.analytic || 0),
        abilityRaw: Math.round((abilityRows.analytic / totalAbility) * 100),
      },
      {
        key: 'communication',
        label: 'Giao tiếp',
        interestRaw: Number(g.social || 0),
        abilityRaw: Math.round((abilityRows.communication / totalAbility) * 100),
      },
      {
        key: 'leadership',
        label: 'Lãnh đạo',
        interestRaw: Number(g.business || 0),
        abilityRaw: Math.round((abilityRows.leadership / totalAbility) * 100),
      },
      {
        key: 'technology',
        label: 'Công nghệ',
        interestRaw: Number(g.analytic || 0),
        abilityRaw: Math.round((abilityRows.technology / totalAbility) * 100),
      },
      {
        key: 'strategy',
        label: 'Chiến lược',
        interestRaw: Number(g.business || 0),
        abilityRaw: Math.round((abilityRows.strategy / totalAbility) * 100),
      },
    ];

    return rows.map(item => ({
      ...item,
      interestScale: this.toRadarScale(item.interestRaw, 50),
      abilityScale: this.toRadarScale(item.abilityRaw, 50),
      interestBarPercent: this.toRadarScale(item.interestRaw, 50) * 100,
      abilityBarPercent: this.toRadarScale(item.abilityRaw, 50) * 100,
    }));
  }

  private toRadarScale(value: number, max: number): number {
    if (!max || value <= 0) return 0;
    return Math.min(1, value / max);
  }

  get radarInterestPoints(): string {
    return this.buildRadarPoints(this.combinedChartData.map(item => item.interestScale));
  }

  get radarAbilityPoints(): string {
    return this.buildRadarPoints(this.combinedChartData.map(item => item.abilityScale));
  }

  get radarInterestNodes(): RadarPoint[] {
    return this.buildRadarNodes(this.combinedChartData.map(item => item.interestScale));
  }

  get radarAbilityNodes(): RadarPoint[] {
    return this.buildRadarNodes(this.combinedChartData.map(item => item.abilityScale));
  }

  get radarAxes(): Array<{ x1: number; y1: number; x2: number; y2: number }> {
    const count = this.combinedChartData.length;

    return this.combinedChartData.map((_, index) => {
      const angle = this.getAngle(index, count);

      return {
        x1: this.svgCenter,
        y1: this.svgCenter,
        x2: this.pointX(angle, 1),
        y2: this.pointY(angle, 1)
      };
    });
  }

  get radarGridPolygons(): string[] {
    return [0.2, 0.4, 0.6, 0.8, 1].map(scale =>
      this.buildRadarPoints(new Array(this.combinedChartData.length).fill(scale))
    );
  }

  get radarLabelPositions(): Array<{ label: string; x: number; y: number }> {
    const count = this.combinedChartData.length;

    return this.combinedChartData.map((item, index) => {
      const angle = this.getAngle(index, count);

      return {
        label: item.label,
        x: this.pointX(angle, 1.18),
        y: this.pointY(angle, 1.18)
      };
    });
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

  private buildRadarNodes(values: number[]): RadarPoint[] {
    const count = values.length;

    return values.map((value, index) => {
      const angle = this.getAngle(index, count);

      return {
        x: this.pointX(angle, value),
        y: this.pointY(angle, value)
      };
    });
  }

  private loadMajorRecommendationsFromApi(): void {
    const storedAbility = this.getStoredAbilityRaw();

    const mbtiType =
      this.mbti?.type ||
      storedAbility?.mbti_type ||
      this.mbtiType;

    const abilityScores =
      this.ability?.scores ||
      this.normalizeAbilityScores(storedAbility?.scores);

    const effectiveInterest =
      this.interest ||
      this.createFallbackInterestFromAbilityScores(abilityScores);

    if (!mbtiType || mbtiType === '----') {
      console.warn('Missing MBTI type for recommendation');
      return;
    }

    if (!abilityScores || !this.hasNonZeroAbilityScores(abilityScores)) {
      console.warn('Missing ability scores for recommendation');
      return;
    }

    this.resultApi.calculateMajorRecommendations({
      level: 'premium',
      mbti_type: mbtiType,
      interest_group_scores: effectiveInterest.groupScores,
      ability_scores: abilityScores,
      limit: 5
      }).subscribe({
        next: (res: any) => {
          console.log('PREMIUM RECOMMENDATION RESPONSE', res);

          const majors =
            Array.isArray(res?.top_majors) ? res.top_majors :
            Array.isArray(res?.top_major) ? res.top_major :
            Array.isArray(res?.data?.top_majors) ? res.data.top_majors :
            Array.isArray(res?.data?.top_major) ? res.data.top_major :
            [];

          console.log('MAJORS TO RENDER', majors);

          this.topCareers = majors.map((item: any) => ({
            name: String(item?.name ?? ''),
            description: String(item?.description ?? ''),
            mbtiTypes: Array.isArray(item?.suitable_mbti) ? item.suitable_mbti : [],
            interestGroups: [],
            abilityKeys: [],
            schools: this.normalizeSchools(item),
            score: Number(item?.score ?? 0),
            reasons: Array.isArray(item?.reasons) ? item.reasons : []
          }));

          this.aiCareerAnalysis =
          String(res?.ai_analysis ?? res?.data?.ai_analysis ?? '').trim();

          console.log('TOP CAREERS RENDERED', this.topCareers);
          this.cdr.detectChanges();

          this.premiumMajorsReady = true;
          this.savePremiumSnapshotAfterPartLoaded();
        },
        error: (err) => {
          console.error('Load premium major recommendations failed', err);
          this.premiumMajorsReady = true;
          this.savePremiumSnapshotAfterPartLoaded();
        }
      });
  }

  restartFullTest(): void {
    this.router.navigateByUrl('/mbti-test');
  }
  getMbtiRobotImage(): string {
    return `/images/emoji/${this.mbtiType}.png`;
  }

  getLevelLabel(value: number, max: number = 4): string {
    const score = Number(value || 0);

    if (score >= Math.ceil(max * 0.75)) {
      return 'Cốt lõi';
    }

    if (score >= Math.ceil(max * 0.4)) {
      return 'Có liên quan';
    }

    return 'Ít nổi bật';
  }
}