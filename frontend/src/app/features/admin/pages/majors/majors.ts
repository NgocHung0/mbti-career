import { Component, OnInit, ChangeDetectorRef, NgZone } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { finalize, timeout } from 'rxjs/operators';
import { ResultApiService } from '../../../../services/result-api.service';

type MajorRow = {
  id: number;
  name: string;
  code: string | null;
  description: string | null;
  short_description?: string | null;
  image_url?: string | null;
  career_prospects: string | null;
  skills: string | null;
  top_schools: string[];
  status: 'active' | 'inactive';
  suitable_mbti: string[];
  interest_profile: {
    creative: number;
    analytic: number;
    social: number;
    business: number;
  };

  ability_profile: {
    LANGUAGE: number;
    LOGIC: number;
    CREATIVE: number;
    TECH: number;
    LEADERSHIP: number;
    TEAMWORK: number;
    DETAIL: number;
    ADAPT: number;
    PRACTICAL: number;
    STRATEGIC: number;
  };
  vector?: {
    E: number;
    S: number;
    T: number;
    J: number;
  };
  vector_e: number;
  vector_s: number;
  vector_t: number;
  vector_j: number;
  created_at?: string;
  updated_at?: string;
};

type MajorForm = {
  name: string;
  code: string;
  description: string;
  career_prospects: string;
  skills: string;
  top_schools_text: string;
  status: 'active' | 'inactive';
  vector_e: number;
  vector_s: number;
  vector_t: number;
  vector_j: number;
  suitable_mbti: string[];
  interest_creative: number;
  interest_analytic: number;
  interest_social: number;
  interest_business: number;
  ability_LANGUAGE: number;
  ability_LOGIC: number;
  ability_CREATIVE: number;
  ability_TECH: number;
  ability_LEADERSHIP: number;
  ability_TEAMWORK: number;
  ability_DETAIL: number;
  ability_ADAPT: number;
  ability_PRACTICAL: number;
  ability_STRATEGIC: number;
};

type AiVectorResult = {
  vector_e: number;
  vector_s: number;
  vector_t: number;
  vector_j: number;
  source?: string;
  summary?: string;
  top_schools?: string[];
  explanation?: {
    E?: string;
    S?: string;
    T?: string;
    J?: string;
  };
};

@Component({
  selector: 'app-admin-majors',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './majors.html',
  styleUrls: ['./majors.css']
})
export class AdminMajors implements OnInit {
  q = '';
  statusFilter: 'all' | 'active' | 'inactive' = 'all';

  loading = false;
  error = '';

  items: MajorRow[] = [];

  currentPage = 1;
  perPage = 10;
  lastPage = 1;
  total = 0;

  summaryActive = 0;
  summaryInactive = 0;

  showViewModal = false;
  showCreateModal = false;
  showEditModal = false;
  showDeleteModal = false;

  selectedItem: MajorRow | null = null;

  creating = false;
  updating = false;
  deleting = false;

  createError = '';
  editError = '';
  deleteError = '';

  createForm: MajorForm = this.getEmptyForm();
  editForm: MajorForm = this.getEmptyForm();

  createAiLoading = false;
  editAiLoading = false;

  createAiError = '';
  editAiError = '';

  createAiResult: AiVectorResult | null = null;
  editAiResult: AiVectorResult | null = null;

  createImageFile: File | null = null;
  editImageFile: File | null = null;

  createImagePreview = '';
  editImagePreview = '';
  readonly mbtiOptions = [
    'INTJ','INTP','ENTJ','ENTP',

    'INFJ','INFP','ENFJ','ENFP',

    'ISTJ','ISFJ','ESTJ','ESFJ',

    'ISTP','ISFP','ESTP','ESFP'
  ];
  readonly profileLevelOptions = [
    { value: 0, label: 'Không liên quan' },
    { value: 1, label: 'Liên quan phụ' },
    { value: 2, label: 'Liên quan chính' },
    { value: 3, label: 'Cốt lõi / bắt buộc' }
  ];
  readonly defaultPreview = '/images/major-default.png';

