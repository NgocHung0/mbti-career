import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { finalize } from 'rxjs/operators';
import { MbtiService } from '../../services/mbti16.service';

type MbtiItem = {
  id: number;
  code: string;
  name: string;
  description: string;
};

@Component({
  selector: 'app-mbti-admin',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './mbti-admin.html',
  styleUrls: ['./mbti-admin.css']
})
export class MbtiAdminComponent implements OnInit {
  items: MbtiItem[] = [];
  filteredItems: MbtiItem[] = [];

  loading = false;
  saving = false;
  deletingId: number | null = null;

  keyword = '';
  errorMessage = '';
  successMessage = '';

  showModal = false;
  isEditMode = false;
  editingId: number | null = null;

  form = {
    code: '',
    name: '',
    description: ''
  };

  readonly defaultMbtiCodes = [
    'INTJ', 'INTP', 'ENTJ', 'ENTP',
    'INFJ', 'INFP', 'ENFJ', 'ENFP',
    'ISTJ', 'ISFJ', 'ESTJ', 'ESFJ',
    'ISTP', 'ISFP', 'ESTP', 'ESFP'
  ];

  constructor(private mbtiService: MbtiService) {}

  ngOnInit(): void {
    console.log('MBTI ADMIN COMPONENT RUNNING');
    this.loadData();
  }

  loadData(): void {
    this.loading = true;
    this.errorMessage = '';
    this.successMessage = '';

    this.mbtiService
      .getList()
      .pipe(finalize(() => (this.loading = false)))
      .subscribe({
        next: (res: any) => {
          const rawItems = Array.isArray(res)
            ? res
            : Array.isArray(res?.data)
            ? res.data
            : Array.isArray(res?.items)
            ? res.items
            : [];

          this.items = rawItems.map((item: any) => ({
            id: Number(item?.id ?? 0),
            code: String(item?.code ?? '').toUpperCase().trim(),
            name: String(item?.name ?? '').trim(),
            description: String(item?.description ?? '').trim(),
          }));

          this.applyFilter();
        },
        error: (error) => {
          console.error('Load MBTI list error:', error);
          this.errorMessage = error?.error?.message || 'Không tải được danh sách nhóm MBTI.';
          this.items = [];
          this.filteredItems = [];
        }
      });
  }

  applyFilter(): void {
    const key = this.keyword.trim().toLowerCase();

    if (!key) {
      this.filteredItems = [...this.items].sort((a, b) => a.code.localeCompare(b.code));
      return;
    }

    this.filteredItems = this.items
      .filter(item =>
        item.code.toLowerCase().includes(key) ||
        item.name.toLowerCase().includes(key) ||
        item.description.toLowerCase().includes(key)
      )
      .sort((a, b) => a.code.localeCompare(b.code));
  }

  onSearchChange(): void {
    this.applyFilter();
  }

  openCreateModal(): void {
    this.isEditMode = false;
    this.editingId = null;
    this.errorMessage = '';
    this.form = {
      code: '',
      name: '',
      description: ''
    };
    this.showModal = true;
  }

  openEditModal(item: MbtiItem): void {
    this.isEditMode = true;
    this.editingId = item.id;
    this.errorMessage = '';
    this.form = {
      code: item.code,
      name: item.name,
      description: item.description
    };
    this.showModal = true;
  }

  closeModal(): void {
    if (this.saving) return;
    this.showModal = false;
  }

  fillQuickCode(code: string): void {
    this.form.code = code;
  }

  validateForm(): string {
    this.form.code = String(this.form.code || '').toUpperCase().trim();
    this.form.name = String(this.form.name || '').trim();
    this.form.description = String(this.form.description || '').trim();

    if (!this.form.code) return 'Vui lòng nhập mã MBTI.';
    if (!/^[A-Z]{4}$/.test(this.form.code)) return 'Mã MBTI phải gồm đúng 4 chữ cái in hoa.';
    if (!this.form.name) return 'Vui lòng nhập tên nhóm.';
    if (!this.form.description) return 'Vui lòng nhập mô tả.';

    return '';
  }

  save(): void {
    const message = this.validateForm();

    if (message) {
      this.errorMessage = message;
      this.successMessage = '';
      return;
    }

    this.saving = true;
    this.errorMessage = '';
    this.successMessage = '';

    const payload = {
      code: this.form.code,
      name: this.form.name,
      description: this.form.description
    };

    const request$ =
      this.isEditMode && this.editingId
        ? this.mbtiService.update(this.editingId, payload)
        : this.mbtiService.create(payload);

    request$
      .pipe(finalize(() => (this.saving = false)))
      .subscribe({
        next: () => {
          this.showModal = false;
          this.successMessage = this.isEditMode
            ? 'Cập nhật nhóm MBTI thành công.'
            : 'Thêm nhóm MBTI thành công.';
          this.loadData();
        },
        error: (error) => {
          console.error('Save MBTI error:', error);
          this.errorMessage =
            error?.error?.message ||
            error?.error?.errors?.code?.[0] ||
            error?.error?.errors?.name?.[0] ||
            error?.error?.errors?.description?.[0] ||
            'Không lưu được nhóm MBTI.';
        }
      });
  }

  deleteItem(item: MbtiItem): void {
    const confirmed = window.confirm(`Bạn có chắc muốn xóa nhóm ${item.code} không?`);
    if (!confirmed) return;

    this.deletingId = item.id;
    this.errorMessage = '';
    this.successMessage = '';

    this.mbtiService
      .delete(item.id)
      .pipe(finalize(() => (this.deletingId = null)))
      .subscribe({
        next: () => {
          this.successMessage = `Đã xóa nhóm ${item.code}.`;
          this.loadData();
        },
        error: (error) => {
          console.error('Delete MBTI error:', error);
          this.errorMessage = error?.error?.message || 'Không xóa được nhóm MBTI.';
        }
      });
  }

  trackById(_: number, item: MbtiItem): number {
    return item.id;
  }

  get emptyStateText(): string {
    return this.keyword.trim()
      ? 'Không tìm thấy nhóm MBTI phù hợp.'
      : 'Chưa có dữ liệu nhóm MBTI.';
  }
}