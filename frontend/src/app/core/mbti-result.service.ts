import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { API_URL } from './api.config';

export type MbtiResultPayload = {
  mbti_type: string;
  scores: {
    e: number;
    i: number;
    s: number;
    n: number;
    t: number;
    f: number;
    j: number;
    p: number;
  };
  upgrade_interest: boolean;
  upgrade_ability: boolean;
  answers: Record<number, 'A' | 'B'>;
};

@Injectable({
  providedIn: 'root'
})
export class MbtiResultService {
  private readonly apiUrl = API_URL;

  constructor(private http: HttpClient) {}

  saveResult(payload: MbtiResultPayload): Observable<any> {
    return this.http.post(`${this.apiUrl}/mbti-results`, payload);
  }

  getLatestResult(): Observable<any> {
    return this.http.get(`${this.apiUrl}/mbti-results/latest`);
  }
}