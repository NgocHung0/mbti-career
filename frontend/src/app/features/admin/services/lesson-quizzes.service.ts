import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export type QuizOptionKey = 'A' | 'B' | 'C' | 'D';

export interface LessonQuizItem {
  id: number;
  lesson_id: number;
  question: string;
  option_a: string;
  option_b: string;
  option_c: string | null;
  option_d: string | null;
  correct_answer: QuizOptionKey;
  sort_order: number;
  created_at?: string;
  updated_at?: string;
}

export interface LessonQuizzesResponse {
  lesson: {
    id: number;
    title: string;
  };
  quizzes: LessonQuizItem[];
}

export interface LessonQuizPayload {
  question: string;
  option_a: string;
  option_b: string;
  option_c?: string | null;
  option_d?: string | null;
  correct_answer: QuizOptionKey;
  sort_order?: number;
}

@Injectable({
  providedIn: 'root'
})
export class LessonQuizzesService {
  private http = inject(HttpClient);

  getQuizzes(lessonId: number): Observable<LessonQuizzesResponse> {
    return this.http.get<LessonQuizzesResponse>(`/api/admin/lessons/${lessonId}/quizzes`);
  }

  createQuiz(
    lessonId: number,
    payload: LessonQuizPayload
  ): Observable<{ message: string; quiz: LessonQuizItem }> {
    return this.http.post<{ message: string; quiz: LessonQuizItem }>(
      `/api/admin/lessons/${lessonId}/quizzes`,
      payload
    );
  }

  updateQuiz(
    lessonId: number,
    quizId: number,
    payload: LessonQuizPayload
  ): Observable<{ message: string; quiz: LessonQuizItem }> {
    return this.http.put<{ message: string; quiz: LessonQuizItem }>(
      `/api/admin/lessons/${lessonId}/quizzes/${quizId}`,
      payload
    );
  }

  deleteQuiz(lessonId: number, quizId: number): Observable<{ message: string }> {
    return this.http.delete<{ message: string }>(
      `/api/admin/lessons/${lessonId}/quizzes/${quizId}`
    );
  }
}