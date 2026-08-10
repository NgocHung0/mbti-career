import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';

type MbtiQuestion = {
  id: number;
  content: string;
  axis: 'EI' | 'SN' | 'TF' | 'JP';
  dir_a: string;
  dir_b: string;
  label_a: string;
  label_b: string;
  order: number;
};

@Component({
  standalone: true,
  selector: 'app-test-mbti-page',
  imports: [CommonModule, FormsModule],
  template: `
    <div style="max-width:900px;margin:30px auto;font-family:system-ui">
      <h1 style="text-align:center">Bài test MBTI</h1>

      <div style="display:flex;justify-content:space-between;align-items:center;margin:10px 0">
        <div>Tổng câu: <b>{{questions.length}}</b></div>
        <div>Đã chọn: <b>{{answeredCount}}</b>/{{questions.length}}</div>
      </div>

      <p *ngIf="loading">Đang tải câu hỏi...</p>
      <p *ngIf="err" style="color:red">{{err}}</p>

      <div *ngFor="let q of questions; let i = index"
           style="border:1px solid #eee;padding:12px;border-radius:10px;margin:12px 0">
        <div><b>Câu {{i+1}}:</b> {{q.content}}</div>

        <div style="margin-top:8px;display:flex;gap:14px;flex-wrap:wrap">
          <label style="cursor:pointer">
            <input type="radio" [name]="'q'+q.id" [value]="q.dir_a"
                   [(ngModel)]="answers[q.id]" (ngModelChange)="syncAnswered()" />
            {{q.label_a}}
          </label>

          <label style="cursor:pointer">
            <input type="radio" [name]="'q'+q.id" [value]="q.dir_b"
                   [(ngModel)]="answers[q.id]" (ngModelChange)="syncAnswered()" />
            {{q.label_b}}
          </label>
        </div>
      </div>

      <button (click)="submit()"
              [disabled]="loading || questions.length===0 || answeredCount !== questions.length || submitting"
              style="display:block;margin:20px auto;padding:10px 16px;background:#16a34a;color:#fff;border:0;border-radius:8px">
        {{submitting ? 'Đang nộp...' : 'Nộp bài'}}
      </button>

      <p *ngIf="answeredCount !== questions.length && questions.length>0"
         style="text-align:center;color:#777">
        Bạn cần trả lời đủ {{questions.length}} câu để nộp bài.
      </p>
    </div>
  `,
})
export class TestMbtiPage implements OnInit {
  questions: MbtiQuestion[] = [];
  answers: Record<number, string> = {};
  answeredCount = 0;

  loading = false;
  submitting = false;
  err = '';

  constructor(private http: HttpClient, private router: Router) {}

  ngOnInit(): void {
    this.loadQuestions();
  }

  private loadQuestions() {
    this.loading = true;
    this.err = '';
    this.http.get<MbtiQuestion[]>('/api/mbti/questions').subscribe({
      next: (res) => {
        this.questions = (res ?? []).sort((a, b) => (a.order ?? 0) - (b.order ?? 0));
        this.loading = false;
        this.syncAnswered();
      },
      error: (e) => {
        this.loading = false;
        this.err = e?.error?.message ?? e?.message ?? 'Không load được câu hỏi';
        console.error(e);
      },
    });
  }

  syncAnswered() {
    this.answeredCount = Object.keys(this.answers).filter((k) => !!this.answers[Number(k)]).length;
  }

  private getOrCreateSessionId(): Promise<number> {
    const cached = localStorage.getItem('test_session_id');
    if (cached) return Promise.resolve(Number(cached));

    // tạo session mới
    return new Promise((resolve, reject) => {
      this.http.post<any>('/api/test-sessions', {}).subscribe({
        next: (res) => {
          const id = Number(res?.id);
          if (!id) return reject(new Error('Không tạo được session'));
          localStorage.setItem('test_session_id', String(id));
          resolve(id);
        },
        error: (e) => reject(e),
      });
    });
  }

  async submit() {
    if (this.answeredCount !== this.questions.length) return;

    this.submitting = true;
    this.err = '';

    try {
      const sessionId = await this.getOrCreateSessionId();

      // payload: mảng answer theo question_id
      const payload = {
        answers: this.questions.map((q) => ({
          question_id: q.id,
          choice: this.answers[q.id], // 'E'/'I'/'S'/'N'...
        })),
      };

      await new Promise<void>((resolve, reject) => {
        this.http.post(`/api/test-sessions/${sessionId}/submit`, payload).subscribe({
          next: () => resolve(),
          error: (e) => reject(e),
        });
      });

      // qua trang chọn sở thích
      this.router.navigateByUrl('/interest');
    } catch (e: any) {
      console.error(e);
      this.err = e?.error?.message ?? e?.message ?? 'Nộp bài lỗi';
    } finally {
      this.submitting = false;
    }
  }
}