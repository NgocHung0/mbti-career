import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { API_ORIGIN } from '../../../core/api.config';

@Injectable({
  providedIn: 'root'
})
export class MbtiService {
  private http = inject(HttpClient);
  private baseUrl = API_ORIGIN;

  getAdminMbtiQuestions(page = 1, perPage = 10, axis = 'all', packageType = 'all'): Observable<any> {
    return this.http.get<any>(`${this.baseUrl}/api/admin/mbti/questions`, {
      params: {
        page,
        per_page: perPage,
        axis,
        package_type: packageType
      },
      withCredentials: true
    });
  }

  createAdminMbtiQuestion(payload: {
    question: string;
    option_a: string;
    option_b: string;
    axis: string;
    package_type: string;
  }): Observable<any> {
    return this.http.post<any>(
      `${this.baseUrl}/api/admin/mbti/questions`,
      payload,
      { withCredentials: true }
    );
  }

  updateAdminMbtiQuestion(id: number, payload: {
    question: string;
    option_a: string;
    option_b: string;
    axis: string;
    package_type: string;
  }): Observable<any> {
    return this.http.put<any>(
      `${this.baseUrl}/api/admin/mbti/questions/${id}`,
      payload,
      { withCredentials: true }
    );
  }

  deleteAdminMbtiQuestion(id: number): Observable<any> {
    return this.http.delete<any>(
      `${this.baseUrl}/api/admin/mbti/questions/${id}`,
      { withCredentials: true }
    );
  }
  
}