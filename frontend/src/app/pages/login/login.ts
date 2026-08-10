import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule, Router } from '@angular/router';
import { HttpErrorResponse } from '@angular/common/http';
import { finalize } from 'rxjs/operators';
import { ResultApiService } from '../../services/result-api.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './login.html',
  styleUrl: './login.css'
})
export class Login {
  mode: 'login' | 'register' = 'login';

  email = '';
  password = '';
  showPassword = false;
  loading = false;
  err = '';

  registerName = '';
  registerEmail = '';
  registerPassword = '';
  registerPasswordConfirmation = '';
  showRegisterPassword = false;
  registerLoading = false;
  registerErr = '';
  registerSuccess = '';

  constructor(
    private api: ResultApiService,
    private router: Router
  ) {}

  switchMode(mode: 'login' | 'register') {
    this.mode = mode;
    this.err = '';
    this.registerErr = '';
    this.registerSuccess = '';
  }

  togglePassword() {
    this.showPassword = !this.showPassword;
  }

  toggleRegisterPassword() {
    this.showRegisterPassword = !this.showRegisterPassword;
  }

  private getLoginErrorMessage(error: HttpErrorResponse): string {
    const backendMessage = error?.error?.message || '';
    const emailError = error?.error?.errors?.email?.[0] || '';
    const text = `${backendMessage} ${emailError}`.toLowerCase();

    if (
      error?.status === 403 ||
      text.includes('bị khóa') ||
      text.includes('tài khoản hiện tại đang bị khóa') ||
      text.includes('inactive')
    ) {
      return 'Tài khoản hiện tại đang bị khóa.';
    }

    if (error?.status === 401) {
      return emailError || backendMessage || 'Email hoặc mật khẩu không đúng.';
    }

    if (error?.status === 422) {
      return emailError || backendMessage || 'Email hoặc mật khẩu không đúng.';
    }

    return emailError || backendMessage || 'Đăng nhập thất bại.';
  }

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
      .pipe(
        finalize(() => {
          this.loading = false;
        })
      )
      .subscribe({
        next: () => {
          if (typeof window !== 'undefined') {
            const returnAfterLoginUpgrade = localStorage.getItem('return_after_login_upgrade');

            if (returnAfterLoginUpgrade === '1') {
              this.router.navigateByUrl('/mbti-test');
              return;
            }
          }

          this.router.navigateByUrl('/');
        },
        error: (error: HttpErrorResponse) => {
          this.err = this.getLoginErrorMessage(error);
        }
      });
  }

  onRegister() {
    if (this.registerLoading) return;

    this.registerErr = '';
    this.registerSuccess = '';

    const name = this.registerName.trim();
    const email = this.registerEmail.trim();

    if (!name) {
      this.registerErr = 'Vui lòng nhập họ tên.';
      return;
    }

    if (!email) {
      this.registerErr = 'Vui lòng nhập email.';
      return;
    }

    if (!this.registerPassword.trim()) {
      this.registerErr = 'Vui lòng nhập mật khẩu.';
      return;
    }

    if (this.registerPassword.length < 6) {
      this.registerErr = 'Mật khẩu phải có ít nhất 6 ký tự.';
      return;
    }

    if (this.registerPassword !== this.registerPasswordConfirmation) {
      this.registerErr = 'Mật khẩu xác nhận không khớp.';
      return;
    }

    this.registerLoading = true;

    this.api.register({
      name,
      email,
      password: this.registerPassword,
      password_confirmation: this.registerPasswordConfirmation
    })
    .pipe(
      finalize(() => {
        this.registerLoading = false;
      })
    )
    .subscribe({
      next: () => {
        this.registerSuccess = 'Đăng ký thành công.';
        this.registerName = '';
        this.registerEmail = '';
        this.registerPassword = '';
        this.registerPasswordConfirmation = '';

        if (typeof window !== 'undefined') {
          const returnAfterLoginUpgrade = localStorage.getItem('return_after_login_upgrade');

          if (returnAfterLoginUpgrade === '1') {
            this.router.navigateByUrl('/mbti-test');
            return;
          }
        }

        this.router.navigateByUrl('/');
      },
      error: (error: HttpErrorResponse) => {
        if (error?.status === 422) {
          const errors = error?.error?.errors || {};

          this.registerErr =
            errors?.name?.[0] ||
            errors?.email?.[0] ||
            errors?.password?.[0] ||
            error?.error?.message ||
            'Dữ liệu đăng ký không hợp lệ.';
          return;
        }

        this.registerErr = error?.error?.message || 'Đăng ký thất bại.';
      }
    });
  }
  onEmailInput() {
  this.err = '';
  }

  onPasswordInput() {
    this.err = '';
  }
}