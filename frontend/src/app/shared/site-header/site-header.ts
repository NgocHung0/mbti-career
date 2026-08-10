import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterModule } from '@angular/router';
import { ResultApiService } from '../../services/result-api.service';
import { STORAGE_URL } from '../../core/api.config';

@Component({
  selector: 'app-site-header',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './site-header.html',
  styleUrl: './site-header.css'
})
export class SiteHeader {
  showUserMenu = false;
  private closeTimer: any = null;

  constructor(
    public api: ResultApiService,
    private router: Router
  ) {}

  isLoggedIn(): boolean {
    return this.api.isLoggedIn();
  }

  user() {
    return this.api.user();
  }

  userInitial(): string {
    const name = this.api.user()?.name?.trim();
    return name ? name.charAt(0).toUpperCase() : 'U';
  }

  avatarUrl(): string {
    const user: any = this.api.user();

    if (!user) return '';

    if (user.avatar_url) {
      return user.avatar_url;
    }

    const avatar = String(user.avatar || '').trim();

    if (!avatar) return '';

    if (
      avatar.startsWith('http://') ||
      avatar.startsWith('https://')
    ) {
      return avatar;
    }

    return `${STORAGE_URL}/${avatar}`;
  }

  hasPremiumCourseAccess(): boolean {
    const user = this.api.user() as any;

    const role = String(user?.role || '')
      .trim()
      .toLowerCase();

    return role === 'premium';
  }

  toggleUserMenu(): void {
    this.showUserMenu = !this.showUserMenu;
  }

  openUserMenu(): void {
    if (this.closeTimer) {
      clearTimeout(this.closeTimer);
      this.closeTimer = null;
    }

    this.showUserMenu = true;
  }

  closeUserMenu(): void {
    if (this.closeTimer) {
      clearTimeout(this.closeTimer);
      this.closeTimer = null;
    }

    this.showUserMenu = false;
  }

  logout(): void {
    this.api.logout().subscribe({
      next: () => {
        this.showUserMenu = false;
        this.router.navigateByUrl('/');
      },
      error: () => {
        if (typeof window !== 'undefined') {
          localStorage.removeItem('auth_token');
          localStorage.removeItem('auth_user');
        }

        this.api.user.set(null);
        this.showUserMenu = false;
        this.router.navigateByUrl('/');
      }
    });
  }

  scheduleCloseUserMenu(): void {
    if (this.closeTimer) {
      clearTimeout(this.closeTimer);
    }

    this.closeTimer = setTimeout(() => {
      this.showUserMenu = false;
    }, 180);
  }
}