  constructor(
    private api: ResultApiService,
    private cdr: ChangeDetectorRef,
    private zone: NgZone
  ) {}

  ngOnInit(): void {
    if (typeof window === 'undefined') return;
    this.loadItems(1);
  }

  trackById(_: number, item: MajorRow): number {
    return item.id;
  }

  getEmptyForm(): MajorForm {
    return {
      name: '',
      code: '',
      description: '',
      career_prospects: '',
      skills: '',
      top_schools_text: '',
      status: 'active',
      vector_e: 50,
      vector_s: 50,
      vector_t: 50,
      vector_j: 50,
      suitable_mbti: [],
      interest_creative: 0,
      interest_analytic: 0,
      interest_social: 0,
      interest_business: 0,
      ability_LANGUAGE: 0,
      ability_LOGIC: 0,
      ability_CREATIVE: 0,
      ability_TECH: 0,
      ability_LEADERSHIP: 0,
      ability_TEAMWORK: 0,
      ability_DETAIL: 0,
      ability_ADAPT: 0,
      ability_PRACTICAL: 0,
      ability_STRATEGIC: 0,
    };
  }

  onlyNumberCode(form: MajorForm): void {
    form.code = String(form.code || '').replace(/\D/g, '');
  }

  private clampVector(value: unknown): number {
    const num = Number(value);
    if (Number.isNaN(num)) return 50;
    return Math.max(0, Math.min(100, Math.round(num)));
  }

  private clampProfileLevel(value: unknown): number {
    const num = Number(value);
    if (Number.isNaN(num)) return 0;
    return Math.max(0, Math.min(3, Math.round(num)));
  }

  private parseJsonArray(value: any): any[] {
    if (Array.isArray(value)) return value;

    if (typeof value === 'string' && value.trim()) {
      try {
        const parsed = JSON.parse(value);
        return Array.isArray(parsed) ? parsed : [];
      } catch {
        return [];
      }
    }

    return [];
  }

  private parseJsonObject<T extends Record<string, any>>(value: any, fallback: T): T {
    if (value && typeof value === 'object' && !Array.isArray(value)) {
      return { ...fallback, ...value };
    }

    if (typeof value === 'string' && value.trim()) {
      try {
        const parsed = JSON.parse(value);
        if (parsed && typeof parsed === 'object' && !Array.isArray(parsed)) {
          return { ...fallback, ...parsed };
        }
      } catch {
        return fallback;
      }
    }

    return fallback;
  }

