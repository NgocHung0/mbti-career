import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterModule } from '@angular/router';
import { ResultApiService } from '../../services/result-api.service';

type MbtiScores = {
  E: number;
  I: number;
  S: number;
  N: number;
  T: number;
  F: number;
  J: number;
  P: number;
};

type MbtiResult = {
  type: string;
  scores: MbtiScores;
};

type UpgradeSelection = {
  interest: boolean;
  ability: boolean;
};

type SuggestedSchool = {
  name: string;
  major: string;
};

@Component({
  selector: 'app-result-basic',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './result-basic.html',
  styleUrl: './result-basic.css'
})
export class ResultBasic implements OnInit {
  result: MbtiResult | null = null;

  upgrades: UpgradeSelection = {
    interest: false,
    ability: false
  };

  currentRole: 'user' | 'student' | 'premium' | string = 'user';

  readonly titles: Record<string, string> = {
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

  readonly typeDescriptions: Record<string, string> = {
    INTJ: 'Bạn thiên về tư duy chiến lược, độc lập và thích xây dựng kế hoạch dài hạn rõ ràng.',
    INTP: 'Bạn mạnh về phân tích, thích tìm hiểu bản chất vấn đề và thường suy nghĩ theo chiều sâu.',
    ENTJ: 'Bạn quyết đoán, có xu hướng lãnh đạo và giỏi tổ chức để đạt mục tiêu cụ thể.',
    ENTP: 'Bạn linh hoạt, sáng tạo, thích khám phá ý tưởng mới và phản biện nhiều góc nhìn.',
    INFJ: 'Bạn sâu sắc, có trực giác tốt và thường quan tâm đến ý nghĩa dài hạn của mọi việc.',
    INFP: 'Bạn chân thành, giàu giá trị cá nhân và thường hành động theo điều mình tin là đúng.',
    ENFJ: 'Bạn có khả năng kết nối, truyền cảm hứng và tạo ảnh hưởng tích cực đến người khác.',
    ENFP: 'Bạn giàu năng lượng, cởi mở, yêu thích trải nghiệm mới và thường nhìn thấy nhiều khả năng.',
    ISTJ: 'Bạn thực tế, nguyên tắc, trách nhiệm cao và làm việc rất đáng tin cậy.',
    ISFJ: 'Bạn chu đáo, ổn định, tận tâm và thường hỗ trợ người khác theo cách rất thực tế.',
    ESTJ: 'Bạn có tổ chức, rõ ràng, thích quy củ và phù hợp với môi trường kỷ luật cao.',
    ESFJ: 'Bạn hòa đồng, biết quan tâm tập thể và thường tạo cảm giác gắn kết cho mọi người.',
    ISTP: 'Bạn bình tĩnh, thực tế, thích tự mình xử lý vấn đề và học tốt qua trải nghiệm.',
    ISFP: 'Bạn tinh tế, linh hoạt, yêu cái đẹp và sống khá chân thật với cảm xúc.',
    ESTP: 'Bạn nhanh nhạy, thiên hành động, thích thử thách và hợp môi trường năng động.',
    ESFP: 'Bạn cởi mở, vui vẻ, thích tương tác và dễ lan tỏa năng lượng tích cực.'
  };

  constructor(
    private resultApi: ResultApiService,
    private router: Router
  ) {}

  ngOnInit(): void {
    if (typeof window === 'undefined') return;

    this.loadRoleFromStorage();
    this.loadFromLocalStorage();

    if (!this.checkAccess()) {
      this.router.navigateByUrl('/mbti-test');
      return;
    }

    const token = localStorage.getItem('auth_token');
    if (!token) {
      this.clearExpiredAdAccess();
      return;
    }

    this.resultApi.getLatestMbtiResult().subscribe({
      next: (res: any) => {
        const normalized = this.normalizeResult(res);

        if (normalized) {
          this.result = normalized;

          this.upgrades = {
            interest: !!res?.upgrade_interest,
            ability: !!res?.upgrade_ability
          };

          localStorage.setItem('mbti_result', JSON.stringify(this.result));
        }

        this.clearExpiredAdAccess();
      },
      error: (err: any) => {
        console.error('Load latest MBTI failed', err);
        this.clearExpiredAdAccess();
      }
    });
  }

  get isFreeUser(): boolean {
    return this.currentRole === 'user';
  }

  private loadRoleFromStorage(): void {
    if (typeof window === 'undefined') return;

    try {
      const rawUser = localStorage.getItem('auth_user');
      const parsedUser = rawUser ? JSON.parse(rawUser) : null;
      const role = String(parsedUser?.role || '').trim().toLowerCase();

      if (role === 'premium' || role === 'student' || role === 'user') {
        this.currentRole = role;
      } else {
        this.currentRole = 'user';
      }
    } catch {
      this.currentRole = 'user';
    }
  }

  private checkAccess(): boolean {
    if (typeof window === 'undefined') return false;

    const rawResult = localStorage.getItem('mbti_result');
    if (!rawResult) return false;

    const mode = localStorage.getItem('result_basic_access');
    const time = Number(localStorage.getItem('result_basic_access_at') || 0);
    const now = Date.now();

    const validAd =
      mode === 'ad' &&
      time > 0 &&
      now - time <= 10 * 60 * 1000;

    const validPackage = mode === 'package';

    return validAd || validPackage;
  }

  private clearExpiredAdAccess(): void {
    if (typeof window === 'undefined') return;

    const mode = localStorage.getItem('result_basic_access');
    const time = Number(localStorage.getItem('result_basic_access_at') || 0);
    const now = Date.now();

    if (mode === 'ad' && (time <= 0 || now - time > 10 * 60 * 1000)) {
      localStorage.removeItem('result_basic_access');
      localStorage.removeItem('result_basic_access_at');
    }
  }

  private loadFromLocalStorage(): void {
    if (typeof window === 'undefined') return;

    const rawResult = localStorage.getItem('mbti_result');
    const rawUpgrades = localStorage.getItem('selected_upgrades');

    try {
      const parsed = rawResult ? JSON.parse(rawResult) : null;
      this.result = this.normalizeResult(parsed);
    } catch {
      this.result = null;
    }

    try {
      this.upgrades = rawUpgrades
        ? JSON.parse(rawUpgrades)
        : { interest: false, ability: false };
    } catch {
      this.upgrades = { interest: false, ability: false };
    }
  }

  private normalizeResult(raw: any): MbtiResult | null {
    if (!raw) return null;

    const source = raw?.data ?? raw?.result ?? raw;

    const type = String(
      source?.type ||
      source?.mbti_type ||
      ''
    ).toUpperCase();

    const hasScorePair =
      source?.scores ||
      source?.score_e !== undefined ||
      source?.score_i !== undefined ||
      source?.score_s !== undefined ||
      source?.score_n !== undefined ||
      source?.score_t !== undefined ||
      source?.score_f !== undefined ||
      source?.score_j !== undefined ||
      source?.score_p !== undefined;

    if (!hasScorePair) {
      return null;
    }

    const scores: MbtiScores = {
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

  private buildTypeFromScores(scores: MbtiScores): string {
    const e = scores.E >= scores.I ? 'E' : 'I';
    const s = scores.S >= scores.N ? 'S' : 'N';
    const t = scores.T >= scores.F ? 'T' : 'F';
    const j = scores.J >= scores.P ? 'J' : 'P';
    return `${e}${s}${t}${j}`;
  }

  get typeCode(): string {
    return this.result?.type || '----';
  }

  get title(): string {
    return this.titles[this.typeCode] || 'Nhóm tính cách';
  }

  get description(): string {
    if (!this.result) {
      return 'Chưa có dữ liệu kết quả để phân tích.';
    }

    const base = this.typeDescriptions[this.typeCode] || 'Bạn có một kiểu tính cách khá cân bằng và linh hoạt.';
    const details = [
      this.getEiAnalysis(),
      this.getSnAnalysis(),
      this.getTfAnalysis(),
      this.getJpAnalysis()
    ];

    return `${base} ${details.join(' ')}`;
  }

  get strengths(): string[] {
    if (!this.result) return [];

    const items: string[] = [];
    items.push(this.getMainStrengthByAxis('EI'));
    items.push(this.getMainStrengthByAxis('SN'));
    items.push(this.getMainStrengthByAxis('TF'));
    items.push(this.getMainStrengthByAxis('JP'));

    return items.filter(Boolean);
  }

  get studySuggestion(): string {
    if (!this.result) {
      return 'Hãy hoàn thành bài test để nhận gợi ý phù hợp hơn.';
    }

    const socialMode = this.ePercent >= 55
      ? 'Bạn có xu hướng học tốt khi được trao đổi, làm việc nhóm và tham gia các hoạt động có tương tác.'
      : 'Bạn có xu hướng học tốt khi có không gian tập trung riêng, thời gian suy nghĩ độc lập và nhịp học ổn định.';

    const intakeMode = this.nPercent >= 55
      ? 'Bạn tiếp thu tốt khi được học qua ý tưởng lớn, mô hình tổng quan và liên hệ thực tế tương lai.'
      : 'Bạn tiếp thu tốt khi có ví dụ cụ thể, quy trình rõ ràng và cách học từng bước chắc chắn.';

    const decisionMode = this.tPercent >= 55
      ? 'Bạn nên ưu tiên cách học có logic, tiêu chí rõ ràng và mục tiêu đo lường cụ thể.'
      : 'Bạn sẽ học hiệu quả hơn khi nội dung gắn với giá trị cá nhân, cảm hứng và yếu tố con người.';

    const lifestyleMode = this.jPercent >= 55
      ? 'Bạn phù hợp với kế hoạch học tập cố định, có deadline rõ và checklist theo tuần.'
      : 'Bạn phù hợp với cách học linh hoạt, chia nhỏ mục tiêu và có khoảng trống để điều chỉnh theo cảm hứng.';

    return `${socialMode} ${intakeMode} ${decisionMode} ${lifestyleMode}`;
  }

  get recommendedMajors(): string[] {
    const map: Record<string, string[]> = {
      INTJ: ['Công nghệ thông tin', 'Khoa học dữ liệu', 'Hệ thống thông tin'],
      INTP: ['Khoa học máy tính', 'Phân tích dữ liệu', 'Nghiên cứu'],
      ENTJ: ['Quản trị kinh doanh', 'Marketing', 'Logistics'],
      ENTP: ['Truyền thông', 'Marketing', 'Khởi nghiệp'],
      INFJ: ['Tâm lý học', 'Giáo dục', 'Truyền thông'],
      INFP: ['Truyền thông đa phương tiện', 'Ngôn ngữ', 'Thiết kế'],
      ENFJ: ['Giáo dục', 'Quản trị nhân sự', 'Tư vấn'],
      ENFP: ['Truyền thông đa phương tiện', 'Marketing', 'Tổ chức sự kiện'],
      ISTJ: ['Kế toán', 'Kiểm toán', 'Hành chính'],
      ISFJ: ['Điều dưỡng', 'Giáo dục', 'Công tác xã hội'],
      ESTJ: ['Quản trị kinh doanh', 'Luật', 'Logistics'],
      ESFJ: ['Quan hệ công chúng', 'Giáo dục', 'Dịch vụ'],
      ISTP: ['Kỹ thuật', 'Công nghệ ô tô', 'Mạng máy tính'],
      ISFP: ['Thiết kế đồ họa', 'Mỹ thuật', 'Thời trang'],
      ESTP: ['Kinh doanh', 'Du lịch', 'Tổ chức sự kiện'],
      ESFP: ['Truyền thông', 'Quan hệ công chúng', 'Dịch vụ khách hàng']
    };

    return map[this.typeCode] || ['Quản trị kinh doanh', 'Truyền thông', 'Công nghệ thông tin'];
  }

  get suggestedSchools(): SuggestedSchool[] {
    const map: Record<string, SuggestedSchool[]> = {
      INTJ: [
        { name: 'Đại học Công nghệ Thông tin', major: 'Công nghệ thông tin' },
        { name: 'Đại học Bách khoa', major: 'Khoa học dữ liệu' },
        { name: 'Đại học Khoa học Tự nhiên', major: 'Hệ thống thông tin' }
      ],
      INTP: [
        { name: 'Đại học Khoa học Tự nhiên', major: 'Khoa học máy tính' },
        { name: 'Đại học Công nghệ Thông tin', major: 'Phân tích dữ liệu' },
        { name: 'Đại học Bách khoa', major: 'Trí tuệ nhân tạo' }
      ],
      ENTJ: [
        { name: 'Đại học Kinh tế TP.HCM', major: 'Quản trị kinh doanh' },
        { name: 'Đại học Ngoại thương', major: 'Marketing' },
        { name: 'Đại học Giao thông Vận tải', major: 'Logistics' }
      ],
      ENTP: [
        { name: 'Đại học Văn Lang', major: 'Truyền thông' },
        { name: 'Đại học Tài chính - Marketing', major: 'Marketing' },
        { name: 'Đại học Kinh tế TP.HCM', major: 'Kinh doanh số' }
      ],
      INFJ: [
        { name: 'Đại học Sư phạm TP.HCM', major: 'Giáo dục' },
        { name: 'Đại học KHXH&NV', major: 'Tâm lý học' },
        { name: 'Đại học Văn Lang', major: 'Truyền thông' }
      ],
      INFP: [
        { name: 'Đại học Văn Hiến', major: 'Truyền thông đa phương tiện' },
        { name: 'Đại học Văn Lang', major: 'Thiết kế' },
        { name: 'Đại học KHXH&NV', major: 'Ngôn ngữ' }
      ],
      ENFJ: [
        { name: 'Đại học Sư phạm TP.HCM', major: 'Giáo dục' },
        { name: 'Đại học Lao động - Xã hội', major: 'Quản trị nhân sự' },
        { name: 'Đại học KHXH&NV', major: 'Tâm lý học' }
      ],
      ENFP: [
        { name: 'Đại học Văn Hiến', major: 'Truyền thông đa phương tiện' },
        { name: 'Đại học Tài chính - Marketing', major: 'Marketing' },
        { name: 'Đại học Hoa Sen', major: 'Tổ chức sự kiện' }
      ],
      ISTJ: [
        { name: 'Đại học Kinh tế TP.HCM', major: 'Kế toán' },
        { name: 'Đại học Ngân hàng', major: 'Kiểm toán' },
        { name: 'Học viện Hành chính', major: 'Hành chính công' }
      ],
      ISFJ: [
        { name: 'Đại học Y Dược', major: 'Điều dưỡng' },
        { name: 'Đại học Sư phạm TP.HCM', major: 'Giáo dục' },
        { name: 'Đại học Mở TP.HCM', major: 'Công tác xã hội' }
      ],
      ESTJ: [
        { name: 'Đại học Kinh tế TP.HCM', major: 'Quản trị kinh doanh' },
        { name: 'Đại học Luật TP.HCM', major: 'Luật' },
        { name: 'Đại học Giao thông Vận tải', major: 'Logistics' }
      ],
      ESFJ: [
        { name: 'Đại học KHXH&NV', major: 'Quan hệ công chúng' },
        { name: 'Đại học Sư phạm TP.HCM', major: 'Giáo dục' },
        { name: 'Đại học Hoa Sen', major: 'Dịch vụ khách hàng' }
      ],
      ISTP: [
        { name: 'Đại học Bách khoa', major: 'Kỹ thuật' },
        { name: 'Đại học Sư phạm Kỹ thuật', major: 'Công nghệ ô tô' },
        { name: 'Đại học Công nghệ Thông tin', major: 'Mạng máy tính' }
      ],
      ISFP: [
        { name: 'Đại học Kiến trúc', major: 'Thiết kế đồ họa' },
        { name: 'Đại học Văn Lang', major: 'Mỹ thuật' },
        { name: 'Đại học Công nghiệp TP.HCM', major: 'Thiết kế thời trang' }
      ],
      ESTP: [
        { name: 'Đại học Kinh tế TP.HCM', major: 'Kinh doanh' },
        { name: 'Đại học Văn Hiến', major: 'Du lịch' },
        { name: 'Đại học Hoa Sen', major: 'Tổ chức sự kiện' }
      ],
      ESFP: [
        { name: 'Đại học Văn Hiến', major: 'Truyền thông' },
        { name: 'Đại học KHXH&NV', major: 'Quan hệ công chúng' },
        { name: 'Đại học Hoa Sen', major: 'Dịch vụ khách hàng' }
      ]
    };

    return map[this.typeCode] || [
      { name: 'Đại học Kinh tế TP.HCM', major: 'Quản trị kinh doanh' },
      { name: 'Đại học Văn Hiến', major: 'Truyền thông đa phương tiện' },
      { name: 'Đại học Công nghệ Thông tin', major: 'Công nghệ thông tin' }
    ];
  }

  private getMainStrengthByAxis(axis: 'EI' | 'SN' | 'TF' | 'JP'): string {
    switch (axis) {
      case 'EI':
        return this.ePercent >= this.iPercent
          ? 'Bạn có khả năng kết nối, chủ động giao tiếp và lan tỏa năng lượng tích cực.'
          : 'Bạn có khả năng tập trung sâu, quan sát tốt và suy nghĩ độc lập trước khi hành động.';
      case 'SN':
        return this.sPercent >= this.nPercent
          ? 'Bạn mạnh ở tính thực tế, chú ý chi tiết và tiếp cận vấn đề theo dữ kiện rõ ràng.'
          : 'Bạn mạnh ở trực giác, nhìn ra khả năng mới và liên kết ý tưởng theo bức tranh lớn.';
      case 'TF':
        return this.tPercent >= this.fPercent
          ? 'Bạn có xu hướng phân tích logic, đánh giá công bằng và ra quyết định rõ ràng.'
          : 'Bạn có khả năng thấu cảm, quan tâm con người và cân bằng cảm xúc khi xử lý vấn đề.';
      case 'JP':
        return this.jPercent >= this.pPercent
          ? 'Bạn có xu hướng tổ chức tốt, làm việc có kế hoạch và theo đuổi mục tiêu đến cùng.'
          : 'Bạn linh hoạt, thích nghi nhanh và dễ xử lý tình huống khi môi trường thay đổi.';
      default:
        return '';
    }
  }

  private getEiAnalysis(): string {
    return this.ePercent >= this.iPercent
      ? 'Bạn nghiêng về hướng ngoại, thường nạp năng lượng qua tương tác và hoạt động với người khác.'
      : 'Bạn nghiêng về hướng nội, thường nạp năng lượng qua không gian riêng và thời gian suy nghĩ một mình.';
  }

  private getSnAnalysis(): string {
    return this.sPercent >= this.nPercent
      ? 'Bạn thiên về giác quan, chú trọng thực tế, dữ kiện rõ ràng và trải nghiệm cụ thể.'
      : 'Bạn thiên về trực giác, thích ý tưởng mới, khả năng tương lai và những kết nối mang tính khái quát.';
  }

  private getTfAnalysis(): string {
    return this.tPercent >= this.fPercent
      ? 'Bạn thiên về lý trí, thường cân nhắc theo logic, nguyên tắc và tiêu chí khách quan.'
      : 'Bạn thiên về cảm xúc, thường đưa ra quyết định dựa trên giá trị cá nhân và ảnh hưởng đến con người.';
  }

  private getJpAnalysis(): string {
    return this.jPercent >= this.pPercent
      ? 'Bạn thiên về nguyên tắc, thích sự rõ ràng, kế hoạch và cảm giác kiểm soát tiến độ.'
      : 'Bạn thiên về linh hoạt, thích thử nghiệm, điều chỉnh theo tình huống và giữ nhiều lựa chọn mở.';
  }

  get ePercent(): number {
    return this.toPercent(this.result?.scores.E ?? 0, this.result?.scores.I ?? 0);
  }

  get iPercent(): number {
    return this.toPercent(this.result?.scores.I ?? 0, this.result?.scores.E ?? 0);
  }

  get sPercent(): number {
    return this.toPercent(this.result?.scores.S ?? 0, this.result?.scores.N ?? 0);
  }

  get nPercent(): number {
    return this.toPercent(this.result?.scores.N ?? 0, this.result?.scores.S ?? 0);
  }

  get tPercent(): number {
    return this.toPercent(this.result?.scores.T ?? 0, this.result?.scores.F ?? 0);
  }

  get fPercent(): number {
    return this.toPercent(this.result?.scores.F ?? 0, this.result?.scores.T ?? 0);
  }

  get jPercent(): number {
    return this.toPercent(this.result?.scores.J ?? 0, this.result?.scores.P ?? 0);
  }

  get pPercent(): number {
    return this.toPercent(this.result?.scores.P ?? 0, this.result?.scores.J ?? 0);
  }

  private toPercent(primary: number, opposite: number): number {
    const total = primary + opposite;
    if (total <= 0) return 50;
    return Math.round((primary / total) * 100);
  }
}