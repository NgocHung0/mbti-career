import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { API_URL } from '../../../core/api.config';

export interface TestPackage {
  id: number;
  name: string;
  slug: string;
  price: number;
  short_description: string | null;
  description: string | null;
  badge_text: string | null;
  theme: string;
  sort_order: number;
  is_active: boolean;
  is_featured: boolean;
  include_interest_test: boolean;
  include_ability_test: boolean;
  created_at?: string;
  updated_at?: string;
}

export interface PackagePayload {
  name: string;
  slug?: string | null;
  price: number;
  short_description?: string | null;
  description?: string | null;
  badge_text?: string | null;
  theme?: string | null;
  sort_order?: number;
  is_active?: boolean;
  is_featured?: boolean;
  include_interest_test?: boolean;
  include_ability_test?: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class PackageAdminService {
  private http = inject(HttpClient);

  private readonly baseUrl = `${API_URL}/admin/packages`;

  getPackages(): Observable<{ packages: TestPackage[] }> {
    return this.http.get<{ packages: TestPackage[] }>(this.baseUrl);
  }

  createPackage(payload: PackagePayload): Observable<{ message: string; package: TestPackage }> {
    return this.http.post<{ message: string; package: TestPackage }>(this.baseUrl, payload);
  }

  updatePackage(id: number, payload: PackagePayload): Observable<{ message: string; package: TestPackage }> {
    return this.http.put<{ message: string; package: TestPackage }>(`${this.baseUrl}/${id}`, payload);
  }

  deletePackage(id: number): Observable<{ message: string }> {
    return this.http.delete<{ message: string }>(`${this.baseUrl}/${id}`);
  }
}