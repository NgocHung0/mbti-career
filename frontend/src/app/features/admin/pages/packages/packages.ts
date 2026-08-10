import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import {
  FormBuilder,
  ReactiveFormsModule,
  Validators,
} from '@angular/forms';
import { finalize } from 'rxjs/operators';
import {
  DragDropModule,
  CdkDragDrop,
  moveItemInArray
} from '@angular/cdk/drag-drop';
import {
  PackageAdminService,
  TestPackage,
  PackagePayload,
} from '../../services/package-admin.service';

type SortPreviewItem = {
  id: number | null;
  name: string;
  isDraft: boolean;
};

@Component({
  selector: 'app-packages',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, DragDropModule],
  templateUrl: './packages.html',
  styleUrls: ['./packages.css']
})
export class Packages implements OnInit {
  private fb = inject(FormBuilder);
  private packageService = inject(PackageAdminService);

  loading = signal(false);
  saving = signal(false);
  deletingId = signal<number | null>(null);

  packages = signal<TestPackage[]>([]);
  keyword = signal('');

  showModal = signal(false);
  editingId = signal<number | null>(null);

  successMessage = signal('');
  errorMessage = signal('');

  sortPreview = signal<SortPreviewItem[]>([]);
  currentSortPosition = signal(1);

  readonly themes = ['blue', 'purple', 'green', 'orange', 'pink'];

  form = this.fb.nonNullable.group({
    name: ['', [Validators.required, Validators.maxLength(255)]],
    slug: [''],
    price: [0, [Validators.required, Validators.min(0)]],
    short_description: [''],
    description: [''],
    badge_text: [''],
    theme: ['green', [Validators.required]],
    sort_order: [1, [Validators.required, Validators.min(1)]],
    is_active: [true],
    is_featured: [false],
    include_interest_test: [false],
    include_ability_test: [false],
  });

  filteredPackages = computed(() => {
    const kw = this.keyword().trim().toLowerCase();

    const items = [...this.packages()].sort((a, b) => {
      if ((a.sort_order ?? 0) !== (b.sort_order ?? 0)) {
        return (a.sort_order ?? 0) - (b.sort_order ?? 0);
      }
      return b.id - a.id;
    });

    if (!kw) return items;

    return items.filter(item => {
      const text = [
        item.name,
        item.slug,
        item.short_description,
        item.description,
        item.badge_text,
        item.theme,
        this.getPackageTypeLabel(item),
        this.getTestSummary(item),
        ...this.getAccessSummary(item),
      ]
        .filter(Boolean)
        .join(' ')
        .toLowerCase();

      return text.includes(kw);
    });
  });

  ngOnInit(): void {
    this.loadPackages();
  }

  loadPackages(): void {
    this.loading.set(true);
    this.clearMessages();

    this.packageService.getPackages()
      .pipe(finalize(() => this.loading.set(false)))
      .subscribe({
        next: (res) => {
          this.packages.set(res?.packages ?? []);
        },
        error: (err) => {
          console.error(err);
          this.errorMessage.set('Không tải được danh sách gói dịch vụ.');
        }
      });
  }

  setKeyword(value: string): void {
    this.keyword.set(value);
  }

  openCreateModal(): void {
    this.clearMessages();
    this.editingId.set(null);

    const nextOrder = Math.max(1, (this.filteredPackages()?.length ?? 0) + 1);

    this.form.reset({
      name: '',
      slug: '',
      price: 0,
      short_description: '',
      description: '',
      badge_text: '',
      theme: 'green',
      sort_order: nextOrder,
      is_active: true,
      is_featured: false,
      include_interest_test: false,
      include_ability_test: false,
    });

    this.buildSortPreviewForCreate();
    this.form.markAsPristine();
    this.form.markAsUntouched();
    this.showModal.set(true);
  }

  openEditModal(item: TestPackage): void {
    this.clearMessages();
    this.editingId.set(item.id);

    this.form.reset({
      name: item.name ?? '',
      slug: item.slug ?? '',
      price: Number(item.price ?? 0),
      short_description: item.short_description ?? '',
      description: item.description ?? '',
      badge_text: item.badge_text ?? '',
      theme: item.theme ?? 'green',
      sort_order: Number(item.sort_order ?? 1),
      is_active: !!item.is_active,
      is_featured: !!item.is_featured,
      include_interest_test: !!item.include_interest_test,
      include_ability_test: !!item.include_ability_test,
    });

    this.buildSortPreviewForEdit(item);
    this.form.markAsPristine();
    this.form.markAsUntouched();
    this.showModal.set(true);
  }

  closeModal(): void {
    if (this.saving()) return;
    this.showModal.set(false);
  }

