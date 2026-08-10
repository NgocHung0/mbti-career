import { Component, OnInit, ChangeDetectorRef, NgZone } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { finalize, timeout } from 'rxjs/operators';
import { ResultApiService } from '../../../../services/result-api.service';

type AdminUserRow = {
  id: number;
  name: string;
  email: string;
  role: string;
  status: 'active' | 'inactive';
  joined_at: string;
};

@Component({
  selector: 'app-admin-users',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './admin-users.html',
  styleUrl: './admin-users.css'
})
export class AdminUsers implements OnInit {
  q = '';

  private searchTimer:
    ReturnType<typeof setTimeout> | null = null;
  roleFilter = 'all';
  statusFilter = 'all';

  loading = false;
  error = '';

  users: AdminUserRow[] = [];

  currentPage = 1;
  perPage = 10;
  lastPage = 1;
  total = 0;
  activeTotal = 0;
  showViewModal = false;
  showEditModal = false;
  showCreateModal = false;
  showDeleteModal = false;

  selectedUser: AdminUserRow | null = null;

  savingEdit = false;
  editError = '';

  creatingUser = false;
  createError = '';

  deletingUser = false;
  deleteError = '';

  editForm = {
    name: '',
    email: '',
    status: 'active' as 'active' | 'inactive'
  };

  createForm = {
    name: '',
    email: '',
    password: '',
    status: 'active' as 'active' | 'inactive'
  };

  constructor(
    private api: ResultApiService,
    private cdr: ChangeDetectorRef,
    private zone: NgZone
  ) {}

  ngOnInit(): void {
    if (typeof window === 'undefined') return;
    this.loadUsers(1);
  }

  loadUsers(page: number = 1) {
    if (typeof window === 'undefined') return;

    this.loading = true;
    this.error = '';
    this.cdr.detectChanges();

    this.api.getAdminUsers(
      page,
      this.perPage,
      this.q,
      this.statusFilter,
      this.roleFilter
    )
      .pipe(
        timeout(8000),
        finalize(() => {
          this.zone.run(() => {
            this.loading = false;
            this.cdr.detectChanges();
          });
        })
      )
      .subscribe({
        next: (res) => {
          this.zone.run(() => {
            this.users = Array.isArray(res?.data) ? res.data : [];
            this.currentPage = res?.current_page ?? 1;
            this.lastPage = res?.last_page ?? 1;
            this.total = Number(
              res?.total_users ??
              res?.filtered_total ??
              0
            );
            this.activeTotal = res?.active_total ?? 0;
            this.error = '';
            this.cdr.detectChanges();
          });
        },
        error: (err) => {
          console.error('ADMIN USERS ERROR:', err);
          this.zone.run(() => {
            this.users = [];
            this.error = 'Không tải được danh sách người dùng.';
            this.cdr.detectChanges();
          });
        }
      });
  }

  onSearchChange(): void {
    this.currentPage = 1;

    if (this.searchTimer) {
      clearTimeout(this.searchTimer);
    }

    /*
    * Chờ người dùng ngừng nhập 300ms
    * rồi mới gọi API.
    */
    this.searchTimer = setTimeout(() => {
      this.searchTimer = null;
      this.loadUsers(1);
    }, 300);
  }

  onFilterChange(): void {
    this.currentPage = 1;
    this.loadUsers(1);
  }

  get filteredUsers(): AdminUserRow[] {
    return this.users;
  }

  totalUsers() {
        return this.total;
  }

  activeUsers() {
        return this.activeTotal;
  }

  formatDate(date: string) {
    if (!date) return '';
    return new Date(date).toLocaleDateString('vi-VN');
  }

  goToPage(page: number) {
    if (page < 1 || page > this.lastPage || page === this.currentPage) return;
    this.loadUsers(page);
  }

  pageNumbers(): number[] {
    return Array.from({ length: this.lastPage }, (_, i) => i + 1);
  }

  rowNumber(index: number): number {
    return (this.currentPage - 1) * this.perPage + index + 1;
  }

  resetFilters(): void {
    if (this.searchTimer) {
      clearTimeout(this.searchTimer);
      this.searchTimer = null;
    }

    this.q = '';
    this.roleFilter = 'all';
    this.statusFilter = 'all';
    this.currentPage = 1;

    this.loadUsers(1);
  }

