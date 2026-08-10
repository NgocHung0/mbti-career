const host =
  typeof window !== 'undefined'
    ? window.location.hostname
    : '127.0.0.1';

export const API_ORIGIN = `http://${host}:8000`;
export const API_URL = `${API_ORIGIN}/api`;
export const STORAGE_URL = `${API_ORIGIN}/storage`;