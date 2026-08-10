import { Component, OnInit, inject, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, RouterModule } from '@angular/router';
import { finalize } from 'rxjs/operators';
import { ResultApiService } from '../../services/result-api.service';
import { API_ORIGIN, STORAGE_URL } from '../../core/api.config';

type AdmissionStatusApi = 'coming_soon' | 'open' | 'closed';

type AdmissionApiItem = {
  id: number;
  school_name: string;
  major_name: string;
  city: string | null;
  short_description: string | null;
  description?: string | null;
  image_url: string | null;
  tags?: string[] | null;
  status: AdmissionStatusApi;
  featured?: boolean;
  tuition_fee?: string | null;
  duration?: string | null;
  credit_count?: string | number | null;
  credits?: string | number | null;
  degree?: string | null;
  admission_method?: string | null;
  application_deadline?: string | null;
  start_date?: string | null;
  register_link?: string | null;
  contact_phone?: string | null;
  contact_email?: string | null;
  is_active?: boolean;
};

type UserAdmissions = {
  id: number;
  school: string;
  program: string;
  location: string;
  status: 'Đang mở' | 'Sắp mở' | 'Đã đóng';
  statusRaw: AdmissionStatusApi;
  desc: string;
  tags: string[];
  image: string | null;
  tuitionFee: string;
  credits: string;
  duration: string;
  degree: string;
  admissionMethod: string;
  admissionMethodList: string[];
  deadlineStart: string;
  deadlineEnd: string;
  startDate: string;
  registerLink: string | null;
  contactPhone: string | null;
  contactEmail: string | null;
};

@Component({
  selector: 'app-admissions',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './admissions.html',
  styleUrl: './admissions.css'
})
export class Admissions implements OnInit {
  private api = inject(ResultApiService);
  private route = inject(ActivatedRoute);

  readonly keyword = signal('');
  readonly activeStatus = signal('Tất cả');

  readonly loading = signal(false);
  readonly error = signal('');
  readonly admissions = signal<UserAdmissions[]>([]);

  readonly showDetailModal = signal(false);
  readonly selectedAdmission = signal<UserAdmissions | null>(null);

  readonly currentPage = signal(1);
  readonly pageSize = 9;

  readonly statuses = ['Tất cả', 'Đang mở', 'Sắp mở', 'Đã đóng'];

  private pendingFocus: { id: number; school: string; major: string } | null = null;

  readonly filteredAdmissions = computed(() => {
    const q = this.normalizeText(this.keyword());

    return this.admissions().filter((item) => {
      const matchStatus =
        this.activeStatus() === 'Tất cả' || item.status === this.activeStatus();

      const searchText = this.normalizeText([
        item.school,
        item.program,
        item.location,
        item.desc,
        item.tuitionFee,
        item.credits,
        item.admissionMethod,
        ...item.tags
      ].join(' '));

      const matchKeyword = !q || searchText.includes(q);

      return matchStatus && matchKeyword;
    });
  });

  readonly totalPages = computed(() => {
    const total = Math.ceil(this.filteredAdmissions().length / this.pageSize);
    return total > 0 ? total : 1;
  });

  readonly paginatedAdmissions = computed(() => {
    const start = (this.currentPage() - 1) * this.pageSize;
    return this.filteredAdmissions().slice(start, start + this.pageSize);
  });

  readonly pageNumbers = computed<(number | string)[]>(() => {
    const total = this.totalPages();
    const current = this.currentPage();

    if (total <= 5) {
      return Array.from({ length: total }, (_, i) => i + 1);
    }

    if (current <= 3) {
      return [1, 2, 3, 4, 5, '...', total];
    }

    if (current >= total - 2) {
      return [1, '...', total - 4, total - 3, total - 2, total - 1, total];
    }

    return [1, '...', current - 1, current, current + 1, '...', total];
  });

  ngOnInit(): void {
    this.readFocusParams();
    this.loadAdmissions();
  }

