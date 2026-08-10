import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { finalize } from 'rxjs/operators';
import { NgSelectModule } from '@ng-select/ng-select';
import {
  CourseAdminService,
  CourseItem,
  CoursePayload,
} from '../../services/course-admin.service';
import {
  API_ORIGIN,
  API_URL,
} from '../../../../core/api.config';

@Component({
  selector: 'app-courses',
  standalone: true,
  templateUrl: './courses.html',
  styleUrls: ['./courses.css'],
  imports: [
    CommonModule,
    ReactiveFormsModule,
    NgSelectModule
  ]
})
export class Courses implements OnInit {
  private fb = inject(FormBuilder);
  private courseService = inject(CourseAdminService);
  private router = inject(Router);
  private readonly apiOrigin = API_ORIGIN;
  private apiUrl = `${API_URL}/admin/courses`;
  private brokenImageIds = new Set<number>();

  loading = signal(false);
  saving = signal(false);
  deletingId = signal<number | null>(null);

  courses = signal<CourseItem[]>([]);
  keyword = signal('');

  showModal = signal(false);
  editingId = signal<number | null>(null);

  successMessage = signal('');
  errorMessage = signal('');

  currentPage = signal(1);
  readonly pageSize = 10;

  majorOptions: string[] = [];

  form = this.fb.nonNullable.group({
    name: ['', [Validators.required, Validators.maxLength(255)]],
    short_description: [''],
    description: [''],
    course_major: ['', [Validators.required]],
    thumbnail: [''],
    is_active: [true],
    is_featured: [false],
  });

  filteredCourses = computed(() => {
    const kw = this.keyword().trim().toLowerCase();

    const items = [...this.courses()].sort((a, b) => {
      if ((a.sort_order ?? 0) !== (b.sort_order ?? 0)) {
        return (a.sort_order ?? 0) - (b.sort_order ?? 0);
      }
      return b.id - a.id;
    });

    if (!kw) return items;

    return items.filter(item => {
      const text = [
        item.name,
        item.short_description,
        item.description,
        item.course_major,
      ]
        .filter(Boolean)
        .join(' ')
        .toLowerCase();

      return text.includes(kw);
    });
  });

  totalPages = computed(() => {
    const total = this.filteredCourses().length;
    return Math.max(1, Math.ceil(total / this.pageSize));
  });

  paginatedCourses = computed(() => {
    const page = this.currentPage();
    const start = (page - 1) * this.pageSize;
    const end = start + this.pageSize;
    return this.filteredCourses().slice(start, end);
  });

  paginationNumbers = computed(() => {
    const total = this.totalPages();
    const current = this.currentPage();

    if (total <= 5) {
      return Array.from({ length: total }, (_, i) => i + 1);
    }

    if (current <= 3) {
      return [1, 2, 3, 4, 5];
    }

    if (current >= total - 2) {
      return [total - 4, total - 3, total - 2, total - 1, total];
    }

    return [current - 2, current - 1, current, current + 1, current + 2];
  });

  startItem = computed(() => {
    const total = this.filteredCourses().length;
    if (!total) return 0;
    return (this.currentPage() - 1) * this.pageSize + 1;
  });

  endItem = computed(() => {
    const total = this.filteredCourses().length;
    if (!total) return 0;
    return Math.min(this.currentPage() * this.pageSize, total);
  });

  ngOnInit(): void {
    this.loadMajors();

    const savedPage = Number(
      sessionStorage.getItem('course_admin_page') || '1'
    );

    this.currentPage.set(
      Number.isFinite(savedPage) && savedPage > 0
        ? savedPage
        : 1
    );

    sessionStorage.removeItem('course_admin_page');

    this.loadCourses(true);
  }

  loadMajors(): void {
    this.courseService.getMajors().subscribe({
      next: (res) => {
        this.majorOptions = res ?? [];
      },
      error: (err) => {
        console.error(err);
        this.majorOptions = [];
      }
    });
  }

  loadCourses(keepCurrentPage = false): void {
    const pageBeforeLoad = this.currentPage();

    this.loading.set(true);
    this.clearMessages();
    this.brokenImageIds.clear();

    this.courseService.getCourses()
      .pipe(
        finalize(() => this.loading.set(false))
      )
      .subscribe({
        next: (res) => {
          this.courses.set(res?.courses ?? []);

          const maxPage = this.totalPages();

          if (keepCurrentPage) {
            this.currentPage.set(
              Math.min(
                Math.max(pageBeforeLoad, 1),
                maxPage
              )
            );
          } else {
            this.currentPage.set(1);
          }
        },

        error: (err) => {
          console.error(err);
          this.errorMessage.set(
            'Không tải được danh sách khóa học.'
          );
        }
      });
  }

  setKeyword(value: string): void {
    this.keyword.set(value);
    this.currentPage.set(1);
    this.scrollToTopOfList();
  }

  goToPage(page: number): void {
    const total = this.totalPages();
    if (page < 1 || page > total || page === this.currentPage()) return;

    this.currentPage.set(page);
    this.scrollToTopOfList();
  }

  prevPage(): void {
    this.goToPage(this.currentPage() - 1);
  }

  nextPage(): void {
    this.goToPage(this.currentPage() + 1);
  }