  submit(): void {
    this.clearMessages();

    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    const raw = this.form.getRawValue();

    if (!raw.include_interest_test && !raw.include_ability_test) {
      this.errorMessage.set('Vui lòng chọn ít nhất 1 quyền lợi bài test cho gói.');
      return;
    }

    this.saving.set(true);

    const payload: PackagePayload = {
      name: raw.name.trim(),
      slug: this.normalizeNullable(raw.slug),
      price: Number(raw.price || 0),
      short_description: this.normalizeNullable(raw.short_description),
      description: this.normalizeNullable(raw.description),
      badge_text: this.normalizeNullable(raw.badge_text),
      theme: raw.theme || 'green',
      sort_order: Number(raw.sort_order || 1),
      is_active: !!raw.is_active,
      is_featured: !!raw.is_featured,
      include_interest_test: !!raw.include_interest_test,
      include_ability_test: !!raw.include_ability_test,
    };

    const editingId = this.editingId();

    const request$ = editingId
      ? this.packageService.updatePackage(editingId, payload)
      : this.packageService.createPackage(payload);

    request$
      .pipe(finalize(() => this.saving.set(false)))
      .subscribe({
        next: () => {
          this.successMessage.set(
            editingId ? 'Cập nhật gói dịch vụ thành công.' : 'Tạo gói dịch vụ thành công.'
          );
          this.showModal.set(false);
          this.loadPackages();
        },
        error: (err) => {
          console.error(err);

          const apiMessage = err?.error?.message;
          const validationErrors = err?.error?.errors;

          if (validationErrors) {
            const firstKey = Object.keys(validationErrors)[0];
            const firstMessage = validationErrors[firstKey]?.[0];
            this.errorMessage.set(firstMessage || 'Dữ liệu không hợp lệ.');
            return;
          }

          this.errorMessage.set(apiMessage || 'Lưu gói dịch vụ thất bại.');
        }
      });
  }

  remove(item: TestPackage): void {
    const ok = window.confirm(`Bạn có chắc muốn xóa gói "${item.name}" không?`);
    if (!ok) return;

    this.deletingId.set(item.id);
    this.clearMessages();

    this.packageService.deletePackage(item.id)
      .pipe(finalize(() => this.deletingId.set(null)))
      .subscribe({
        next: () => {
          this.successMessage.set('Xóa gói thành công.');
          this.loadPackages();
        },
        error: (err) => {
          console.error(err);
          this.errorMessage.set(err?.error?.message || 'Xóa gói thất bại.');
        }
      });
  }

  onSortDrop(event: CdkDragDrop<SortPreviewItem[]>): void {
    const updated = [...this.sortPreview()];
    moveItemInArray(updated, event.previousIndex, event.currentIndex);
    this.sortPreview.set(updated);

    const draftIndex = updated.findIndex(item => item.isDraft);
    const newPosition = draftIndex >= 0 ? draftIndex + 1 : 1;

    this.currentSortPosition.set(newPosition);
    this.form.patchValue({ sort_order: newPosition });
  }

  trackById(_: number, item: TestPackage): number {
    return item.id;
  }

  trackSortPreview(_: number, item: SortPreviewItem): string {
    return `${item.id ?? 'draft'}-${item.name}`;
  }

  getPackageTypeLabel(item: TestPackage): string {
    const hasInterest = !!item.include_interest_test;
    const hasAbility = !!item.include_ability_test;

    if (hasInterest && hasAbility) return 'Tùy chỉnh';
    if (hasInterest) return 'Test tính cách';
    if (hasAbility) return 'Test năng lực';
    return 'Chưa cấu hình';
  }

  getTestSummary(item: TestPackage): string {
    const parts: string[] = [];

    if (item.include_interest_test) parts.push('Tính cách');
    if (item.include_ability_test) parts.push('Năng lực');

    return parts.length ? parts.join(' + ') : 'Chưa chọn';
  }

  getAccessSummary(item: TestPackage): string[] {
    const items: string[] = [];

    if (item.include_interest_test) {
      items.push('Có test tính cách');
    }

    if (item.include_ability_test) {
      items.push('Có test năng lực');
    }

    if (item.is_featured) {
      items.push('Gói nổi bật');
    }

    return items.length ? items : ['Chưa cấu hình quyền lợi'];
  }

  private buildSortPreviewForCreate(): void {
    const base: SortPreviewItem[] = [...this.filteredPackages()]
      .map(item => ({
        id: item.id,
        name: item.name,
        isDraft: false,
      }));

    base.push({
      id: null,
      name: 'Gói đang tạo',
      isDraft: true,
    });

    this.sortPreview.set(base);
    this.currentSortPosition.set(base.length);
    this.form.patchValue({ sort_order: base.length });
  }

  private buildSortPreviewForEdit(item: TestPackage): void {
    const base: SortPreviewItem[] = [...this.filteredPackages()]
      .map(pkg => ({
        id: pkg.id,
        name: pkg.id === item.id ? (item.name || 'Gói đang sửa') : pkg.name,
        isDraft: pkg.id === item.id,
      }));

    const currentIndex = base.findIndex(x => x.isDraft);
    const position = currentIndex >= 0 ? currentIndex + 1 : 1;

    this.sortPreview.set(base);
    this.currentSortPosition.set(position);
    this.form.patchValue({ sort_order: position });
  }

  private normalizeNullable(value: string | null | undefined): string | null {
    const v = (value ?? '').trim();
    return v ? v : null;
  }

  private clearMessages(): void {
    this.successMessage.set('');
    this.errorMessage.set('');
  }
}