  loadAdmissions(): void {
    this.loading.set(true);
    this.error.set('');

    this.api.getPublicAdmissions()
      .pipe(
        finalize(() => {
          this.loading.set(false);
          this.ensureValidCurrentPage();
        })
      )
      .subscribe({
        next: (res: any) => {
          const rawItems = Array.isArray(res)
            ? res
            : Array.isArray(res?.data)
              ? res.data
              : [];

          const mappedItems = rawItems
            .map((item: AdmissionApiItem) => this.mapItem(item))
            .sort(() => Math.random() - 0.5);

          this.admissions.set(mappedItems);
          this.currentPage.set(1);
          this.error.set('');
          this.ensureValidCurrentPage();

          this.focusAdmissionFromQuery();
        },
        error: (err) => {
          console.error('load public admissions error:', err);
          this.error.set(err?.error?.message || 'Không tải được dữ liệu tuyển sinh.');
          this.admissions.set([]);
          this.currentPage.set(1);
        }
      });
  }

  setStatus(status: string): void {
    this.activeStatus.set(status);
    this.currentPage.set(1);
    this.ensureValidCurrentPage();
  }

  onKeywordChange(value: string): void {
    this.keyword.set(value ?? '');
    this.currentPage.set(1);
    this.ensureValidCurrentPage();
  }

  clearKeyword(): void {
    this.keyword.set('');
    this.currentPage.set(1);
  }

