import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface CourseLessonItem {
  id: number;
  service_package_id: number;
  title: string;
  description: string | null;
  video_url: string | null;
  duration: string | null;
  sort_order: number;
  is_active: boolean;
  created_at?: string;
  updated_at?: string;
}

export interface CourseLessonsResponse {
  course: {
    id: number;
    name: string;
  };
  lessons: CourseLessonItem[];
}

export interface CourseLessonPayload {
  title: string;
  description?: string | null;
  video_url?: string | null;
  duration?: string | null;
  sort_order?: number;
  is_active?: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class CourseLessonsService {
  private http = inject(HttpClient);

  getLessons(courseId: number): Observable<CourseLessonsResponse> {
    return this.http.get<CourseLessonsResponse>(`/api/admin/courses/${courseId}/lessons`);
  }

  createLesson(courseId: number, payload: CourseLessonPayload): Observable<{ message: string; lesson: CourseLessonItem }> {
    return this.http.post<{ message: string; lesson: CourseLessonItem }>(
      `/api/admin/courses/${courseId}/lessons`,
      payload
    );
  }

  updateLesson(
    courseId: number,
    lessonId: number,
    payload: CourseLessonPayload
  ): Observable<{ message: string; lesson: CourseLessonItem }> {
    return this.http.put<{ message: string; lesson: CourseLessonItem }>(
      `/api/admin/courses/${courseId}/lessons/${lessonId}`,
      payload
    );
  }

  deleteLesson(courseId: number, lessonId: number): Observable<{ message: string }> {
    return this.http.delete<{ message: string }>(
      `/api/admin/courses/${courseId}/lessons/${lessonId}`
    );
  }
}