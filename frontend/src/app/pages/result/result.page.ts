import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';

@Component({
  standalone: true,
  selector: 'app-result-page',
  imports: [CommonModule],
  template: `
    <div style="max-width:900px;margin:30px auto;font-family:system-ui">
      <h1 style="text-align:center">Kết quả</h1>

      <p *ngIf="loading">Đang tải kết quả...</p>
      <p *ngIf="err" style="color:red">{{err}}</p>

      <div *ngIf="result">
        <h2>MBTI: {{result.mbti_type}}</h2>
        <pre style="background:#f6f6f6;padding:12px;border-radius:10px;overflow:auto">
{{ result | json }}
        </pre>

        <button (click)="restart()"
          style="display:block;margin:20px auto;padding:10px 16px;background:#111;color:#fff;border:0;border-radius:8px">
          Làm lại
        </button>
      </div>
    </div>
  `,
})
export class ResultPage implements OnInit {
  loading = false;
  err = '';
  result: any = null;

  constructor(private http: HttpClient, private router: Router) {}

  ngOnInit(): void {
    const sessionId = Number(localStorage.getItem('test_session_id'));
    if (!sessionId) {
      this.router.navigateByUrl('/test-mbti');
      return;
    }

    this.loading = true;
    this.http.get(`/api/test-sessions/${sessionId}/result`).subscribe({
      next: (res) => {
        this.result = res;
        this.loading = false;
      },
      error: (e) => {
        this.loading = false;
        this.err = e?.error?.message ?? e?.message ?? 'Không load được kết quả';
      },
    });
  }

  restart() {
    localStorage.removeItem('test_session_id');
    this.router.navigateByUrl('/test-mbti');
  }
}