import { Component, OnInit, ChangeDetectorRef, NgZone } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { finalize, timeout } from 'rxjs/operators';
import { MbtiService } from '../../services/mbti.service';

type PackageType = 'free' | 'plus' | 'premium';

type MbtiQuestionRow = {
  id: number;
  question: string;
  option_a: string;
  option_b: string;
  axis: string;
  package_type?: PackageType | string;
  created_at?: string;
};

type StatsState = {
  total: number;
  free: number;
  plus: number;
  premium: number;
};

@Component({
  selector: 'app-admin-mbti',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './admin-mbti.html',
  styleUrls: ['./admin-mbti.css']
})
export class AdminMbti implements OnInit {
  q = '';
  axisFilter = 'all';
  packageFilter: 'all' | PackageType = 'all';

  loading = false;
  error = '';

  items: MbtiQuestionRow[] = [];
  allItems: MbtiQuestionRow[] = [];

  stats: StatsState = {
    total: 0,
    free: 0,
    plus: 0,
    premium: 0
  };

  readonly axisOptionsByPackage: Record<PackageType, string[]> = {
    free: [
      'Hướng ngoại / Hướng nội',
      'Giác quan / Trực giác',
      'Lý trí / Cảm xúc',
      'Nguyên tắc / Linh hoạt'
    ],

    plus: [
      'Sáng tạo / Phân tích - Công nghệ',
      'Con người - Giao tiếp / Kinh doanh - Tổ chức',
      'Sáng tạo / Con người - Giao tiếp',
      'Phân tích - Công nghệ / Kinh doanh - Tổ chức',
      'Sáng tạo / Kinh doanh - Tổ chức',
      'Phân tích - Công nghệ / Con người - Giao tiếp'
    ],

    premium: [
      'Ngôn ngữ / Chiến lược',
      'Tư duy logic / Thực hành',
      'Sáng tạo / Thích nghi',
      'Công nghệ / Chi tiết - Cẩn thận',
      'Lãnh đạo / Làm việc nhóm',

      'Ngôn ngữ / Thực hành',
      'Chiến lược / Thích nghi',
      'Tư duy logic / Chi tiết - Cẩn thận',
      'Sáng tạo / Làm việc nhóm',
      'Công nghệ / Lãnh đạo',

      'Ngôn ngữ / Thích nghi',
      'Thực hành / Chi tiết - Cẩn thận',
      'Chiến lược / Làm việc nhóm',
      'Tư duy logic / Lãnh đạo',
      'Sáng tạo / Công nghệ',

      'Ngôn ngữ / Chi tiết - Cẩn thận',
      'Thích nghi / Làm việc nhóm',
      'Thực hành / Lãnh đạo',
      'Chiến lược / Công nghệ',
      'Tư duy logic / Sáng tạo',

      'Ngôn ngữ / Làm việc nhóm',
      'Chi tiết - Cẩn thận / Lãnh đạo',
      'Thích nghi / Công nghệ',
      'Thực hành / Sáng tạo',
      'Chiến lược / Tư duy logic',

      'Ngôn ngữ / Lãnh đạo',
      'Làm việc nhóm / Công nghệ',
      'Chi tiết - Cẩn thận / Sáng tạo',
      'Thích nghi / Tư duy logic',
      'Thực hành / Chiến lược'
    ]
  };

  currentPage = 1;
  perPage = 10;
  lastPage = 1;
  total = 0;

  showCreateModal = false;
  showEditModal = false;
  showDeleteModal = false;

  creating = false;
  updating = false;
  deleting = false;

  createError = '';
  editError = '';
  deleteError = '';

  selectedItem: MbtiQuestionRow | null = null;

  createForm = {
    question: '',
    option_a: '',
    option_b: '',
    axis: '',
    package_type: 'free' as PackageType
  };

  editForm = {
    question: '',
    option_a: '',
    option_b: '',
    axis: '',
    package_type: 'free' as PackageType
  };

  constructor(
    private api: MbtiService,
    private cdr: ChangeDetectorRef,
    private zone: NgZone
  ) {}

  ngOnInit(): void {
    if (typeof window === 'undefined') return;
    this.loadItems(1);
  }

  private normalizeAxis(axis: string | undefined | null): string {
    return String(axis || '')
      .trim()
      .replace(/\s+/g, ' ');
  }

  private normalizePackageType(value: string | undefined | null): PackageType {
    const raw = String(value || '').trim().toLowerCase();

    if (raw === 'plus') return 'plus';
    if (raw === 'premium') return 'premium';
    return 'free';
  }

  private normalizeStats(raw: any): StatsState {
    return {
      total: Number(raw?.total ?? 0),
      free: Number(raw?.free ?? raw?.packages?.free ?? raw?.package_counts?.free ?? 0),
      plus: Number(raw?.plus ?? raw?.packages?.plus ?? raw?.package_counts?.plus ?? 0),
      premium: Number(raw?.premium ?? raw?.packages?.premium ?? raw?.package_counts?.premium ?? 0)
    };
  }

