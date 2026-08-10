import { Injectable, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { tap } from 'rxjs/operators';
import { API_URL } from '../core/api.config';

export type User = {
  id: number;
  name: string;
  email: string;
};

export type LoginResponse = {
  message: string;
  token: string;
  user: User;
};

export type RegisterResponse = {
  message: string;
  token: string;
  user: User;
};

@Injectable({
  providedIn: 'root'
})
export class ResultApiService {
  private http = inject(HttpClient);
  private apiUrl = API_URL;

  user = signal<User | null>(null);

  constructor() {
    if (typeof window !== 'undefined') {
      const raw = localStorage.getItem('auth_user');
      if (raw) {
        try {
          this.user.set(JSON.parse(raw));
        } catch {
          localStorage.removeItem('auth_user');
          this.user.set(null);
        }
      }
    }
  }

  login(email: string, password: string) {
    return this.http.post<LoginResponse>(`${this.apiUrl}/login`, {
      email,
      password
    }).pipe(
      tap((res) => {
        localStorage.setItem('auth_token', res.token);
        localStorage.setItem('auth_user', JSON.stringify(res.user));
        this.user.set(res.user);
      })
    );
  }

  register(payload: {
    name: string;
    email: string;
    password: string;
    password_confirmation: string;
  }) {
    return this.http.post<RegisterResponse>(`${this.apiUrl}/register`, payload).pipe(
      tap((res) => {
        localStorage.setItem('auth_token', res.token);
        localStorage.setItem('auth_user', JSON.stringify(res.user));
        this.user.set(res.user);
      })
    );
  }

  logout() {
    return this.http.post(`${this.apiUrl}/logout`, {}).pipe(
      tap(() => {
        localStorage.removeItem('auth_token');
        localStorage.removeItem('auth_user');
        this.user.set(null);
      })
    );
  }

  me() {
    return this.http.get<User>(`${this.apiUrl}/me`).pipe(
      tap((user) => {
        localStorage.setItem('auth_user', JSON.stringify(user));
        this.user.set(user);
      })
    );
  }

  isLoggedIn(): boolean {
    if (typeof window === 'undefined') return false;
    return !!localStorage.getItem('auth_token');
  }

  saveMbtiResult(payload: any) {
    return this.http.post(`${this.apiUrl}/mbti-results`, payload);
  }

  getLatestMbtiResult() {
    return this.http.get(`${this.apiUrl}/mbti-results/latest`);
  }

  getMbtiHistory() {
    return this.http.get(`${this.apiUrl}/mbti-results/history`);
  }

  saveInterestResult(payload: any) {
    return this.http.post(`${this.apiUrl}/interest-results`, payload);
  }

  getLatestInterestResult() {
    return this.http.get(`${this.apiUrl}/interest-results/latest`);
  }

  saveAbilityResult(payload: any) {
    return this.http.post(`${this.apiUrl}/ability-results`, payload);
  }

  getLatestAbilityResult() {
    return this.http.get(`${this.apiUrl}/ability-results/latest`);
  }

  getMajorRecommendations(level: 'plus' | 'premium' = 'plus', limit: number = 5) {
    return this.http.get<any>(
      `${this.apiUrl}/recommendations/majors?level=${level}&limit=${limit}`
    );
  }

  calculateMajorRecommendations(payload: {
    level: 'plus' | 'premium';
    mbti_type: string;
    mbti_scores?: any;
    interest_group_scores?: any;
    top_interest_groups?: string[];
    ability_scores?: any;
    limit?: number;
  }) {
    return this.http.post<any>(`${this.apiUrl}/recommendations/majors`, payload);
  }

  changePassword(payload: {
    current_password: string;
    new_password: string;
    new_password_confirmation: string;
  }) {
    return this.http.post(`${this.apiUrl}/change-password`, payload);
  }

  getMbtiQuestions(packageType: 'free' | 'plus' | 'premium' = 'free') {
    return this.http.get<any>(`${this.apiUrl}/mbti/questions?package_type=${packageType}`);
  }

  getPublicMbtiQuestions(packageType: 'free' | 'plus' | 'premium' = 'free') {
    return this.getMbtiQuestions(packageType);
  }

  getPublicMajors() {
    return this.http.get<any>(`${this.apiUrl}/majors`);
  }

  getPublicAdmissions() {
    return this.http.get<any>(`${this.apiUrl}/admissions`);
  }

  getPublicAdmissionDetail(id: number) {
    return this.http.get<any>(`${this.apiUrl}/admissions/${id}`);
  }

  getAdminUsers(
    page: number = 1,
    perPage: number = 10,
    q: string = '',
    status: string = 'all',
    role: string = 'all'
  ) {
    let url =
      `${this.apiUrl}/admin/users` +
      `?page=${page}` +
      `&per_page=${perPage}`;

    if (q.trim()) {
      url += `&q=${encodeURIComponent(q.trim())}`;
    }

    if (status && status !== 'all') {
      url += `&status=${encodeURIComponent(status)}`;
    }

    if (role && role !== 'all') {
      url += `&role=${encodeURIComponent(role)}`;
    }

    return this.http.get<any>(url);
  }

  createAdminUser(payload: any) {
    return this.http.post<any>(`${this.apiUrl}/admin/users`, payload);
  }

  updateAdminUser(id: number, payload: any) {
    return this.http.put<any>(`${this.apiUrl}/admin/users/${id}`, payload);
  }

  deleteAdminUser(id: number) {
    return this.http.delete<any>(`${this.apiUrl}/admin/users/${id}`);
  }

  getAdminMbtiQuestions(page: number = 1, perPage: number = 10, axis: string = '') {
    let url = `${this.apiUrl}/admin/mbti-questions?page=${page}&per_page=${perPage}`;

    if (axis && axis !== 'all') {
      url += `&axis=${axis}`;
    }

    return this.http.get<any>(url);
  }

  createAdminMbtiQuestion(payload: any) {
    return this.http.post<any>(`${this.apiUrl}/admin/mbti-questions`, payload);
  }

  updateAdminMbtiQuestion(id: number, payload: any) {
    return this.http.put<any>(`${this.apiUrl}/admin/mbti-questions/${id}`, payload);
  }

  deleteAdminMbtiQuestion(id: number) {
    return this.http.delete<any>(`${this.apiUrl}/admin/mbti-questions/${id}`);
  }

  getAdminMajors(page: number = 1, perPage: number = 10, q: string = '', includeInactive: boolean = true) {
    let url = `${this.apiUrl}/admin/majors?page=${page}&per_page=${perPage}&include_inactive=${includeInactive ? 1 : 0}`;

    if (q.trim()) {
      url += `&q=${encodeURIComponent(q.trim())}`;
    }

    return this.http.get<any>(url);
  }

  createAdminMajor(payload: FormData) {
    return this.http.post<any>(`${this.apiUrl}/admin/majors`, payload);
  }

  updateAdminMajor(id: number, payload: FormData) {
    payload.append('_method', 'PUT');
    return this.http.post<any>(`${this.apiUrl}/admin/majors/${id}`, payload);
  }

  deleteAdminMajor(id: number) {
    return this.http.delete<any>(`${this.apiUrl}/admin/majors/${id}`);
  }

  suggestAdminMajorVector(payload: any) {
    return this.http.post<any>(`${this.apiUrl}/admin/majors/ai-suggest-vector`, payload);
  }

  getAdminAdmissions(
    page: number = 1,
    perPage: number = 10,
    q: string = '',
    includeInactive: boolean = true,
    status: string = 'all'
  ) {
    let url =
      `${this.apiUrl}/admin/admissions` +
      `?page=${page}` +
      `&per_page=${perPage}` +
      `&include_inactive=${includeInactive ? 1 : 0}`;

    if (q.trim()) {
      url += `&q=${encodeURIComponent(q.trim())}`;
    }

    if (status && status !== 'all') {
      url += `&status=${encodeURIComponent(status)}`;
    }

    return this.http.get<any>(url);
  }

  createAdminAdmission(payload: FormData) {
    return this.http.post<any>(`${this.apiUrl}/admin/admissions`, payload);
  }

  updateAdminAdmission(id: number, payload: FormData) {
    payload.append('_method', 'PUT');
    return this.http.post<any>(`${this.apiUrl}/admin/admissions/${id}`, payload);
  }
  
  deleteAdminAdmission(id: number) {
    return this.http.delete<any>(`${this.apiUrl}/admin/admissions/${id}`);
  }

  getServicePackages() {
    return this.http.get<any>(`${this.apiUrl}/admin/packages`);
  }
}