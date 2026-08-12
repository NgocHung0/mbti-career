const isProduction = typeof window !== 'undefined' && 
  (window.location.hostname !== 'localhost' && window.location.hostname !== '127.0.0.1');

export const API_ORIGIN = isProduction
  ? 'https://mbti-career.onrender.com'
  : 'http://localhost:8000';

export const API_URL = `${API_ORIGIN}/api`;
export const STORAGE_URL = `${API_ORIGIN}/storage`;