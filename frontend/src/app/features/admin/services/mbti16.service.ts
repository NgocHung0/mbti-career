import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';

@Injectable({
  providedIn: 'root'
})
export class MbtiService {
  constructor(private http: HttpClient) {}

  getList() {
    return this.http.get('/api/admin/mbti');
  }

  create(data: any) {
    return this.http.post('/api/admin/mbti', data);
  }

  update(id: number, data: any) {
    return this.http.put('/api/admin/mbti/' + id, data);
  }

  delete(id: number) {
    return this.http.delete('/api/admin/mbti/' + id);
  }
}