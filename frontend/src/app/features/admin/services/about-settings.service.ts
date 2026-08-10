import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface AboutStatItem {
  id?: number;
  label: string;
  value: string;
  sort_order: number;
  is_active: boolean;
}

export interface AboutSettingItem {
  id?: number;
  hero_title: string | null;
  short_description: string | null;
  full_description: string | null;
  mission_title: string | null;
  mission_description: string | null;
  vision_title: string | null;
  vision_description: string | null;
  privacy_policy?: string | null;
  banner_image: string | null;
  secondary_image: string | null;
}

export interface AboutResponse {
  setting: AboutSettingItem | null;
  stats: AboutStatItem[];
  message?: string;
}

@Injectable({
  providedIn: 'root'
})
export class AboutSettingsService {
  private http = inject(HttpClient);

  getAboutSettings(): Observable<AboutResponse> {
    return this.http.get<AboutResponse>('/api/settings/about');
  }

  saveAboutSettings(payload: AboutSettingItem): Observable<AboutResponse> {
    return this.http.post<AboutResponse>('/api/settings/about', payload);
  }

  createStat(payload: AboutStatItem): Observable<AboutStatItem> {
    return this.http.post<AboutStatItem>('/api/settings/about/stats', payload);
  }

  updateStat(id: number, payload: AboutStatItem): Observable<AboutStatItem> {
    return this.http.put<AboutStatItem>(`/api/settings/about/stats/${id}`, payload);
  }

  deleteStat(id: number): Observable<{ message: string }> {
    return this.http.delete<{ message: string }>(`/api/settings/about/stats/${id}`);
  }

  uploadAboutImage(file: File, type: 'banner' | 'secondary'): Observable<{ message: string; path: string; url: string }> {
    const formData = new FormData();
    formData.append('image', file);
    formData.append('type', type);

    return this.http.post<{ message: string; path: string; url: string }>(
      '/api/settings/about/upload',
      formData
    );
  }
}