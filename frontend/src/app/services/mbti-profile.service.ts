import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';

@Injectable({
  providedIn: 'root'
})
export class MbtiProfileService {
  constructor(private http: HttpClient) {}

  getByCode(code: string) {
    return this.http.get('/api/mbti-profiles/' + code);
  }
}