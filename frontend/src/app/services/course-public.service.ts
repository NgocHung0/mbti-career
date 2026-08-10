import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface PublicCourseItem {
  id: number;
  name: string;
  slug?: string | null;
  price: number;
  short_description?: string | null;
  description?: string | null;
  course_major?: string | null;
  course_level?: string | null;
  thumbnail?: string | null;
  is_active: boolean;
  is_featured: boolean;
  sort_order?: number | null;
  created_at?: string;
  updated_at?: string;
}

@Injectable({
  providedIn: 'root'
})
export class CoursePublicService {
  private http = inject(HttpClient);

  getCourses(): Observable<{ courses: PublicCourseItem[] }> {
    return this.http.get<{ courses: PublicCourseItem[] }>('/api/courses');
  }

  getCourseDetail(id: number): Observable<{ course: PublicCourseItem }> {
    return this.http.get<{ course: PublicCourseItem }>(`/api/courses/${id}`);
  }
}