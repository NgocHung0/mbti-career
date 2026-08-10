import { CommonModule } from '@angular/common';
import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { finalize } from 'rxjs/operators';
import {
  CourseLessonItem,
  CourseLessonPayload,
  CourseLessonsService,
} from '../../services/course-lessons.service';
import {
  LessonQuizItem,
  LessonQuizPayload,
  LessonQuizzesService,
  QuizOptionKey,
} from '../../services/lesson-quizzes.service';

@Component({
  selector: 'app-course-lessons',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './course-lessons.html',
  styleUrl: './course-lessons.css'
})
export class CourseLessons implements OnInit {
  private fb = inject(FormBuilder);
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private lessonService = inject(CourseLessonsService);
  private quizService = inject(LessonQuizzesService);

  courseId = Number(this.route.snapshot.paramMap.get('id') || 0);

  loading = signal(false);
  saving = signal(false);
  deleting = signal(false);

  loadingQuizzes = signal(false);
  savingQuiz = signal(false);
  deletingQuizId = signal<number | null>(null);
  expandedLessonId = signal<number | null>(null);

  courseName = signal('Khóa học');
  keyword = signal('');

  lessons = signal<CourseLessonItem[]>([]);
  selectedLessonId = signal<number | null>(null);

  successMessage = signal('');
  errorMessage = signal('');

  showQuizPanel = signal(false);
  editingQuizId = signal<number | null>(null);

  lessonQuizzes = signal<Record<number, LessonQuizItem[]>>({});

  lessonForm = this.fb.nonNullable.group({
    title: ['', [Validators.required, Validators.maxLength(255)]],
    description: [''],
    video_url: [''],
    duration: [''],
    sort_order: [1, [Validators.required, Validators.min(1)]],
    is_active: [true],
  });

  quizForm = this.fb.nonNullable.group({
    question: ['', [Validators.required]],
    option_a: ['', [Validators.required]],
    option_b: ['', [Validators.required]],
    option_c: [''],
    option_d: [''],
    correct_answer: ['A' as QuizOptionKey, [Validators.required]],
    sort_order: [1, [Validators.required, Validators.min(1)]],
  });

  readonly filteredLessons = computed(() => {
    const kw = this.keyword().trim().toLowerCase();

    const items = [...this.lessons()].sort((a, b) => {
      if ((a.sort_order ?? 0) !== (b.sort_order ?? 0)) {
        return (a.sort_order ?? 0) - (b.sort_order ?? 0);
      }
      return a.id - b.id;
    });

    if (!kw) return items;

    return items.filter(item => {
      const text = [item.title, item.description, item.duration]
        .filter(Boolean)
        .join(' ')
        .toLowerCase();

      return text.includes(kw);
    });
  });

  readonly selectedLesson = computed(() => {
    const id = this.selectedLessonId();
    if (!id) return null;
    return this.lessons().find(item => item.id === id) ?? null;
  });

  readonly selectedLessonQuizzes = computed(() => {
    const lessonId = this.selectedLessonId();
    if (!lessonId) return [];

    return [...(this.lessonQuizzes()[lessonId] ?? [])].sort((a, b) => {
      if ((a.sort_order ?? 0) !== (b.sort_order ?? 0)) {
        return (a.sort_order ?? 0) - (b.sort_order ?? 0);
      }
      return a.id - b.id;
    });
  });

  ngOnInit(): void {
    this.loadLessons();
  }

  loadLessons(autoSelectFirst = true, shouldClearMessages = true): void {
    if (!this.courseId) {
      this.errorMessage.set('Không tìm thấy khóa học.');
      return;
    }

    this.loading.set(true);

    if (shouldClearMessages) {
      this.clearMessages();
    }

    this.lessonService.getLessons(this.courseId)
      .pipe(finalize(() => this.loading.set(false)))
      .subscribe({
        next: (res) => {
          const incomingLessons = res?.lessons ?? [];

          this.courseName.set(res?.course?.name || 'Khóa học');
          this.lessons.set(incomingLessons);

          const currentId = this.selectedLessonId();
          const stillExists = !!currentId && incomingLessons.some(item => item.id === currentId);

          const selected = stillExists
            ? incomingLessons.find(item => item.id === currentId) ?? null
            : (autoSelectFirst ? incomingLessons[0] ?? null : null);

          if (selected) {
            this.selectedLessonId.set(selected.id);
            this.patchLessonForm(selected);
            this.loadQuizzes(selected.id, true);
          } else {
            this.selectedLessonId.set(null);
            this.expandedLessonId.set(null);
            this.resetLessonForm();
            this.showQuizPanel.set(false);
            this.editingQuizId.set(null);
            this.resetQuizForm();
          }

          this.preloadQuizDataForLessons(incomingLessons);
        },
        error: (err) => {
          console.error(err);
          this.errorMessage.set(err?.error?.message || 'Không tải được danh sách bài học.');
        }
      });
  }