  private normalizeAbilityProfile(
    value: any
  ): MajorRow['ability_profile'] {
    let raw: any = value;

    /*
    * Trường hợp API trả ability_profile
    * dưới dạng chuỗi JSON.
    */
    if (
      typeof raw === 'string' &&
      raw.trim()
    ) {
      try {
        raw = JSON.parse(raw);
      } catch {
        raw = {};
      }
    }

    if (
      !raw ||
      typeof raw !== 'object' ||
      Array.isArray(raw)
    ) {
      raw = {};
    }

    /*
    * Chuẩn hóa:
    * Ngôn ngữ → NGON_NGU
    * language → LANGUAGE
    * Chi tiết / cẩn thận → CHI_TIET_CAN_THAN
    */
    const normalized: Record<string, any> = {};

    Object.entries(raw).forEach(
      ([key, profileValue]) => {
        const normalizedKey = String(key)
          .trim()
          .normalize('NFD')
          .replace(
            /[\u0300-\u036f]/g,
            ''
          )
          .replace(/đ/g, 'd')
          .replace(/Đ/g, 'D')
          .toUpperCase()
          .replace(
            /[^A-Z0-9]+/g,
            '_'
          )
          .replace(
            /^_+|_+$/g,
            ''
          );

        normalized[normalizedKey] =
          profileValue;
      }
    );

    /*
    * Lấy giá trị đầu tiên tìm thấy
    * trong danh sách tên tương ứng.
    */
    const getValue = (
      ...keys: string[]
    ): number => {
      for (const key of keys) {
        if (
          normalized[key] !== undefined &&
          normalized[key] !== null &&
          normalized[key] !== ''
        ) {
          return this.clampProfileLevel(
            normalized[key]
          );
        }
      }

      return 0;
    };

    return {
      LANGUAGE: getValue(
        'LANGUAGE',
        'NGON_NGU',
        'NGON_NGU_DIEN_DAT'
      ),

      LOGIC: getValue(
        'LOGIC',
        'TU_DUY_LOGIC',
        'LOGIC_LAP_LUAN'
      ),

      CREATIVE: getValue(
        'CREATIVE',
        'SANG_TAO'
      ),

      TECH: getValue(
        'TECH',
        'TECHNOLOGY',
        'CONG_NGHE'
      ),

      LEADERSHIP: getValue(
        'LEADERSHIP',
        'LANH_DAO'
      ),

      TEAMWORK: getValue(
        'TEAMWORK',
        'TEAM_WORK',
        'LAM_VIEC_NHOM'
      ),

      DETAIL: getValue(
        'DETAIL',
        'CAREFUL',
        'DETAIL_CAREFUL',
        'CHI_TIET',
        'CAN_THAN',
        'CHI_TIET_CAN_THAN'
      ),

      ADAPT: getValue(
        'ADAPT',
        'ADAPTABILITY',
        'THICH_NGHI',
        'THICH_UNG'
      ),

      PRACTICAL: getValue(
        'PRACTICAL',
        'PRACTICE',
        'THUC_HANH'
      ),

      STRATEGIC: getValue(
        'STRATEGIC',
        'STRATEGY',
        'CHIEN_LUOC'
      )
    };
  }

  isMbtiSelected(form: MajorForm, type: string): boolean {
    return (form.suitable_mbti || []).includes(type);
  }

  toggleMbti(form: MajorForm, type: string, event: Event): void {
    const checked = (event.target as HTMLInputElement).checked;
    const selected = new Set(form.suitable_mbti || []);

    if (checked) {
      selected.add(type);
    } else {
      selected.delete(type);
    }

    form.suitable_mbti = Array.from(selected);
  }

  private normalizeRow(item: any): MajorRow {
    return {
      id: Number(item?.id ?? 0),
      name: item?.name ?? '',
      code: item?.code ?? null,
      description: item?.description ?? null,
      short_description: item?.short_description ?? null,
      image_url: item?.image_url ?? null,
      career_prospects: item?.career_prospects ?? null,
      skills: item?.skills ?? null,
      status: item?.status === 'inactive' ? 'inactive' : 'active',
      vector: item?.vector,
      vector_e: this.clampVector(item?.vector_e ?? item?.vector?.E ?? 50),
      vector_s: this.clampVector(item?.vector_s ?? item?.vector?.S ?? 50),
      vector_t: this.clampVector(item?.vector_t ?? item?.vector?.T ?? 50),
      vector_j: this.clampVector(item?.vector_j ?? item?.vector?.J ?? 50),
      created_at: item?.created_at,
      updated_at: item?.updated_at,
      top_schools: this.parseJsonArray(item?.top_schools).map(String),
      suitable_mbti: this.parseJsonArray(item?.suitable_mbti).map(String),
      interest_profile: this.parseJsonObject(item?.interest_profile, {
        creative: 0,
        analytic: 0,
        social: 0,
        business: 0
      }),
      ability_profile:
        this.normalizeAbilityProfile(
          item?.ability_profile
        ),
    };
  }

  private detect(): void {
    this.cdr.detectChanges();
  }

  private recalcSummaryFromCurrentItems(): void {
    this.summaryActive = this.items.filter(item => item.status === 'active').length;
    this.summaryInactive = this.items.filter(item => item.status === 'inactive').length;
  }

  private resetModalState(): void {
    this.showViewModal = false;
    this.showCreateModal = false;
    this.showEditModal = false;
    this.showDeleteModal = false;
    this.selectedItem = null;

    this.createError = '';
    this.editError = '';
    this.deleteError = '';

    this.createAiError = '';
    this.editAiError = '';

    this.createAiResult = null;
    this.editAiResult = null;
  }

