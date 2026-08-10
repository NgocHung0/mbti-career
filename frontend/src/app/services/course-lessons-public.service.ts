import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface PublicCourseLessonItem {
  id: number;
  title: string;
  description?: string | null;
  video_url?: string | null;
  duration?: string | null;
  sort_order: number;
  is_active: boolean;
  questions?: Array<{
    id?: number;
    question: string;
    explanation?: string | null;
    options?: Array<{
      id?: number;
      content: string;
      is_correct?: boolean;
    }>;
  }>;
}

@Injectable({
  providedIn: 'root'
})
export class CourseLessonsPublicService {
  private http = inject(HttpClient);

  getLessons(courseId: number) {
    const token = localStorage.getItem('auth_token');

    return this.http.get<any>(`/api/courses/${courseId}/lessons`, {
      withCredentials: true,
      headers: token
        ? {
            Authorization: `Bearer ${token}`,
            Accept: 'application/json',
          }
        : {
            Accept: 'application/json',
          },
    });
  }
}