  loadQuizzes(lessonId: number, showLoading = false): void {
    if (!lessonId) return;

    if (showLoading) {
      this.loadingQuizzes.set(true);
    }

    this.quizService.getQuizzes(lessonId)
      .pipe(finalize(() => {
        if (showLoading) {
          this.loadingQuizzes.set(false);
        }
      }))
      .subscribe({
        next: (res) => {
          this.lessonQuizzes.update(map => ({
            ...map,
            [lessonId]: res?.quizzes ?? [],
          }));

          if (this.selectedLessonId() === lessonId && !this.editingQuizId()) {
            this.resetQuizForm();
          }
        },
        error: (err) => {
          console.error(err);
        }
      });
  }

  preloadQuizDataForLessons(lessons: CourseLessonItem[]): void {
    for (const lesson of lessons) {
      const lessonId = lesson.id;
      if (!lessonId) continue;

      if (this.lessonQuizzes()[lessonId] === undefined) {
        this.loadQuizzes(lessonId, false);
      }
    }
  }

  toggleLessonQuizPreview(lessonId: number): void {
    const nextExpandedId = this.expandedLessonId() === lessonId ? null : lessonId;
    this.expandedLessonId.set(nextExpandedId);

    if (nextExpandedId && this.lessonQuizzes()[lessonId] === undefined) {
      this.loadQuizzes(lessonId, false);
    }
  }

  setKeyword(value: string): void {
    this.keyword.set(value);
  }

  selectLesson(id: number): void {
    const lesson = this.lessons().find(item => item.id === id);
    if (!lesson) return;

    this.selectedLessonId.set(id);
    this.patchLessonForm(lesson);
    this.clearMessages();

    this.showQuizPanel.set(false);
    this.editingQuizId.set(null);
    this.resetQuizForm();

    if (this.expandedLessonId() && this.expandedLessonId() !== id) {
      this.expandedLessonId.set(null);
    }

    this.loadQuizzes(id, true);
  }

  createNewLesson(): void {
    this.selectedLessonId.set(null);
    this.expandedLessonId.set(null);
    this.resetLessonForm();
    this.clearMessages();

    this.showQuizPanel.set(false);
    this.editingQuizId.set(null);
    this.resetQuizForm();
  }

  saveLesson(): void {
    if (this.lessonForm.invalid) {
      this.lessonForm.markAllAsTouched();
      return;
    }

    this.saving.set(true);
    this.clearMessages();

    const raw = this.lessonForm.getRawValue();

    const payload: CourseLessonPayload = {
      title: raw.title.trim(),
      description: this.normalizeNullable(raw.description),
      video_url: this.normalizeNullable(raw.video_url),
      duration: this.normalizeNullable(raw.duration),
      sort_order: Number(raw.sort_order || 1),
      is_active: !!raw.is_active,
    };

    const currentId = this.selectedLessonId();

    const request$ = currentId
      ? this.lessonService.updateLesson(this.courseId, currentId, payload)
      : this.lessonService.createLesson(this.courseId, payload);

    request$
      .pipe(finalize(() => this.saving.set(false)))
      .subscribe({
        next: () => {
          this.successMessage.set(currentId ? 'Cập nhật bài học thành công.' : 'Tạo bài học thành công.');
          this.errorMessage.set('');

          if (currentId) {
            this.loadLessons(true, false);
            return;
          }

          this.selectedLessonId.set(null);
          this.expandedLessonId.set(null);
          this.showQuizPanel.set(false);
          this.editingQuizId.set(null);
          this.resetQuizForm();

          this.loadLessons(false, false);
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

          this.errorMessage.set(apiMessage || 'Lưu bài học thất bại.');
        }
      });
  }

  removeLesson(): void {
    const lesson = this.selectedLesson();
    if (!lesson) return;

    const ok = window.confirm(`Bạn có chắc muốn xóa bài học "${lesson.title}" không?`);
    if (!ok) return;

    this.deleting.set(true);
    this.clearMessages();

    this.lessonService.deleteLesson(this.courseId, lesson.id)
      .pipe(finalize(() => this.deleting.set(false)))
      .subscribe({
        next: () => {
          this.successMessage.set('Xóa bài học thành công.');

          this.lessonQuizzes.update(map => {
            const next = { ...map };
            delete next[lesson.id];
            return next;
          });

          if (this.expandedLessonId() === lesson.id) {
            this.expandedLessonId.set(null);
          }

          this.loadLessons();
        },
        error: (err) => {
          console.error(err);
          this.errorMessage.set(err?.error?.message || 'Xóa bài học thất bại.');
        }
      });
  }

  openQuizPanel(): void {
    const lessonId = this.selectedLessonId();

    if (!lessonId) {
      this.errorMessage.set('Vui lòng chọn một bài học trước khi thêm trắc nghiệm.');
      this.successMessage.set('');
      return;
    }

    this.showQuizPanel.set(true);
    this.editingQuizId.set(null);
    this.resetQuizForm();
    this.clearMessages();

    if (this.lessonQuizzes()[lessonId] === undefined) {
      this.loadQuizzes(lessonId, true);
    }

    setTimeout(() => {
      const el = document.getElementById('quiz-panel');
      el?.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }, 50);
  }