  goToPage(page: number): void {
    if (page < 1 || page > this.totalPages() || page === this.currentPage()) return;

    this.currentPage.set(page);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  prevPage(): void {
    if (this.currentPage() > 1) {
      this.goToPage(this.currentPage() - 1);
    }
  }

  nextPage(): void {
    if (this.currentPage() < this.totalPages()) {
      this.goToPage(this.currentPage() + 1);
    }
  }

  openDetail(item: UserAdmissions): void {
    this.selectedAdmission.set(item);
    this.showDetailModal.set(true);
  }

  closeDetail(): void {
    this.showDetailModal.set(false);
    this.selectedAdmission.set(null);
  }

  trackById(_: number, item: UserAdmissions): number {
    return item.id;
  }

  trackByPage(_: number, page: number | string): number | string {
    return page;
  }

  private readFocusParams(): void {
    const params = this.route.snapshot.queryParamMap;

    const focus = params.get('focus');
    const id = Number(params.get('admission_id') || params.get('id') || 0);
    const school = String(params.get('school') || '').trim();
    const major = String(params.get('major') || '').trim();

    if (focus === '1' && (id || school || major)) {
      this.pendingFocus = { id, school, major };
    }
  }

  private focusAdmissionFromQuery(): void {
    if (!this.pendingFocus) return;

    const school = this.pendingFocus.school;
    const major = this.pendingFocus.major;
    const id = this.pendingFocus.id;

    const normalizedSchool = this.normalizeText(school);
    const normalizedMajor = this.normalizeText(major);

    this.activeStatus.set('Tất cả');

    const idTarget = id
    ? this.admissions().find(item => item.id === id)
    : null;
    const exactTarget = this.admissions().find(item => {
      const itemSchool = this.normalizeText(item.school);
      const itemProgram = this.normalizeText(item.program);

      const matchSchool =
        !normalizedSchool ||
        itemSchool.includes(normalizedSchool) ||
        normalizedSchool.includes(itemSchool);

      const matchMajor =
        !normalizedMajor ||
        itemProgram.includes(normalizedMajor) ||
        normalizedMajor.includes(itemProgram);

      return matchSchool && matchMajor;
    });

    const looseTarget = idTarget || exactTarget || this.admissions().find(item => {
      const itemSchool = this.normalizeText(item.school);
      const itemProgram = this.normalizeText(item.program);

      return (
        (!!normalizedSchool && itemSchool.includes(normalizedSchool)) ||
        (!!normalizedMajor && itemProgram.includes(normalizedMajor))
      );
    });

    if (!looseTarget) {
      this.keyword.set(`${school} ${major}`.trim());
      this.currentPage.set(1);
      return;
    }

    this.keyword.set('');
    const index = this.filteredAdmissions().findIndex(item => item.id === looseTarget.id);
    const page = index >= 0 ? Math.floor(index / this.pageSize) + 1 : 1;

    this.currentPage.set(page);
    this.ensureValidCurrentPage();

    setTimeout(() => {
      const el = document.getElementById(`admission-${looseTarget.id}`);

      if (!el) return;

      el.scrollIntoView({
        behavior: 'smooth',
        block: 'center'
      });

      el.classList.add('admission-focus');
      this.openDetail(looseTarget);
      
      setTimeout(() => {
        el.classList.remove('admission-focus');
      }, 2800);
    }, 800);
  }

  private ensureValidCurrentPage(): void {
    if (this.currentPage() > this.totalPages()) {
      this.currentPage.set(this.totalPages());
    }

    if (this.currentPage() < 1) {
      this.currentPage.set(1);
    }
  }

  private mapItem(item: AdmissionApiItem): UserAdmissions {
    const tags = Array.isArray(item?.tags) ? item.tags.filter(Boolean) : [];
    const methods = this.parseAdmissionMethods(item?.admission_method);
    const period = this.parseDeadlineRange(item?.application_deadline);

    const creditValue = this.getCredits(item);
    const descValue = this.getDescription(item);

    return {
      id: Number(item?.id ?? 0),
      school: String(item?.school_name ?? ''),
      program: String(item?.major_name ?? ''),
      location: String(item?.city ?? 'Đang cập nhật'),
      status: this.mapStatus(item?.status),
      statusRaw: item?.status ?? 'coming_soon',
      desc: descValue,
      tags: tags.length ? tags : methods.slice(0, 4),
      image: this.resolveImageUrl(item?.image_url),
      tuitionFee: String(item?.tuition_fee ?? 'Đang cập nhật'),
      credits: creditValue,
      duration: creditValue,
      degree: String(item?.degree ?? 'Đang cập nhật'),
      admissionMethod: methods.join(', ') || 'Đang cập nhật',
      admissionMethodList: methods,
      deadlineStart: this.formatSingleDate(period.start),
      deadlineEnd: this.formatSingleDate(period.end),
      startDate: this.formatSingleDate(item?.start_date ?? ''),
      registerLink: item?.register_link ?? null,
      contactPhone: item?.contact_phone ?? null,
      contactEmail: item?.contact_email ?? null
    };
  }

  private getDescription(item: AdmissionApiItem): string {
    const value =
      item?.short_description ??
      item?.description ??
      '';

    const raw = String(value).trim();

    if (!raw) {
      return 'Thông tin mô tả ngành đang được cập nhật.';
    }

    return raw;
  }

  private getCredits(item: AdmissionApiItem): string {
    const value =
      item?.duration ??
      item?.credit_count ??
      item?.credits ??
      '';

    const raw = String(value).trim();

    if (!raw) return 'Đang cập nhật';

    if (raw.toLowerCase().includes('tín chỉ')) {
      return raw;
    }

    return `${raw} tín chỉ`;
  }

  private mapStatus(status: AdmissionStatusApi | undefined): 'Đang mở' | 'Sắp mở' | 'Đã đóng' {
    switch (status) {
      case 'open':
        return 'Đang mở';
      case 'closed':
        return 'Đã đóng';
      default:
        return 'Sắp mở';
    }
  }

  private resolveImageUrl(value: any): string | null {
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
      return raw;
    }

    const cleaned = raw.replace(/^\/+/, '');

    if (
      cleaned.startsWith('images/') ||
      cleaned.startsWith('assets/')
    ) {
      return `/${cleaned}`;
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

  private parseAdmissionMethods(value: string | null | undefined): string[] {
    if (!value) return [];

    return String(value)
      .split(',')
      .map(x => x.trim())
      .filter(Boolean);
  }

  private parseDeadlineRange(value: string | null | undefined): { start: string; end: string } {
    if (!value) return { start: '', end: '' };

    const raw = String(value).trim();
    if (!raw) return { start: '', end: '' };

    if (raw.includes(' - ')) {
      const [start = '', end = ''] = raw.split(' - ');
      return { start: start.trim(), end: end.trim() };
    }

    if (raw.includes(' to ')) {
      const [start = '', end = ''] = raw.split(' to ');
      return { start: start.trim(), end: end.trim() };
    }

    if (raw.includes('|')) {
      const [start = '', end = ''] = raw.split('|');
      return { start: start.trim(), end: end.trim() };
    }

    if (raw.includes('T')) {
      return { start: raw.slice(0, 10), end: '' };
    }

    return { start: raw, end: '' };
  }

  private formatSingleDate(value: string | null | undefined): string {
    if (!value) return 'Đang cập nhật';

    const raw = String(value).trim();
    if (!raw) return 'Đang cập nhật';

    const pure = raw.includes('T') ? raw.slice(0, 10) : raw;
    const m = pure.match(/^(\d{4})-(\d{2})-(\d{2})$/);

    if (m) {
      return `${m[3]}/${m[2]}/${m[1]}`;
    }

    return pure;
  }

  private normalizeText(value: string): string {
    return String(value ?? '')
      .toLowerCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/đ/g, 'd')
      .trim();
  }
}