  private resetCreateImage(): void {
    this.createImageFile = null;
    this.createImagePreview = '';
  }

  private resetEditImage(): void {
    this.editImageFile = null;
    this.editImagePreview = '';
  }

  getCreatePreview(): string {
    return this.createImagePreview || this.defaultPreview;
  }

  getEditPreview(): string {
    return this.editImagePreview || this.selectedItem?.image_url || this.defaultPreview;
  }

  onCreateImageChange(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0] ?? null;

    this.createImageFile = file;
    this.createImagePreview = '';

    if (!file) {
      this.detect();
      return;
    }

    if (!file.type.startsWith('image/')) {
      this.createError = 'Vui lòng chọn file ảnh hợp lệ.';
      this.createImageFile = null;
      input.value = '';
      this.detect();
      return;
    }

    const reader = new FileReader();
    reader.onload = () => {
      this.zone.run(() => {
        this.createImagePreview = String(reader.result || '');
        this.createError = '';
        this.detect();
      });
    };
    reader.readAsDataURL(file);
  }

  onEditImageChange(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0] ?? null;

    this.editImageFile = file;
    this.editImagePreview = '';

    if (!file) {
      this.detect();
      return;
    }

    if (!file.type.startsWith('image/')) {
      this.editError = 'Vui lòng chọn file ảnh hợp lệ.';
      this.editImageFile = null;
      input.value = '';
      this.detect();
      return;
    }

    const reader = new FileReader();
    reader.onload = () => {
      this.zone.run(() => {
        this.editImagePreview = String(reader.result || '');
        this.editError = '';
        this.detect();
      });
    };
    reader.readAsDataURL(file);
  }

  clearCreateImage(input?: HTMLInputElement): void {
    this.resetCreateImage();
    if (input) input.value = '';
    this.detect();
  }

  clearEditImage(input?: HTMLInputElement): void {
    this.resetEditImage();
    if (input) input.value = '';
    this.detect();
  }

  loadItems(page: number = 1): void {
    if (typeof window === 'undefined') return;

    this.loading = true;
    this.error = '';
    this.detect();

    this.api.getAdminMajors(1, 1000, '', true)
      .pipe(
        timeout(10000),
        finalize(() => {
          this.zone.run(() => {
            this.loading = false;
            this.detect();
          });
        })
      )
      .subscribe({
        next: (res: any) => {
          this.zone.run(() => {
            const rows = Array.isArray(res?.data) ? res.data : [];
            this.items = rows.map((item: any) => this.normalizeRow(item));

            this.currentPage = 1;
            this.perPage = 10;
            this.currentPage = 1;
            this.lastPage = this.totalFilteredPages;

            this.total = Number(
              res?.summary?.total ??
              res?.counts?.total ??
              res?.total_count ??
              res?.total ??
              this.items.length
            );

            this.summaryActive = Number(
              res?.summary?.active ??
              res?.counts?.active ??
              res?.active_count ??
              this.items.filter(item => item.status === 'active').length
            );

            this.summaryInactive = Number(
              res?.summary?.inactive ??
              res?.counts?.inactive ??
              res?.inactive_count ??
              this.items.filter(item => item.status === 'inactive').length
            );

            this.error = '';
            this.detect();
          });
        },
        error: (err) => {
          console.error('ADMIN MAJORS ERROR:', err);
          this.zone.run(() => {
            this.items = [];
            this.error = err?.error?.message || 'Không tải được danh sách ngành nghề.';
            this.detect();
          });
        }
      });
  }

  get filteredItems(): MajorRow[] {
    const keyword = this.q.trim().toLowerCase();

    return this.items.filter((item) => {
      const matchKeyword =
        !keyword ||
        (item.name || '').toLowerCase().includes(keyword) ||
        String(item.code || '').toLowerCase().includes(keyword);

      const matchStatus =
        this.statusFilter === 'all' || item.status === this.statusFilter;

      return matchKeyword && matchStatus;
    });
  }

  get pagedItems(): MajorRow[] {
    const start = (this.currentPage - 1) * this.perPage;
    return this.filteredItems.slice(start, start + this.perPage);
  }

  get totalFilteredPages(): number {
    return Math.max(1, Math.ceil(this.filteredItems.length / this.perPage));
  }

  totalMajors(): number {
    return this.items.length || this.total;
  }

  activeMajors(): number {
    return this.filteredItems.filter(item => item.status === 'active').length;
  }

  inactiveMajors(): number {
    return this.filteredItems.filter(item => item.status === 'inactive').length;
  }

  rowNumber(index: number): number {
    return (this.currentPage - 1) * this.perPage + index + 1;
  }

  goToPage(page: number): void {
    const maxPage = this.totalFilteredPages;

    if (page < 1 || page > maxPage || page === this.currentPage) return;

    this.currentPage = page;

    window.scrollTo({
      top: 0,
      behavior: 'smooth',
    });

    this.detect();
  }

  pageNumbers(): Array<number | string> {
    const total = this.totalFilteredPages;
    const current = this.currentPage;

    if (total <= 7) {
      return Array.from({ length: total }, (_, i) => i + 1);
    }

    if (current <= 4) {
      return [1, 2, 3, 4, 5, '...', total];
    }

    if (current >= total - 3) {
      return [1, '...', total - 4, total - 3, total - 2, total - 1, total];
    }

    return [1, '...', current - 1, current, current + 1, '...', total];
  }

  resetFilters(): void {
    this.q = '';
    this.statusFilter = 'all';
    this.loadItems(1);
  }

  formatDate(date?: string): string {
    if (!date) return '';
    const d = new Date(date);
    if (Number.isNaN(d.getTime())) return '';
    return d.toLocaleDateString('vi-VN');
  }

  toArrayFromTextarea(value: string): string[] {
    return (value || '')
      .split('\n')
      .map(item => item.trim())
      .filter(Boolean);
  }

  private appendFormData(formData: FormData, form: MajorForm): void {
    formData.append('name', form.name.trim());
    formData.append('code', form.code.trim());
    formData.append('description', form.description.trim());
    formData.append('career_prospects', form.career_prospects.trim());
    formData.append('skills', form.skills.trim());
    formData.append('status', form.status);

    formData.append('vector_e', String(this.clampVector(form.vector_e)));
    formData.append('vector_s', String(this.clampVector(form.vector_s)));
    formData.append('vector_t', String(this.clampVector(form.vector_t)));
    formData.append('vector_j', String(this.clampVector(form.vector_j)));

    (form.suitable_mbti || []).forEach((type, index) => {
      formData.append(`suitable_mbti[${index}]`, type);
    });

    formData.append('interest_profile[creative]', String(this.clampProfileLevel(form.interest_creative)));
    formData.append('interest_profile[analytic]', String(this.clampProfileLevel(form.interest_analytic)));
    formData.append('interest_profile[social]', String(this.clampProfileLevel(form.interest_social)));
    formData.append('interest_profile[business]', String(this.clampProfileLevel(form.interest_business)));

    formData.append('ability_profile[LANGUAGE]', String(this.clampProfileLevel(form.ability_LANGUAGE)));
    formData.append('ability_profile[LOGIC]', String(this.clampProfileLevel(form.ability_LOGIC)));
    formData.append('ability_profile[CREATIVE]', String(this.clampProfileLevel(form.ability_CREATIVE)));
    formData.append('ability_profile[TECH]', String(this.clampProfileLevel(form.ability_TECH)));
    formData.append('ability_profile[LEADERSHIP]', String(this.clampProfileLevel(form.ability_LEADERSHIP)));
    formData.append('ability_profile[TEAMWORK]', String(this.clampProfileLevel(form.ability_TEAMWORK)));
    formData.append('ability_profile[DETAIL]', String(this.clampProfileLevel(form.ability_DETAIL)));
    formData.append('ability_profile[ADAPT]', String(this.clampProfileLevel(form.ability_ADAPT)));
    formData.append('ability_profile[PRACTICAL]', String(this.clampProfileLevel(form.ability_PRACTICAL)));
    formData.append('ability_profile[STRATEGIC]', String(this.clampProfileLevel(form.ability_STRATEGIC)));

    this.toArrayFromTextarea(form.top_schools_text).forEach((school, index) => {
      formData.append(`top_schools[${index}]`, school);
    });
  }

  private extractApiError(err: any, fallback: string): string {
    const errors = err?.error?.errors || {};
    return (
      errors?.name?.[0] ||
      errors?.code?.[0] ||
      errors?.image?.[0] ||
      errors?.status?.[0] ||
      errors?.vector_e?.[0] ||
      errors?.vector_s?.[0] ||
      errors?.vector_t?.[0] ||
      errors?.vector_j?.[0] ||
      err?.error?.message ||
      fallback
    );
  }

  axisTone(axis: 'E' | 'S' | 'T' | 'J', value: number): string {
    const other = 100 - value;

    if (axis === 'E') return value >= 50 ? `Thiên E (${value}) / I (${other})` : `Thiên I (${other}) / E (${value})`;
    if (axis === 'S') return value >= 50 ? `Thiên S (${value}) / N (${other})` : `Thiên N (${other}) / S (${value})`;
    if (axis === 'T') return value >= 50 ? `Thiên T (${value}) / F (${other})` : `Thiên F (${other}) / T (${value})`;
    return value >= 50 ? `Thiên J (${value}) / P (${other})` : `Thiên P (${other}) / J (${value})`;
  }

  canSuggestAi(form: MajorForm): boolean {
    return !!(
      form.name.trim() ||
      form.description.trim() ||
      form.career_prospects.trim() ||
      form.skills.trim()
    );
  }

  private applyAiResult(target: 'create' | 'edit', result: AiVectorResult): void {
    const form = target === 'create' ? this.createForm : this.editForm;

    form.vector_e = this.clampVector(result.vector_e);
    form.vector_s = this.clampVector(result.vector_s);
    form.vector_t = this.clampVector(result.vector_t);
    form.vector_j = this.clampVector(result.vector_j);

    if (result.top_schools?.length) {
      form.top_schools_text = result.top_schools.join('\n');
    }

    if (target === 'create') {
      this.createAiResult = result;
    } else {
      this.editAiResult = result;
    }
  }

  suggestVector(target: 'create' | 'edit'): void {
    const form = target === 'create' ? this.createForm : this.editForm;

    if (!this.canSuggestAi(form)) {
      if (target === 'create') {
        this.createAiError = 'Hãy nhập ít nhất tên ngành hoặc mô tả để AI phân tích.';
      } else {
        this.editAiError = 'Hãy nhập ít nhất tên ngành hoặc mô tả để AI phân tích.';
      }
      this.detect();
      return;
    }

    if (target === 'create') {
      this.createAiLoading = true;
      this.createAiError = '';
    } else {
      this.editAiLoading = true;
      this.editAiError = '';
    }
    this.detect();

    this.api.suggestAdminMajorVector({
      name: form.name,
      code: form.code,
      description: form.description,
      career_prospects: form.career_prospects,
      skills: form.skills,
    })
      .pipe(
        finalize(() => {
          if (target === 'create') {
            this.createAiLoading = false;
          } else {
            this.editAiLoading = false;
          }
          this.detect();
        })
      )
      .subscribe({
        next: (res: any) => {
          const result: AiVectorResult = {
            vector_e: this.clampVector(res?.vector_e),
            vector_s: this.clampVector(res?.vector_s),
            vector_t: this.clampVector(res?.vector_t),
            vector_j: this.clampVector(res?.vector_j),
            source: res?.source || 'ai',
            summary: res?.summary || '',
            top_schools: Array.isArray(res?.top_schools) ? res.top_schools : [],
            explanation: {
              E: res?.explanation?.E || '',
              S: res?.explanation?.S || '',
              T: res?.explanation?.T || '',
              J: res?.explanation?.J || '',
            }
          };

          this.applyAiResult(target, result);
        },
        error: (err) => {
          const msg = err?.error?.message || 'Không thể gợi ý vector lúc này.';
          if (target === 'create') {
            this.createAiError = msg;
          } else {
            this.editAiError = msg;
          }
          this.detect();
        }
      });
  }

  openView(item: MajorRow): void {
    this.resetModalState();
    this.selectedItem = { ...item };
    this.showViewModal = true;
    this.detect();
  }

  closeView(): void {
    this.showViewModal = false;
    this.selectedItem = null;
    this.detect();
  }

  openCreate(): void {
    this.resetModalState();
    this.createForm = this.getEmptyForm();
    this.createAiResult = null;
    this.createAiError = '';
    this.resetCreateImage();
    this.showCreateModal = true;
    this.detect();
  }

  closeCreate(): void {
    if (this.creating || this.createAiLoading) return;
    this.showCreateModal = false;
    this.createError = '';
    this.createAiError = '';
    this.resetCreateImage();
    this.detect();
  }

  saveCreate(): void {
    if (this.creating) return;

    if (!this.createForm.name.trim()) {
      this.createError = 'Vui lòng nhập tên ngành.';
      this.detect();
      return;
    }

    this.createForm.code = String(this.createForm.code || '').replace(/\D/g, '');

    if (!this.createForm.code.trim()) {
      this.createError = 'Vui lòng nhập mã ngành.';
      this.detect();
      return;
    }

    const formData = new FormData();
    this.appendFormData(formData, this.createForm);

    if (this.createImageFile) {
      formData.append('image', this.createImageFile);
    }

    this.creating = true;
    this.createError = '';
    this.detect();

    this.api.createAdminMajor(formData)
      .pipe(
        finalize(() => {
          this.creating = false;
          this.detect();
        })
      )
      .subscribe({
        next: () => {
          this.showCreateModal = false;
          this.createForm = this.getEmptyForm();
          this.createAiResult = null;
          this.createError = '';
          this.createAiError = '';
          this.resetCreateImage();
          this.detect();

          this.loadItems(this.currentPage);
        },
        error: (err) => {
          this.createError = this.extractApiError(err, 'Không tạo được ngành nghề.');
          this.detect();
        }
      });
  }

  openEdit(item: MajorRow): void {
    this.resetModalState();
    this.selectedItem = { ...item };

  this.editForm = {
    name: item.name || '',
    code: item.code || '',
    description: item.description || '',
    career_prospects:
      item.career_prospects || '',
    skills: item.skills || '',

    top_schools_text:
      (item.top_schools || []).join('\n'),

    status:
      item.status || 'active',

    suitable_mbti: [
      ...(item.suitable_mbti || [])
    ],

    /* Hồ sơ sở thích */
    interest_creative:
      this.clampProfileLevel(
        item.interest_profile?.creative
      ),

    interest_analytic:
      this.clampProfileLevel(
        item.interest_profile?.analytic
      ),

    interest_social:
      this.clampProfileLevel(
        item.interest_profile?.social
      ),

    interest_business:
      this.clampProfileLevel(
        item.interest_profile?.business
      ),

    /* Hồ sơ năng lực */
    ability_LANGUAGE:
      this.clampProfileLevel(
        item.ability_profile?.LANGUAGE
      ),

    ability_LOGIC:
      this.clampProfileLevel(
        item.ability_profile?.LOGIC
      ),

    ability_CREATIVE:
      this.clampProfileLevel(
        item.ability_profile?.CREATIVE
      ),

    ability_TECH:
      this.clampProfileLevel(
        item.ability_profile?.TECH
      ),

    ability_LEADERSHIP:
      this.clampProfileLevel(
        item.ability_profile?.LEADERSHIP
      ),

    ability_TEAMWORK:
      this.clampProfileLevel(
        item.ability_profile?.TEAMWORK
      ),

    ability_DETAIL:
      this.clampProfileLevel(
        item.ability_profile?.DETAIL
      ),

    ability_ADAPT:
      this.clampProfileLevel(
        item.ability_profile?.ADAPT
      ),

    ability_PRACTICAL:
      this.clampProfileLevel(
        item.ability_profile?.PRACTICAL
      ),

    ability_STRATEGIC:
      this.clampProfileLevel(
        item.ability_profile?.STRATEGIC
      ),

    vector_e:
      this.clampVector(
        item.vector_e ??
        item.vector?.E ??
        50
      ),

    vector_s:
      this.clampVector(
        item.vector_s ??
        item.vector?.S ??
        50
      ),

    vector_t:
      this.clampVector(
        item.vector_t ??
        item.vector?.T ??
        50
      ),

    vector_j:
      this.clampVector(
        item.vector_j ??
        item.vector?.J ??
        50
      )
  };

    this.editAiResult = {
      vector_e: this.editForm.vector_e,
      vector_s: this.editForm.vector_s,
      vector_t: this.editForm.vector_t,
      vector_j: this.editForm.vector_j,
      source: 'saved',
      summary: 'Vector hiện tại của ngành đang lưu trong hệ thống.',
      top_schools: this.toArrayFromTextarea(this.editForm.top_schools_text),
      explanation: {
        E: '',
        S: '',
        T: '',
        J: '',
      }
    };

    this.resetEditImage();
    this.showEditModal = true;
    this.detect();
  }

  closeEdit(): void {
    if (this.updating || this.editAiLoading) return;
    this.showEditModal = false;
    this.selectedItem = null;
    this.editError = '';
    this.editAiError = '';
    this.resetEditImage();
    this.detect();
  }

  saveEdit(): void {
    if (!this.selectedItem || this.updating) return;

    if (!this.editForm.name.trim()) {
      this.editError = 'Vui lòng nhập tên ngành.';
      this.detect();
      return;
    }

    this.editForm.code = String(this.editForm.code || '').replace(/\D/g, '');

    if (!this.editForm.code.trim()) {
      this.editError = 'Vui lòng nhập mã ngành.';
      this.detect();
      return;
    }

    const formData = new FormData();
    this.appendFormData(formData, this.editForm);

    if (this.editImageFile) {
      formData.append('image', this.editImageFile);
    }

    this.updating = true;
    this.editError = '';
    this.detect();

    this.api.updateAdminMajor(this.selectedItem.id, formData)
      .pipe(
        finalize(() => {
          this.updating = false;
          this.detect();
        })
      )
      .subscribe({
        next: () => {
          this.showEditModal = false;
          this.selectedItem = null;
          this.editError = '';
          this.editAiError = '';
          this.resetEditImage();
          this.detect();

          this.loadItems(this.currentPage);
        },
        error: (err) => {
          this.editError = this.extractApiError(err, 'Không cập nhật được ngành nghề.');
          this.detect();
        }
      });
  }

  openDelete(item: MajorRow): void {
    this.resetModalState();
    this.selectedItem = { ...item };
    this.showDeleteModal = true;
    this.detect();
  }

  closeDelete(): void {
    if (this.deleting) return;
    this.showDeleteModal = false;
    this.selectedItem = null;
    this.deleteError = '';
    this.detect();
  }

  confirmDelete(): void {
    if (!this.selectedItem || this.deleting) return;

    const deletingItem = { ...this.selectedItem };

    this.deleting = true;
    this.deleteError = '';
    this.detect();

    this.api.deleteAdminMajor(deletingItem.id)
      .pipe(
        finalize(() => {
          this.deleting = false;
          this.detect();
        })
      )
      .subscribe({
        next: () => {
          this.showDeleteModal = false;
          this.selectedItem = null;
          this.deleteError = '';
          this.detect();

          if (this.items.length === 1 && this.currentPage > 1) {
            this.loadItems(this.currentPage - 1);
          } else {
            this.loadItems(this.currentPage);
          }
        },
        error: (err) => {
          this.deleteError = err?.error?.message || 'Không xóa được ngành nghề.';
          this.detect();
        }
      });
  }

  onSearchChange(): void {
    this.currentPage = 1;
    this.detect();
  }

  onFilterChange(): void {
    this.currentPage = 1;
    this.detect();
  }
}