  openCreateModal(): void {
    this.clearMessages();
    this.editingId.set(null);

    this.form.reset({
      name: '',
      short_description: '',
      description: '',
      course_major: '',
      thumbnail: '',
      is_active: true,
      is_featured: false,
    });

    this.form.markAsPristine();
    this.form.markAsUntouched();
    this.showModal.set(true);
  }

  openEditModal(item: CourseItem): void {
    this.clearMessages();
    this.editingId.set(item.id);

    this.form.reset({
      name: item.name ?? '',
      short_description: item.short_description ?? '',
      description: item.description ?? '',
      course_major: item.course_major ?? '',
      thumbnail: item.thumbnail ?? '',
      is_active: !!item.is_active,
      is_featured: !!item.is_featured,
    });

    this.form.markAsPristine();
    this.form.markAsUntouched();
    this.showModal.set(true);
  }

  closeModal(): void {
    if (this.saving()) return;
    this.showModal.set(false);
  }

  manageLessons(item: CourseItem): void {
    if (!item?.id) {
      this.errorMessage.set('Không tìm thấy khóa học để quản lý nội dung.');
      this.successMessage.set('');
      return;
    }

    // Lưu lại trang hiện tại
    sessionStorage.setItem(
      'course_admin_page',
      this.currentPage().toString()
    );

    this.router.navigate(['/admin/courses', item.id, 'lessons']);
  }

  isManageableCourse(item: CourseItem): boolean {
    return !!item?.id;
  }
  submit(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    this.saving.set(true);
    this.clearMessages();

    const raw = this.form.getRawValue();

    const payload: CoursePayload = {
      name: raw.name.trim(),
      short_description: this.normalizeNullable(raw.short_description),
      description: this.normalizeNullable(raw.description),
      course_major: this.normalizeNullable(raw.course_major),
      thumbnail: this.normalizeNullable(raw.thumbnail),
      is_active: !!raw.is_active,
      is_featured: !!raw.is_featured,
    };

    const editingId = this.editingId();

    const request$ = editingId
      ? this.courseService.updateCourse(editingId, payload)
      : this.courseService.createCourse(payload);

    request$
      .pipe(finalize(() => this.saving.set(false)))
      .subscribe({
        next: () => {
          this.successMessage.set(
            editingId ? 'Cập nhật khóa học thành công.' : 'Tạo khóa học thành công.'
          );
          this.showModal.set(false);
          this.loadCourses(true);
        },
        error: (err) => {
          console.error(err);

          const apiMessage = err?.error?.message;
          const internalError = err?.error?.error;
          const validationErrors = err?.error?.errors;

          if (validationErrors) {
            const firstKey = Object.keys(validationErrors)[0];
            const firstMessage = validationErrors[firstKey]?.[0];
            this.errorMessage.set(firstMessage || 'Dữ liệu không hợp lệ.');
            return;
          }

          this.errorMessage.set(internalError || apiMessage || 'Lưu khóa học thất bại.');
        }
      });
  }

  remove(item: CourseItem): void {
    const ok = window.confirm(`Bạn có chắc muốn xóa "${item.name}" không?`);
    if (!ok) return;

    this.deletingId.set(item.id);
    this.clearMessages();

    this.courseService.deleteCourse(item.id)
      .pipe(finalize(() => this.deletingId.set(null)))
      .subscribe({
        next: () => {
          this.successMessage.set('Xóa thành công.');
          this.loadCourses(true);
        },
        error: (err) => {
          console.error(err);
          this.errorMessage.set(err?.error?.message || 'Xóa thất bại.');
        }
      });
  }

  trackById(_: number, item: CourseItem): number {
    return item.id;
  }

  private scrollToTopOfList(): void {
    requestAnimationFrame(() => {
      const tableCard = document.querySelector('.table-card');
      if (tableCard) {
        tableCard.scrollIntoView({ behavior: 'smooth', block: 'start' });
      } else {
        window.scrollTo({ top: 0, behavior: 'smooth' });
      }
    });
  }

  private normalizeNullable(value: string | null | undefined): string | null {
    const v = (value ?? '').trim();
    return v ? v : null;
  }

  private clearMessages(): void {
    this.successMessage.set('');
    this.errorMessage.set('');
  }

  resolveThumbnail(value: string | null | undefined): string {
    const raw = String(value ?? '').trim();
    if (!raw) return '';

    if (
      raw.startsWith('http://') ||
      raw.startsWith('https://') ||
      raw.startsWith('data:') ||
      raw.startsWith('blob:')
    ) {
      return raw;
    }

    if (raw.startsWith('/storage/')) {
      return `${this.apiOrigin}${raw}`;
    }

    if (raw.startsWith('storage/')) {
      return `${this.apiOrigin}/${raw}`;
    }

    if (raw.startsWith('/uploads/')) {
      return `${this.apiOrigin}${raw}`;
    }

    if (raw.startsWith('uploads/')) {
      return `${this.apiOrigin}/${raw}`;
    }

    return `${this.apiOrigin}/storage/${raw.replace(/^\/+/, '')}`;
  }

  markBrokenImage(id: number): void {
    this.brokenImageIds.add(id);
  }

  isBrokenImage(id: number): boolean {
    return this.brokenImageIds.has(id);
  }
}