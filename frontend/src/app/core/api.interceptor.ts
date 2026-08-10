import { HttpInterceptorFn } from '@angular/common/http';
import { API_ORIGIN } from './api.config';


function getCookie(name: string): string | null {
  if (typeof document === 'undefined') return null;
  const m = document.cookie.match(new RegExp('(^|; )' + name + '=([^;]*)'));
  return m ? decodeURIComponent(m[2]) : null;
}

export const apiInterceptor: HttpInterceptorFn = (req, next) => {
  let r = req;

  if (r.url.startsWith('/api')) {
    r = r.clone({
      url: `${API_ORIGIN}${r.url}`,
      withCredentials: true,
      setHeaders: { Accept: 'application/json' },
    });
  }

  if (r.url.startsWith('/sanctum')) {
    r = r.clone({
      url: `${API_ORIGIN}${r.url}`,
      withCredentials: true,
      setHeaders: { Accept: 'application/json' },
    });
  }

  const isWrite = !['GET', 'HEAD', 'OPTIONS'].includes(r.method);
  if (isWrite) {
    const xsrf = getCookie('XSRF-TOKEN');
    if (xsrf) {
      r = r.clone({
        setHeaders: {
          'X-XSRF-TOKEN': xsrf,
          'XSRF-TOKEN': xsrf,
        },
      });
    }
  }

  return next(r);
};