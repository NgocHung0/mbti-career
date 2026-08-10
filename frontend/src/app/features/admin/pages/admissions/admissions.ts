import { Component, OnInit, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { finalize } from 'rxjs/operators';
import { ResultApiService } from '../../../../services/result-api.service';
import { API_ORIGIN, STORAGE_URL } from '../../../../core/api.config';
import Swal from 'sweetalert2';

type AdmissionStatus = 'coming_soon' | 'open' | 'closed';

export type AdminAdmissions = {
  id: number;
  school_name: string;
  major_name: string;
  city: string | null;
  short_description: string | null;
  image_url: string | null;
  status: AdmissionStatus;
  featured?: boolean | number | null;
  tuition_fee?: string | null;
  duration?: string | null;
  degree?: string | null;
  admission_method?: string | null;
  application_deadline?: string | null;
  start_date?: string | null;
  register_link?: string | null;
  contact_phone?: string | null;
  contact_email?: string | null;
  sort_order?: number | null;
  is_active?: boolean | number | string | null;
  tags?: string[] | string | null;
};

type AdminAdmissionForm = {
  school_name: string;
  major_name: string;
  city: string;
  short_description: string;
  status: AdmissionStatus;
  tuition_fee: string;
  credit_count: string;
  method_hoc_ba: boolean;
  method_thpt: boolean;
  method_dgnl: boolean;
  method_xettuyen_rieng: boolean;
  custom_methods: string;
  deadline_start: string;
  deadline_end: string;
  register_link: string;
  contact_phone: string;
  contact_email: string;
  featured: boolean;
  degree: string;
  tags: string;
  sort_order: string;
};

@Component({
  selector: 'app-admissions-admin',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './admissions.html',
  styleUrl: './admissions.css'
})
export class AdmissionsAdmin implements OnInit {
  private api = inject(ResultApiService);
  private cdr = inject(ChangeDetectorRef);
  
  showDeadlineInputs = true;
  loading = false;
  saving = false;
  error = '';

  items: AdminAdmissions[] = [];
  filteredItems: AdminAdmissions[] = [];

  keyword = '';
  statusFilter: AdmissionStatus | 'all' = 'all';

  private searchTimer:
  ReturnType<typeof setTimeout> | null = null;

  currentPage = 1;
  perPage = 10;
  total = 0;
  totalPages = 1;

  deletingId: number | null = null;
  togglingId: number | null = null;

  showModal = false;
  editingId: number | null = null;

  selectedImageFile: File | null = null;
  previewImage = '';

  readonly cityOptions = [
    'TP. Hồ Chí Minh',
    'Hà Nội',
    'Đà Nẵng',
    'Cần Thơ',
    'Bình Dương',
    'Đồng Nai',
    'Huế',
    'Khác'
  ];

  form: AdminAdmissionForm = this.createEmptyForm();

  ngOnInit(): void {
    this.loadAdmissions(1);
  }

  createEmptyForm(): AdminAdmissionForm {
    return {
      school_name: '',
      major_name: '',
      city: 'TP. Hồ Chí Minh',
      short_description: '',
      status: 'coming_soon',
      tuition_fee: '',
      credit_count: '',
      method_hoc_ba: false,
      method_thpt: false,
      method_dgnl: false,
      method_xettuyen_rieng: false,
      custom_methods: '',
      deadline_start: '',
      deadline_end: '',
      register_link: '',
      contact_phone: '',
      featured: false,
      contact_email: '',
      degree: '',
      tags: '',
      sort_order: ''
    };
  }

  loadAdmissions(page: number = 1): void {
    this.loading = true;
    this.error = '';

    this.api
      .getAdminAdmissions(
        page,
        this.perPage,
        this.keyword,
        true,
        this.statusFilter
      )
      .pipe(
        finalize(() => {
          this.loading = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: (res: any) => {
          const rawItems = Array.isArray(res)
            ? res
            : Array.isArray(res?.data)
              ? res.data
              : [];

          this.items = rawItems.map(
            (item: AdminAdmissions) => ({
              ...item,
              image_url: this.resolveImageUrl(
                item.image_url
              ),
              is_active: this.toBoolean(
                item.is_active
              )
            })
          );

          /*
          * Backend đã tìm trên toàn DB,
          * frontend chỉ nhận kết quả của trang.
          */
          this.filteredItems = [...this.items];

          this.currentPage = Number(
            res?.current_page ?? page ?? 1
          );

          this.perPage = Number(
            res?.per_page ?? this.perPage
          );

          this.total = Number(
            res?.total ?? this.items.length
          );

          this.totalPages = Math.max(
            1,
            Number(
              res?.last_page ??
              Math.ceil(this.total / this.perPage)
            )
          );

          this.cdr.detectChanges();
        },

        error: (err) => {
          console.error(
            'load admin admissions error:',
            err
          );

          this.error =
            err?.error?.message ||
            'Không tải được dữ liệu tuyển sinh.';

          this.items = [];
          this.filteredItems = [];
        }
      });
  }

  applyFilters(): void {
    this.filteredItems = [...this.items];

    this.cdr.detectChanges();
  }

  search(): void {
    if (this.searchTimer) {
      clearTimeout(this.searchTimer);
      this.searchTimer = null;
    }

    this.currentPage = 1;
    this.loadAdmissions(1);
  }

  onChangeFilter(): void {
    if (this.searchTimer) {
      clearTimeout(this.searchTimer);
      this.searchTimer = null;
    }

    this.currentPage = 1;
    this.loadAdmissions(1);
  }

  onSearchChange(): void {
    this.currentPage = 1;

    if (this.searchTimer) {
      clearTimeout(this.searchTimer);
    }

    this.searchTimer = setTimeout(() => {
      this.searchTimer = null;
      this.loadAdmissions(1);
    }, 300);
  }

  openCreate(): void {
    this.editingId = null;
    this.form = this.createEmptyForm();
    this.selectedImageFile = null;
    this.previewImage = '';
    this.showModal = true;
    this.cdr.detectChanges();
  }

  openEdit(item: AdminAdmissions): void {
    const methods = this.parseAdmissionMethods(item.admission_method);
    const deadline = this.parseDeadlineRange(item.application_deadline);
    const methodText = String(item.admission_method ?? '').toLowerCase();

    this.editingId = item.id;

    this.form = {
      school_name: item.school_name ?? '',
      major_name: item.major_name ?? '',
      city: item.city ?? 'TP. Hồ Chí Minh',
      short_description: item.short_description ?? '',
      status: item.status ?? 'coming_soon',

      featured: this.toBoolean(item.featured),

      tuition_fee: item.tuition_fee ?? '',
      credit_count: item.duration ?? '',

      method_hoc_ba: methodText.includes('học bạ'),
      method_thpt: methodText.includes('thpt'),
      method_dgnl: methodText.includes('đgnl') || methodText.includes('đánh giá năng lực'),
      method_xettuyen_rieng:
        methodText.includes('xét tuyển riêng') ||
        methodText.includes('xét tuyển thẳng') ||
        methodText.includes('theo đề án'),

      custom_methods: '',

      deadline_start: deadline.start,
      deadline_end: deadline.end,

      register_link: item.register_link ?? '',
      contact_phone: item.contact_phone ?? '',
      contact_email: item.contact_email ?? '',
      degree: item.degree ?? '',

      tags: Array.isArray((item as any).tags)
        ? (item as any).tags.join(', ')
        : String((item as any).tags ?? ''),

      sort_order: String(item.sort_order ?? '')
    };

    this.selectedImageFile = null;
    this.previewImage = item.image_url ?? '';
    this.showModal = true;
    this.cdr.detectChanges();
  }

  closeModal(force: boolean = false): void {
    if (this.saving && !force) return;

    this.showModal = false;
    this.editingId = null;
    this.form = this.createEmptyForm();
    this.selectedImageFile = null;
    this.previewImage = '';
    this.cdr.detectChanges();
  }

  onFileChange(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0] ?? null;

    this.selectedImageFile = file;

    if (!file) {
      this.previewImage = '';
      this.cdr.detectChanges();
      return;
    }

    const reader = new FileReader();

    reader.onload = () => {
      this.previewImage = String(reader.result ?? '');
      this.cdr.detectChanges();
    };

    reader.readAsDataURL(file);
  }

  buildAdmissionMethods(): string {
    const methods: string[] = [];

    if (this.form.method_hoc_ba) methods.push('Xét tuyển học bạ');
    if (this.form.method_thpt) methods.push('THPT Quốc gia');
    if (this.form.method_dgnl) methods.push('Đánh giá năng lực');
    if (this.form.method_xettuyen_rieng) methods.push('Xét tuyển riêng');

    const custom = this.form.custom_methods
      .split(',')
      .map(x => x.trim())
      .filter(Boolean);

    methods.push(...custom);

    return methods.join(', ');
  }

  buildDeadlineRange(): string {
    const start = this.form.deadline_start.trim();
    const end = this.form.deadline_end.trim();

    if (start && end) return `${start} - ${end}`;
    if (start) return start;
    if (end) return end;

    return '';
  }

 buildPayload(): FormData {
  const payload = new FormData();

  payload.append('school_name', String(this.form.school_name ?? '').trim());
  payload.append('major_name', String(this.form.major_name ?? '').trim());
  payload.append('city', String(this.form.city ?? '').trim());
  payload.append('short_description', String(this.form.short_description ?? '').trim());

  payload.append('status', String(this.form.status ?? 'coming_soon'));
  payload.append('featured', this.form.featured ? '1' : '0');

  payload.append('tuition_fee', String(this.form.tuition_fee ?? '').trim());

  // Số tín chỉ
  payload.append('duration', String(this.form.credit_count ?? '').trim());

  payload.append('degree', this.form.degree);
  payload.append('admission_method', this.buildAdmissionMethods());
  payload.append('application_deadline', this.buildDeadlineRange());
  payload.append('start_date', '');

  payload.append('register_link', String(this.form.register_link ?? '').trim());
  payload.append('contact_phone', String(this.form.contact_phone ?? '').trim());
  payload.append('contact_email', String(this.form.contact_email ?? '').trim());

  payload.append('sort_order', this.form.sort_order || '0');
  payload.append('is_active', '1');

  const tagsArray = this.form.tags
    .split(',')
    .map(x => x.trim())
    .filter(Boolean);

  payload.append('tags', JSON.stringify(tagsArray));

  if (this.selectedImageFile) {
    payload.append('image', this.selectedImageFile);
  }

  return payload;
}

  save(): void {
    if (this.saving) return;

    if (!this.form.school_name.trim()) {
      alert('Vui lòng nhập tên trường.');
      return;
    }

    if (!this.form.major_name.trim()) {
      alert('Vui lòng nhập tên ngành.');
      return;
    }

    this.saving = true;

    const payload = this.buildPayload();

    const request$ = this.editingId
      ? this.api.updateAdminAdmission(this.editingId, payload)
      : this.api.createAdminAdmission(payload);

    request$
      .pipe(
        finalize(() => {
          this.saving = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: () => {
          const targetPage = this.editingId ? this.currentPage : 1;
          this.closeModal(true);
          this.loadAdmissions(targetPage);
        },
        error: (err) => {
          console.error('save admission error:', err);

          const validation = err?.error?.errors;

          if (validation) {
            const firstKey = Object.keys(validation)[0];
            const firstMessage = Array.isArray(validation[firstKey])
              ? validation[firstKey][0]
              : validation[firstKey];

            alert(firstMessage || 'Lưu tuyển sinh thất bại.');
            return;
          }

          alert(
            err?.error?.message ||
            err?.error?.error ||
            'Lưu tuyển sinh thất bại.'
          );
        }
      });
  }

  remove(item: AdminAdmissions): void {
    if (this.deletingId === item.id) return;

    const confirmed = confirm(`Bạn có chắc muốn xóa tuyển sinh "${item.major_name}" không?`);
    if (!confirmed) return;

    this.deletingId = item.id;

    this.api.deleteAdminAdmission(item.id)
      .pipe(
        finalize(() => {
          this.deletingId = null;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: () => {
          this.items = this.items.filter(x => x.id !== item.id);
          this.total = Math.max(0, this.total - 1);

          if (this.items.length === 0 && this.currentPage > 1) {
            this.loadAdmissions(this.currentPage - 1);
            return;
          }

          this.applyFilters();
        },
        error: (err) => {
          console.error('delete admission error:', err);
          alert(err?.error?.message || 'Xóa tuyển sinh thất bại.');
        }
      });
  }

  toggleVisible(item: AdminAdmissions): void {

  if (this.togglingId !== null) return;

  const nextValue = !this.toBoolean(item.is_active);
  this.togglingId = item.id;

  const payload = new FormData();

  payload.append('school_name', item.school_name ?? '');
  payload.append('major_name', item.major_name ?? '');
  payload.append('city', item.city ?? '');
  payload.append('short_description', item.short_description ?? '');
  payload.append('status', item.status ?? 'coming_soon');
  payload.append('featured', this.toBoolean(item.featured) ? '1' : '0');
  payload.append('tuition_fee', item.tuition_fee ?? '');

  // QUAN TRỌNG: duration phải lấy từ item
  payload.append('duration', item.duration ?? '');

  payload.append('degree', item.degree ?? '');
  payload.append('admission_method', item.admission_method ?? '');
  payload.append('application_deadline', item.application_deadline ?? '');
  payload.append('start_date', item.start_date ?? '');
  payload.append('register_link', item.register_link ?? '');
  payload.append('contact_phone', item.contact_phone ?? '');
  payload.append('contact_email', item.contact_email ?? '');
  payload.append('sort_order', String(item.sort_order ?? 0));
  payload.append('is_active', nextValue ? '1' : '0');

  this.api.updateAdminAdmission(item.id, payload)
    .pipe(
      finalize(() => {
        this.togglingId = null;
        this.cdr.detectChanges();
      })
    )
    .subscribe({
      next: () => {
        item.is_active = nextValue;
        this.applyFilters();
      },
      error: (err) => {
        console.error('toggle admission visible error:', err);
        alert(err?.error?.message || 'Cập nhật hiển thị thất bại.');
      }
    });
}

  changePage(page: number): void {
    if (page < 1 || page > this.totalPages || page === this.currentPage) return;
    this.loadAdmissions(page);
  }

  trackById(_: number, item: AdminAdmissions): number {
    return item.id;
  }

  get pages(): (number | '...')[] {
    const total = this.totalPages;
    const current = this.currentPage;

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
  }

  getStatusLabel(status: AdmissionStatus): string {
    switch (status) {
      case 'coming_soon':
        return 'Sắp mở';
      case 'open':
        return 'Đang mở';
      case 'closed':
        return 'Đã đóng';
      default:
        return 'Không rõ';
    }
  }

  parseAdmissionMethods(value: string | null | undefined): string[] {
    if (!value) return [];

    return String(value)
      .split(',')
      .map(v => v.trim())
      .filter(Boolean);
  }

  extractCustomMethods(methods: string[]): string[] {
    const defaults = [
      'Xét tuyển học bạ',
      'THPT Quốc gia',
      'Đánh giá năng lực',
      'Xét tuyển riêng'
    ];

    return methods.filter(method => !defaults.includes(method));
  }

  parseDeadlineRange(value: string | null | undefined): { start: string; end: string } {
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

  formatSingleDate(value: string | null | undefined): string {
    if (!value) return '—';

    const raw = String(value).trim();
    if (!raw) return '—';

    const pure = raw.includes('T') ? raw.slice(0, 10) : raw;
    const m = pure.match(/^(\d{4})-(\d{2})-(\d{2})$/);

    if (m) {
      return `${m[3]}/${m[2]}/${m[1]}`;
    }

    return pure;
  }

  getDeadlineStart(value: string | null | undefined): string {
    return this.formatSingleDate(this.parseDeadlineRange(value).start);
  }

  getDeadlineEnd(value: string | null | undefined): string {
    return this.formatSingleDate(this.parseDeadlineRange(value).end);
  }

  resolveImageUrl(value: any): string | null {
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

  toBoolean(value: any): boolean {
    return value === true || value === 1 || value === '1' || value === 'true';
  }

  onStatusChange(): void {
    if (this.form.status === 'closed') {
      this.form.deadline_start = '';
      this.form.deadline_end = '';
    }

    this.cdr.detectChanges();
  }

  todayDate(): string {
    const d = new Date();
    const yyyy = d.getFullYear();
    const mm = String(d.getMonth() + 1).padStart(2, '0');
    const dd = String(d.getDate()).padStart(2, '0');

    return `${yyyy}-${mm}-${dd}`;
  }

  onDeadlineStartChange(): void {
    setTimeout(() => {
      if (
        this.form.status === 'coming_soon' &&
        this.form.deadline_start &&
        this.form.deadline_start < this.todayDate()
      ) {
        this.form.deadline_start = '';
        this.showError('Trạng thái sắp mở không được chọn ngày trong quá khứ.');
        this.rerenderDeadlineInputs();
        return;
      }

      if (
        this.form.deadline_start &&
        this.form.deadline_end &&
        this.form.deadline_end < this.form.deadline_start
      ) {
        this.form.deadline_end = '';
        this.showError('Hạn chót không được nhỏ hơn ngày bắt đầu.');
        this.rerenderDeadlineInputs();
        return;
      }

      this.cdr.detectChanges();
    });
  }

  onDeadlineEndChange(): void {
    setTimeout(() => {
      if (
        this.form.status === 'coming_soon' &&
        this.form.deadline_end &&
        this.form.deadline_end < this.todayDate()
      ) {
        this.form.deadline_end = '';
        this.showError('Trạng thái sắp mở không được chọn ngày trong quá khứ.');
        this.rerenderDeadlineInputs();
        return;
      }

      if (
        this.form.deadline_start &&
        this.form.deadline_end &&
        this.form.deadline_end < this.form.deadline_start
      ) {
        this.form.deadline_end = '';
        this.showError('Hạn chót không được nhỏ hơn ngày bắt đầu.');
        this.rerenderDeadlineInputs();
        return;
      }

      this.cdr.detectChanges();
    });
  }

  getDateMin(): string | null {
    return this.form.status === 'coming_soon' ? this.todayDate() : null;
  }

  showError(message: string): void {
    Swal.fire({
      toast: true,
      position: 'top-end',
      icon: 'error',
      title: message,
      showConfirmButton: false,
      timer: 2600,
      timerProgressBar: true,
    });
  }

  showSuccess(message: string): void {
    Swal.fire({
      toast: true,
      position: 'top-end',
      icon: 'success',
      title: message,
      showConfirmButton: false,
      timer: 2200,
      timerProgressBar: true,
    });
  }

  rerenderDeadlineInputs(): void {
    this.showDeadlineInputs = false;
    this.cdr.detectChanges();

    setTimeout(() => {
      this.showDeadlineInputs = true;
      this.cdr.detectChanges();
    });
  }
}