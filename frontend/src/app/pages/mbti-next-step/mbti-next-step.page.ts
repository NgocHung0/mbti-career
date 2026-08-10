import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { firstValueFrom } from 'rxjs';
import { AuthService } from '../../core/auth.service';

@Component({
  standalone: true,
  selector: 'app-mbti-next-step-page',
  imports: [CommonModule],
  template: `
    <div style="max-width:720px;margin:40px auto;font-family:system-ui;padding:0 16px">
      <h1 style="text-align:center;margin-bottom:6px">Bước tiếp theo</h1>
      <p style="text-align:center;color:#666;margin-top:0">
        Bạn muốn xem kết quả MBTI ngay hay tiếp tục làm bài test sở thích và năng lực?
      </p>

      <div style="display:flex;gap:12px;justify-content:center;flex-wrap:wrap;margin-top:22px">
        <button
          type="button"
          (click)="viewResult()"
          style="padding:12px 16px;border-radius:10px;border:1px solid #ddd;background:#fff;cursor:pointer;min-width:260px"
        >
          View MBTI result now
        </button>

        <button
          type="button"
          (click)="continueTest()"
          [disabled]="checking"
          style="padding:12px 16px;border-radius:10px;border:0;background:#111;color:#fff;cursor:pointer;min-width:260px"
        >
          {{ checking ? 'Checking...' : 'Continue with interest and aptitude test' }}
        </button>
      </div>

      <p *ngIf="err" style="color:#b91c1c;text-align:center;margin-top:14px">
        {{ err }}
      </p>
    </div>
  `,
})
export class MbtiNextStepPage {
  checking = false;
  err = '';

  constructor(
    private router: Router,
    private auth: AuthService,
  ) {}

  viewResult() {
    this.router.navigateByUrl('/result-basic');
  }

  async continueTest() {
    this.err = '';
    if (this.checking) return;
    this.checking = true;

    try {
      // Fast path if user already loaded.
if (this.auth.user()) {
        await this.router.navigateByUrl('/interest');
        return;
      }

      // Otherwise, verify session is authenticated.
      await firstValueFrom(this.auth.me());
      await this.router.navigateByUrl('/interest');
    } catch {
      await this.router.navigateByUrl('/login');
    } finally {
      this.checking = false;
    }
  }
}

