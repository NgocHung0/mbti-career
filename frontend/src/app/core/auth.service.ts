import { Injectable, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, tap } from 'rxjs';
import { API_URL } from './api.config';

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

export type RegisterPayload = {
  name: string;
  email: string;
  password: string;
  password_confirmation: string;
};

export type RegisterResponse = {
  message: string;
  user: User;
};

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private readonly apiUrl = API_URL;

  user = signal<User | null>(null);
  authChecked = signal<boolean>(false);

  constructor(private http: HttpClient) {
    if (typeof window !== 'undefined') {
      const savedUser = localStorage.getItem('auth_user');

      if (savedUser) {
        try {
          this.user.set(JSON.parse(savedUser));
        } catch {
          localStorage.removeItem('auth_user');
          this.user.set(null);
        }
      }
    }
  }

  login(email: string, password: string): Observable<LoginResponse> {
    return this.http.post<LoginResponse>(`${this.apiUrl}/login`, {
      email,
      password
    }).pipe(
      tap((res) => {
        if (typeof window !== 'undefined') {
          localStorage.setItem('auth_token', res.token);
          localStorage.setItem('auth_user', JSON.stringify(res.user));
        }

        this.user.set(res.user);
        this.authChecked.set(true);
      })
    );
  }

  register(payload: RegisterPayload): Observable<RegisterResponse> {
    return this.http.post<RegisterResponse>(`${this.apiUrl}/register`, payload);
  }

  me(): Observable<User> {
    return this.http.get<User>(`${this.apiUrl}/me`).pipe(
      tap((user) => {
        if (typeof window !== 'undefined') {
          localStorage.setItem('auth_user', JSON.stringify(user));
        }

        this.user.set(user);
        this.authChecked.set(true);
      })
    );
  }

  logout(): Observable<{ message: string }> {
    return this.http.post<{ message: string }>(`${this.apiUrl}/logout`, {}).pipe(
      tap(() => {
        if (typeof window !== 'undefined') {
          localStorage.removeItem('auth_token');
          localStorage.removeItem('auth_user');
        }

        this.user.set(null);
        this.authChecked.set(true);
      })
    );
  }

  getToken(): string | null {
    if (typeof window === 'undefined') {
      return null;
    }

    return localStorage.getItem('auth_token');
  }

  isLoggedIn(): boolean {
    return !!this.getToken();
  }

  clearSession(): void {
    if (typeof window !== 'undefined') {
      localStorage.removeItem('auth_token');
      localStorage.removeItem('auth_user');
    }

    this.user.set(null);
    this.authChecked.set(true);
  }

  bootstrapAuth(): void {
    const token = this.getToken();

    if (!token) {
      this.authChecked.set(true);
      return;
    }

    this.me().subscribe({
      next: () => {},
      error: () => {
        this.clearSession();
      }
    });
  }
}