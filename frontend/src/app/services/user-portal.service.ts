import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { TestPackage } from '../features/admin/services/package-admin.service';
import { API_URL } from '../core/api.config';

export interface UserPackageResponse {
  packages: TestPackage[];
  current_package: TestPackage | null;
  current_package_meta: any;
}

export interface AssignPackageResponse {
  message: string;
  record: {
    id: number;
    user_id: number;
    package_id: number;
    status: string;
    started_at: string | null;
    expires_at: string | null;
    package?: TestPackage | null;
  };
}

export interface TestHistoryItem {
  id: number;
  test_session_id?: string | null;
  test_type: string;
  result_code: string | null;
  package_name: string | null;
  created_at: string;
  result_payload?: any;
  scores?: Record<string, number> | null;
}

export interface TestHistoryDetail {
  id: number;
  test_session_id?: string | null;
  test_type: string;
  result_code: string | null;
  answers: Record<string, 'A' | 'B'> | null;
  questions: any[] | null;
  scores: Record<string, number> | null;
  result_payload: any;
  package_id: number | null;
  package_name: string | null;
  created_at: string;
}

export type PaymentStatus =
  | ''
  | 'PENDING'
  | 'PROCESSING'
  | 'PAID'
  | 'CANCELLED'
  | 'EXPIRED';

export interface CreatePaymentLinkResponse {
  message: string;
  order_id?: number;
  order_code: number;
  payment_link_id: string | null;
  checkout_url: string;
  qr_code: string;
  amount: number;
  status: PaymentStatus;
}

export interface PaymentStatusResponse {
  success: boolean;
  status: PaymentStatus;
  order_code: number;
  package_id: number;
  package?: TestPackage | null;
  paid_at?: string | null;
}

@Injectable({
  providedIn: 'root'
})
export class UserPortalService {
  private http = inject(HttpClient);
  private readonly baseUrl = `${API_URL}/user`;

  private buildAuthOptions() {
    let headers = new HttpHeaders({
      Accept: 'application/json'
    });

    if (typeof window !== 'undefined') {
      const token = localStorage.getItem('auth_token');

      if (token) {
        headers = headers.set('Authorization', `Bearer ${token}`);
      }
    }

    return { headers };
  }

  getPackages(): Observable<UserPackageResponse> {
    return this.http.get<UserPackageResponse>(
      `${this.baseUrl}/service-packages`,
      this.buildAuthOptions()
    );
  }

  assignPackage(packageId: number): Observable<AssignPackageResponse> {
    return this.http.post<AssignPackageResponse>(
      `${this.baseUrl}/service-packages/assign`,
      { package_id: packageId },
      this.buildAuthOptions()
    );
  }

  getHistories(): Observable<{ histories: TestHistoryItem[] }> {
    return this.http.get<{ histories: TestHistoryItem[] }>(
      `${this.baseUrl}/test-histories`,
      this.buildAuthOptions()
    );
  }

  getHistoryDetail(id: number): Observable<{ history: TestHistoryDetail }> {
    return this.http.get<{ history: TestHistoryDetail }>(
      `${this.baseUrl}/test-histories/${id}`,
      this.buildAuthOptions()
    );
  }

  storeHistory(payload: {
    test_session_id?: string | null;
    test_type: string;
    result_code?: string | null;
    answers?: Record<number, 'A' | 'B'> | Record<string, 'A' | 'B'>;
    questions?: any[];
    scores?: Record<string, number>;
    result_payload?: any;
    package_id?: number | null;
    package_name?: string | null;
  }): Observable<any> {
    return this.http.post(
      `${this.baseUrl}/test-histories`,
      payload,
      this.buildAuthOptions()
    );
  }

  createPaymentLink(packageId: number): Observable<CreatePaymentLinkResponse> {
    return this.http.post<CreatePaymentLinkResponse>(
      `/api/mbti-payment/create`,
      { package_id: packageId },
      this.buildAuthOptions()
    );
  }

  getPaymentStatus(orderCode: number): Observable<PaymentStatusResponse> {
    return this.http.get<PaymentStatusResponse>(
      `/api/mbti-payment/status/${orderCode}`,
      this.buildAuthOptions()
    );
  }

  buildQrImageUrl(qrCode: string | null | undefined): string {
    const value = String(qrCode ?? '').trim();
    if (!value) return '';

    if (value.startsWith('data:image/')) {
      return value;
    }

    return `https://api.qrserver.com/v1/create-qr-code/?size=260x260&data=${encodeURIComponent(value)}`;
  }

  getSelectedPackageFromStorage(): TestPackage | null {
    if (typeof window === 'undefined') return null;

    const raw = localStorage.getItem('selected_package');
    if (!raw) return null;

    try {
      return JSON.parse(raw) as TestPackage;
    } catch {
      return null;
    }
  }

  setSelectedPackageToStorage(pkg: TestPackage | null): void {
    if (typeof window === 'undefined') return;

    if (!pkg) {
      localStorage.removeItem('selected_package');
      return;
    }

    localStorage.setItem('selected_package', JSON.stringify(pkg));
  }

  getOrCreateTestSessionId(): string {
    if (typeof window === 'undefined') return '';

    const current = localStorage.getItem('test_session_id');
    if (current) return current;

    const id =
      typeof crypto !== 'undefined' && 'randomUUID' in crypto
        ? crypto.randomUUID()
        : `session_${Date.now()}_${Math.random().toString(36).slice(2, 10)}`;

    localStorage.setItem('test_session_id', id);
    return id;
  }

  getTestSessionId(): string | null {
    if (typeof window === 'undefined') return null;
    return localStorage.getItem('test_session_id');
  }

  clearTestSessionId(): void {
    if (typeof window === 'undefined') return;
    localStorage.removeItem('test_session_id');
  }
}