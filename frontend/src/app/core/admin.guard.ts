import { inject, PLATFORM_ID } from '@angular/core';
import { ActivatedRouteSnapshot, CanActivateFn, Router, RouterStateSnapshot } from '@angular/router';
import { isPlatformBrowser } from '@angular/common';

export const adminGuard: CanActivateFn = (
  route: ActivatedRouteSnapshot,
  state: RouterStateSnapshot
) => {
  const router = inject(Router);
  const platformId = inject(PLATFORM_ID);

  // SSR: không check localStorage, cho đi qua
  if (!isPlatformBrowser(platformId)) {
    return true;
  }

  const token = localStorage.getItem('token');
  const role = localStorage.getItem('role');
  const requiredRole = route.data?.['role'];

  if (!token) {
    return router.createUrlTree(['/admin/login']);
  }

  if (requiredRole && role !== requiredRole) {
    return router.createUrlTree(['/admin/login']);
  }

  return true;
};