  get axisFilterOptions(): string[] {
    if (this.packageFilter === 'free') return this.axisOptionsByPackage.free;
    if (this.packageFilter === 'plus') return this.axisOptionsByPackage.plus;
    if (this.packageFilter === 'premium') return this.axisOptionsByPackage.premium;

    return [
      ...this.axisOptionsByPackage.free,
      ...this.axisOptionsByPackage.plus,
      ...this.axisOptionsByPackage.premium
    ];
  }

  loadItems(page: number = 1): void {
    if (typeof window === 'undefined') return;

    this.loading = true;
    this.error = '';
    this.cdr.detectChanges();

    this.api
      .getAdminMbtiQuestions(page, this.perPage, this.axisFilter, this.packageFilter)
      .pipe(
        timeout(15000),
        finalize(() => {
          this.zone.run(() => {
            this.loading = false;
            this.cdr.detectChanges();
          });
        })
      )
      .subscribe({
        next: (res: any) => {
          this.zone.run(() => {
            const raw = Array.isArray(res?.data) ? res.data : [];

            const mappedItems = raw.map((item: any) => ({
              id: Number(item?.id ?? 0),
              question: String(item?.question ?? item?.content ?? ''),
              option_a: String(item?.option_a ?? item?.label_a ?? ''),
              option_b: String(item?.option_b ?? item?.label_b ?? ''),
              axis: this.normalizeAxis(item?.axis),
              package_type: this.normalizePackageType(item?.package_type),
              created_at: item?.created_at ?? ''
            }));

            this.items = mappedItems;
            this.allItems = mappedItems;

            this.stats = this.normalizeStats(res?.stats);
            this.currentPage = Number(res?.current_page ?? 1);
            this.lastPage = Number(res?.last_page ?? 1);
            this.perPage = Number(res?.per_page ?? this.perPage);
            this.total = Number(res?.total ?? 0);
            this.error = '';

            this.cdr.detectChanges();
          });
        },
        error: (err) => {
          console.error('ADMIN QUESTION ERROR:', err);

          this.zone.run(() => {
            this.items = [];
            this.allItems = [];
            this.stats = {
              total: 0,
              free: 0,
              plus: 0,
              premium: 0
            };
            this.error = 'Không tải được danh sách câu hỏi.';
            this.cdr.detectChanges();
          });
        }
      });
  }

  onSearchChange(): void {
    this.currentPage = 1;
    this.cdr.detectChanges();
  }

  onAxisChange(): void {
    this.currentPage = 1;
    this.loadItems(1);
  }

  onPackageChange(): void {
    this.currentPage = 1;
    this.axisFilter = 'all';
    this.loadItems(1);
  }

  get filteredItems(): MbtiQuestionRow[] {
    const keyword = this.q.trim().toLowerCase();

    return this.allItems.filter((item) => {
      const axis = this.normalizeAxis(item.axis);
      const packageType = this.normalizePackageType(item.package_type);

      const matchKeyword =
        !keyword ||
        item.question.toLowerCase().includes(keyword) ||
        item.option_a.toLowerCase().includes(keyword) ||
        item.option_b.toLowerCase().includes(keyword) ||
        axis.toLowerCase().includes(keyword) ||
        packageType.toLowerCase().includes(keyword);

      const matchAxis =
        this.axisFilter === 'all' ||
        axis === this.axisFilter;

      const matchPackage =
        this.packageFilter === 'all' ||
        packageType === this.packageFilter;

      return matchKeyword && matchAxis && matchPackage;
    });
  }

  totalQuestions(): number {
    const totalFromApi = Number(this.stats.total ?? 0);

    if (totalFromApi > 0) {
      return totalFromApi;
    }

    return (
      this.packageCount('free') +
      this.packageCount('plus') +
      this.packageCount('premium')
    );
  }

  packageCount(type: PackageType): number {
    const fromStats = Number(this.stats[type] ?? 0);

    if (fromStats > 0) {
      return fromStats;
    }

    if (type === 'free') return 36;
    if (type === 'plus') return 20;
    if (type === 'premium') return 30;

    return 0;
  }

  rowNumber(index: number): number {
    if (this.q.trim()) return index + 1;
    return (this.currentPage - 1) * this.perPage + index + 1;
  }

  goToPage(page: number): void {
    if (this.q.trim()) return;
    if (page < 1 || page > this.lastPage || page === this.currentPage) return;
    this.loadItems(page);
  }

  pageNumbers(): number[] {
    const totalPages = this.lastPage;
    const current = this.currentPage;

    if (totalPages <= 7) {
      return Array.from({ length: totalPages }, (_, i) => i + 1);
    }

    const pages = new Set<number>();
    pages.add(1);
    pages.add(totalPages);

    for (let i = current - 1; i <= current + 1; i++) {
      if (i > 1 && i < totalPages) pages.add(i);
    }

    return Array.from(pages).sort((a, b) => a - b);
  }

  resetFilters(): void {
    this.q = '';
    this.axisFilter = 'all';
    this.packageFilter = 'all';
    this.currentPage = 1;
    this.loadItems(1);
  }

