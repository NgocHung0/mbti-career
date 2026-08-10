import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { HttpErrorResponse } from '@angular/common/http';
import { finalize } from 'rxjs/operators';
import { ResultApiService } from '../../../../services/result-api.service';

@Component({
  selector: 'app-admin-login',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './admin-login.html',
  styleUrl: './admin-login.css'
})
export class AdminLogin {
  email = '';
  password = '';
  loading = false;
  err = '';

  constructor(
    private api: ResultApiService,
    private router: Router
  ) {}

  onSubmit() {
    if (this.loading) return;

    this.err = '';

    if (!this.email.trim()) {
      this.err = 'Vui lòng nhập email.';
      return;
    }

    if (!this.password.trim()) {
      this.err = 'Vui lòng nhập mật khẩu.';
      return;
    }

    this.loading = true;

    this.api.login(this.email.trim(), this.password)
      .pipe(finalize(() => (this.loading = false)))
      .subscribe({
        next: (res: any) => {
          localStorage.setItem('token', res.token);
          localStorage.setItem('role', res.user?.role || '');

          if (res.user?.role !== 'admin') {
            localStorage.removeItem('token');
            localStorage.removeItem('role');
            this.err = 'Bạn không có quyền truy cập trang quản trị.';
            return;
          }

          this.router.navigateByUrl('/admin');
        },
        error: (error: HttpErrorResponse) => {
          this.err =
            error?.error?.message ||
            error?.error?.errors?.email?.[0] ||
            'Đăng nhập thất bại.';
        }
      });
  }
}