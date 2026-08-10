import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { API_URL } from '../../../core/api.config';

export interface CourseItem {
  id: number;
  name: string;
  slug?: string | null;
  short_description?: string | null;
  description?: string | null;
  course_major?: string | null;
  thumbnail?: string | null;
  is_active: boolean;
  is_featured: boolean;
  sort_order?: number | null;
  created_at?: string;
  updated_at?: string;
}

export interface CoursePayload {
  name: string;
  short_description?: string | null;
  description?: string | null;
  course_major?: string | null;
  thumbnail?: string | null;
  is_active?: boolean;
  is_featured?: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class CourseAdminService {
  private http = inject(HttpClient);
  private apiUrl = `${API_URL}/admin/courses`;
  private readonly apiBase = `${API_URL}/admin`;
  private readonly coursesUrl = `${this.apiBase}/courses`;

  getCourses() {
    return this.http.get<any>(this.coursesUrl);
  }

  getMajors() {
    return this.http.get<string[]>(`${this.apiBase}/admissions/majors`);
  }

  createCourse(payload: CoursePayload): Observable<{ message: string; course: CourseItem }> {
    return this.http.post<{ message: string; course: CourseItem }>(this.apiUrl, payload);
  }

  updateCourse(id: number, payload: CoursePayload): Observable<{ message: string; course: CourseItem }> {
    return this.http.put<{ message: string; course: CourseItem }>(`${this.apiUrl}/${id}`, payload);
  }

  deleteCourse(id: number): Observable<{ message: string }> {
    return this.http.delete<{ message: string }>(`${this.apiUrl}/${id}`);
  }
}