  openView(user: AdminUserRow) {
    this.selectedUser = { ...user };
    this.showViewModal = true;
  }

  closeView() {
    this.showViewModal = false;
    this.selectedUser = null;
  }

  openEdit(user: AdminUserRow) {
    this.selectedUser = user;
    this.editError = '';
    this.editForm = {
      name: user.name,
      email: user.email,
      status: user.status
    };
    this.showEditModal = true;
  }

  closeEdit() {
    if (this.savingEdit) return;
    this.showEditModal = false;
    this.selectedUser = null;
    this.editError = '';
  }

  saveEdit() {
    if (!this.selectedUser || this.savingEdit) return;

    const name = this.editForm.name.trim();
    const email = this.editForm.email.trim();

    if (!name) {
      this.editError = 'Vui lòng nhập họ tên.';
      return;
    }

    if (!email) {
      this.editError = 'Vui lòng nhập email.';
      return;
    }

    this.savingEdit = true;
    this.editError = '';

    this.api.updateAdminUser(this.selectedUser.id, {
      name,
      email,
      role: 'user',
      status: this.editForm.status
    }).subscribe({
      next: () => {
        this.savingEdit = false;
        this.showEditModal = false;
        this.selectedUser = null;
        this.editError = '';
        this.loadUsers(this.currentPage);
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.savingEdit = false;
        const errors = err?.error?.errors || {};
        this.editError =
          errors?.name?.[0] ||
          errors?.email?.[0] ||
          errors?.role?.[0] ||
          err?.error?.message ||
          'Không cập nhật được người dùng.';
        this.cdr.detectChanges();
      }
    });
  }

  openCreate() {
    this.createError = '';
    this.createForm = {
      name: '',
      email: '',
      password: '',
      status: 'active'
    };
    this.showCreateModal = true;
  }

  closeCreate() {
    if (this.creatingUser) return;
    this.showCreateModal = false;
    this.createError = '';
  }

  saveCreate() {
    if (this.creatingUser) return;

    const name = this.createForm.name.trim();
    const email = this.createForm.email.trim();
    const password = this.createForm.password.trim();

    if (!name) {
      this.createError = 'Vui lòng nhập họ tên.';
      return;
    }

    if (!email) {
      this.createError = 'Vui lòng nhập email.';
      return;
    }

    if (!password) {
      this.createError = 'Vui lòng nhập mật khẩu.';
      return;
    }

    if (password.length < 6) {
      this.createError = 'Mật khẩu phải có ít nhất 6 ký tự.';
      return;
    }

    this.creatingUser = true;
    this.createError = '';

    this.api.createAdminUser({
      name,
      email,
      password,
      role: 'user',
      status: this.createForm.status
    }).subscribe({
      next: () => {
        this.creatingUser = false;
        this.showCreateModal = false;
        this.createError = '';
        this.createForm = {
          name: '',
          email: '',
          password: '',
          status: 'active'
        };
        this.loadUsers(this.currentPage);
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.creatingUser = false;
        const errors = err?.error?.errors || {};
        this.createError =
          errors?.name?.[0] ||
          errors?.email?.[0] ||
          errors?.password?.[0] ||
          err?.error?.message ||
          'Không tạo được người dùng.';
        this.cdr.detectChanges();
      }
    });
  }

  openDelete(user: AdminUserRow) {
    this.selectedUser = user;
    this.deleteError = '';
    this.showDeleteModal = true;
  }

  closeDelete() {
    if (this.deletingUser) return;
    this.showDeleteModal = false;
    this.selectedUser = null;
    this.deleteError = '';
  }

  confirmDelete() {
    if (!this.selectedUser || this.deletingUser) return;

    this.deletingUser = true;
    this.deleteError = '';

    this.api.deleteAdminUser(this.selectedUser.id).subscribe({
      next: () => {
        this.deletingUser = false;
        this.showDeleteModal = false;
        this.selectedUser = null;
        this.deleteError = '';

        if (this.users.length === 1 && this.currentPage > 1) {
          this.loadUsers(this.currentPage - 1);
        } else {
          this.loadUsers(this.currentPage);
        }

        this.cdr.detectChanges();
      },
      error: (err) => {
        this.deletingUser = false;
        this.deleteError =
          err?.error?.message ||
          'Không xóa được người dùng.';
        this.cdr.detectChanges();
      }
    });
  }
}