  openCreate(): void {
    this.createError = '';
    this.createForm = {
      question: '',
      option_a: '',
      option_b: '',
      axis: '',
      package_type: 'free'
    };
    this.showCreateModal = true;
  }

  closeCreate(): void {
    if (this.creating) return;
    this.showCreateModal = false;
    this.createError = '';
  }

  saveCreate(): void {
    if (this.creating) return;

    const question = this.createForm.question.trim();
    const optionA = this.createForm.option_a.trim();
    const optionB = this.createForm.option_b.trim();
    const axis = this.normalizeAxis(this.createForm.axis);

    if (!question) {
      this.createError = 'Vui lòng nhập nội dung câu hỏi.';
      return;
    }

    if (!optionA) {
      this.createError = 'Vui lòng nhập đáp án A.';
      return;
    }

    if (!optionB) {
      this.createError = 'Vui lòng nhập đáp án B.';
      return;
    }

    if (!axis) {
      this.createError = 'Vui lòng chọn nhóm đánh giá.';
      return;
    }

    this.creating = true;
    this.createError = '';

    this.api.createAdminMbtiQuestion({
      question,
      option_a: optionA,
      option_b: optionB,
      axis,
      package_type: this.createForm.package_type
    }).subscribe({
      next: () => {
        this.creating = false;
        this.showCreateModal = false;
        this.loadItems(1);
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.creating = false;
        const errors = err?.error?.errors || {};
        this.createError =
          errors?.question?.[0] ||
          errors?.option_a?.[0] ||
          errors?.option_b?.[0] ||
          errors?.axis?.[0] ||
          errors?.package_type?.[0] ||
          err?.error?.message ||
          'Không tạo được câu hỏi.';
        this.cdr.detectChanges();
      }
    });
  }

  openEdit(item: MbtiQuestionRow): void {
    this.selectedItem = item;
    this.editError = '';
    this.editForm = {
      question: item.question,
      option_a: item.option_a,
      option_b: item.option_b,
      axis: this.normalizeAxis(item.axis),
      package_type: this.normalizePackageType(item.package_type)
    };
    this.showEditModal = true;
  }

  closeEdit(): void {
    if (this.updating) return;
    this.showEditModal = false;
    this.selectedItem = null;
    this.editError = '';
  }

  saveEdit(): void {
    if (!this.selectedItem || this.updating) return;

    const question = this.editForm.question.trim();
    const optionA = this.editForm.option_a.trim();
    const optionB = this.editForm.option_b.trim();
    const axis = this.normalizeAxis(this.editForm.axis);

    if (!question) {
      this.editError = 'Vui lòng nhập nội dung câu hỏi.';
      return;
    }

    if (!optionA) {
      this.editError = 'Vui lòng nhập đáp án A.';
      return;
    }

    if (!optionB) {
      this.editError = 'Vui lòng nhập đáp án B.';
      return;
    }

    if (!axis) {
      this.editError = 'Vui lòng chọn nhóm đánh giá.';
      return;
    }

    this.updating = true;
    this.editError = '';

    this.api.updateAdminMbtiQuestion(this.selectedItem.id, {
      question,
      option_a: optionA,
      option_b: optionB,
      axis,
      package_type: this.editForm.package_type
    }).subscribe({
      next: () => {
        this.updating = false;
        this.showEditModal = false;
        this.selectedItem = null;
        this.loadItems(this.currentPage);
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.updating = false;
        const errors = err?.error?.errors || {};
        this.editError =
          errors?.question?.[0] ||
          errors?.option_a?.[0] ||
          errors?.option_b?.[0] ||
          errors?.axis?.[0] ||
          errors?.package_type?.[0] ||
          err?.error?.message ||
          'Không cập nhật được câu hỏi.';
        this.cdr.detectChanges();
      }
    });
  }

  openDelete(item: MbtiQuestionRow): void {
    this.selectedItem = item;
    this.deleteError = '';
    this.showDeleteModal = true;
  }

  closeDelete(): void {
    if (this.deleting) return;
    this.showDeleteModal = false;
    this.selectedItem = null;
    this.deleteError = '';
  }

  confirmDelete(): void {
    if (!this.selectedItem || this.deleting) return;

    this.deleting = true;
    this.deleteError = '';

    this.api.deleteAdminMbtiQuestion(this.selectedItem.id).subscribe({
      next: () => {
        this.deleting = false;
        this.showDeleteModal = false;
        this.selectedItem = null;

        if (this.items.length === 1 && this.currentPage > 1) {
          this.loadItems(this.currentPage - 1);
        } else {
          this.loadItems(this.currentPage);
        }

        this.cdr.detectChanges();
      },
      error: (err) => {
        this.deleting = false;
        this.deleteError =
          err?.error?.message ||
          'Không xóa được câu hỏi.';
        this.cdr.detectChanges();
      }
    });
  }

  packageLabel(value: string | null | undefined): string {
    const type = this.normalizePackageType(value);
    if (type === 'plus') return 'Plus';
    if (type === 'premium') return 'Premium';
    return 'Free';
  }
}