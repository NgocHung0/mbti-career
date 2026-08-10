import { CommonModule, isPlatformBrowser } from '@angular/common';
import {
  AfterViewInit,
  ChangeDetectorRef,
  Component,
  Inject,
  OnInit,
  PLATFORM_ID,
  inject
} from '@angular/core';
import { RouterModule } from '@angular/router';
import { finalize } from 'rxjs/operators';
import { AboutSettingsService } from '../../features/admin/services/about-settings.service';

type AboutSettingView = {
  hero_title: string | null;
  short_description: string | null;
  full_description: string | null;
  mission_title: string | null;
  mission_description: string | null;
  vision_title: string | null;
  vision_description: string | null;
  privacy_policy: string | null;
  banner_image: string | null;
  secondary_image: string | null;
};

type AboutStatView = {
  id?: number;
  label: string;
  value: string;
  sort_order?: number;
  is_active?: boolean;
};

@Component({
  selector: 'app-about',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './about.html',
  styleUrl: './about.css'
})
export class About implements OnInit, AfterViewInit {
  private aboutService = inject(AboutSettingsService);
  private cdr = inject(ChangeDetectorRef);

  constructor(@Inject(PLATFORM_ID) private platformId: Object) {}

  loading = true;
  errorMessage = '';

  setting: AboutSettingView = {
    hero_title: 'Về chúng tôi',
    short_description: '',
    full_description: '',
    mission_title: 'Sứ mệnh',
    mission_description: '',
    vision_title: 'Tầm nhìn',
    vision_description: '',
    privacy_policy: '',
    banner_image: '',
    secondary_image: ''
  };

  stats: AboutStatView[] = [];

  ngOnInit(): void {
    this.loadAboutData();
  }

  ngAfterViewInit(): void {
    setTimeout(() => {
      this.initRevealAnimation();
    }, 300);
  }

  loadAboutData(): void {
    this.loading = true;
    this.errorMessage = '';
    this.cdr.detectChanges();

    this.aboutService
      .getAboutSettings()
      .pipe(
        finalize(() => {
          this.loading = false;
          this.cdr.detectChanges();

          setTimeout(() => {
            this.initRevealAnimation();
          }, 150);
        })
      )
      .subscribe({
        next: (res: any) => {
          const normalized = this.normalizeAboutResponse(res);
          const setting = normalized.setting;
          const stats = normalized.stats;

            this.setting = {
              hero_title: setting?.hero_title ?? 'Về chúng tôi',
              short_description: setting?.short_description ?? '',
              full_description: setting?.full_description ?? '',
              mission_title: setting?.mission_title ?? 'Sứ mệnh',
              mission_description: setting?.mission_description ?? '',
              vision_title: setting?.vision_title ?? 'Tầm nhìn',
              vision_description: setting?.vision_description ?? '',
              privacy_policy: setting?.privacy_policy ?? '',
              banner_image: setting?.banner_image ?? '',
              secondary_image: setting?.secondary_image ?? ''
            };

          this.stats = stats
            .filter((item: AboutStatView) => item?.is_active !== false)
            .sort((a: AboutStatView, b: AboutStatView) => {
              return Number(a?.sort_order || 0) - Number(b?.sort_order || 0);
            });

          this.errorMessage = '';
          this.cdr.detectChanges();
        },
        error: (err) => {
          console.error('Load about settings error:', err);
          this.errorMessage =
            err?.error?.message ||
            err?.message ||
            'Không tải được dữ liệu trang Về chúng tôi.';
          this.cdr.detectChanges();
        }
      });
  }

  private initRevealAnimation(): void {
    if (!isPlatformBrowser(this.platformId)) return;

    const items = document.querySelectorAll('.reveal-item');
    if (!items.length) return;

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add('show');
          }
        });
      },
      {
        threshold: 0.18
      }
    );

    items.forEach((item) => observer.observe(item));
  }

  private normalizeAboutResponse(res: any): { setting: any; stats: AboutStatView[] } {
    if (!res || typeof res !== 'object') {
      return { setting: {}, stats: [] };
    }

    const setting =
      res.setting ||
      res.data?.setting ||
      res.data ||
      {};

    const statsRaw =
      res.stats ||
      res.data?.stats ||
      setting?.stats ||
      [];

    const stats = Array.isArray(statsRaw) ? statsRaw : [];

    return { setting, stats };
  }

  get fullDescriptionParts(): string[] {
    const raw = (this.setting.full_description || '').trim();
    if (!raw) return [];

    return raw
      .split(/\n+/)
      .map((item) => item.trim())
      .filter(Boolean);
  }

  get privacyPolicy(): string {
    return (
      this.setting.privacy_policy?.trim() ||
      `NAVI chỉ sử dụng dữ liệu bài test để phân tích và gợi ý định hướng.
Thông tin người dùng không được chia sẻ cho bên thứ ba khi chưa có sự đồng ý.
Dữ liệu được dùng để cải thiện kết quả tư vấn và nâng cao trải nghiệm người dùng.`
    );
  }

  get hasStats(): boolean {
    return this.stats.length > 0;
  }

  get heroTitle(): string {
    return this.setting.hero_title?.trim() || 'Về chúng tôi';
  }

  get shortDescription(): string {
    return (
      this.setting.short_description?.trim() ||
      'NAVI giúp người dùng hiểu bản thân rõ hơn và tìm ra hướng đi phù hợp hơn trong học tập cũng như nghề nghiệp.'
    );
  }

  get missionTitle(): string {
    return this.setting.mission_title?.trim() || 'Sứ mệnh';
  }

  get missionDescription(): string {
    return (
      this.setting.mission_description?.trim() ||
      'Giúp người dùng hiểu bản thân rõ hơn để lựa chọn hướng đi phù hợp hơn.'
    );
  }

  get visionTitle(): string {
    return this.setting.vision_title?.trim() || 'Tầm nhìn';
  }

  get visionDescription(): string {
    return (
      this.setting.vision_description?.trim() ||
      'Xây dựng một nền tảng định hướng thân thiện, rõ ràng và dễ tiếp cận cho mọi người dùng.'
    );
  }
}