  closeQuizPanel(): void {
    this.showQuizPanel.set(false);
    this.editingQuizId.set(null);
    this.resetQuizForm();
  }

  saveQuiz(): void {
    const lessonId = this.selectedLessonId();
    if (!lessonId) {
      this.errorMessage.set('Vui lòng chọn bài học trước.');
      this.successMessage.set('');
      return;
    }

    if (this.quizForm.invalid) {
      this.quizForm.markAllAsTouched();
      return;
    }

    this.savingQuiz.set(true);
    this.clearMessages();

    const raw = this.quizForm.getRawValue();
    const editingId = this.editingQuizId();

    const payload: LessonQuizPayload = {
      question: raw.question.trim(),
      option_a: raw.option_a.trim(),
      option_b: raw.option_b.trim(),
      option_c: raw.option_c.trim() || null,
      option_d: raw.option_d.trim() || null,
      correct_answer: raw.correct_answer,
      sort_order: Number(raw.sort_order || 1),
    };

    const request$ = editingId
      ? this.quizService.updateQuiz(lessonId, editingId, payload)
      : this.quizService.createQuiz(lessonId, payload);

    request$
      .pipe(finalize(() => this.savingQuiz.set(false)))
      .subscribe({
        next: () => {
          this.successMessage.set(editingId ? 'Cập nhật câu hỏi thành công.' : 'Thêm câu hỏi thành công.');
          this.errorMessage.set('');
          this.editingQuizId.set(null);
          this.resetQuizForm();

          this.loadQuizzes(lessonId, true);
          this.expandedLessonId.set(lessonId);
        },
        error: (err) => {
          console.error(err);

          const apiMessage = err?.error?.message;
          const validationErrors = err?.error?.errors;

          if (validationErrors) {
            const firstKey = Object.keys(validationErrors)[0];
            const firstMessage = validationErrors[firstKey]?.[0];
            this.errorMessage.set(firstMessage || 'Dữ liệu câu hỏi không hợp lệ.');
            return;
          }

          this.errorMessage.set(apiMessage || 'Lưu câu hỏi thất bại.');
        }
      });
  }

  editQuiz(item: LessonQuizItem): void {
    this.showQuizPanel.set(true);
    this.editingQuizId.set(item.id);

    this.quizForm.reset({
      question: item.question,
      option_a: item.option_a,
      option_b: item.option_b,
      option_c: item.option_c ?? '',
      option_d: item.option_d ?? '',
      correct_answer: item.correct_answer,
      sort_order: item.sort_order ?? 1,
    });

    this.clearMessages();

    setTimeout(() => {
      const el = document.getElementById('quiz-panel');
      el?.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }, 50);
  }

  removeQuiz(quizId: number): void {
    const lessonId = this.selectedLessonId();
    if (!lessonId) return;

    const ok = window.confirm('Bạn có chắc muốn xóa câu hỏi này không?');
    if (!ok) return;

    this.deletingQuizId.set(quizId);
    this.clearMessages();

    this.quizService.deleteQuiz(lessonId, quizId)
      .pipe(finalize(() => this.deletingQuizId.set(null)))
      .subscribe({
        next: () => {
          this.successMessage.set('Xóa câu hỏi thành công.');
          this.errorMessage.set('');

          if (this.editingQuizId() === quizId) {
            this.editingQuizId.set(null);
            this.resetQuizForm();
          }

          this.loadQuizzes(lessonId, true);
        },
        error: (err) => {
          console.error(err);
          this.errorMessage.set(err?.error?.message || 'Xóa câu hỏi thất bại.');
        }
      });
  }

  getQuizCount(lessonId: number): number {
    return (this.lessonQuizzes()[lessonId] ?? []).length;
  }

  goBack(): void {
    this.router.navigate(['/admin/courses']);
  }

  trackLesson(_: number, item: CourseLessonItem): number {
    return item.id;
  }

  trackQuiz(_: number, item: LessonQuizItem): number {
    return item.id;
  }

  private patchLessonForm(lesson: CourseLessonItem): void {
    this.lessonForm.reset({
      title: lesson.title ?? '',
      description: lesson.description ?? '',
      video_url: lesson.video_url ?? '',
      duration: lesson.duration ?? '',
      sort_order: lesson.sort_order ?? 1,
      is_active: !!lesson.is_active,
    });

    this.lessonForm.markAsPristine();
    this.lessonForm.markAsUntouched();
  }

  private resetLessonForm(): void {
    const nextOrder = this.lessons().length + 1;

    this.lessonForm.reset({
      title: '',
      description: '',
      video_url: '',
      duration: '',
      sort_order: nextOrder,
      is_active: true,
    });

    this.lessonForm.markAsPristine();
    this.lessonForm.markAsUntouched();
  }

  private resetQuizForm(): void {
    const nextOrder = this.selectedLessonQuizzes().length + 1;

    this.quizForm.reset({
      question: '',
      option_a: '',
      option_b: '',
      option_c: '',
      option_d: '',
      correct_answer: 'A',
      sort_order: nextOrder,
    });

    this.quizForm.markAsPristine();
    this.quizForm.markAsUntouched();
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