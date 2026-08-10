import {
  ApplicationConfig
} from '@angular/core';

import {
  provideRouter,
  withInMemoryScrolling
} from '@angular/router';

import {
  provideHttpClient,
  withFetch,
  withInterceptors
} from '@angular/common/http';

import {
  routes
} from './app.routes';

import {
  authTokenInterceptor
} from './core/auth-token.interceptor';

import {
  apiInterceptor
} from './core/api.interceptor';

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(
      routes,
      withInMemoryScrolling({
        scrollPositionRestoration: 'top',
        anchorScrolling: 'enabled'
      })
    ),

    provideHttpClient(
      withFetch(),
      withInterceptors([
        apiInterceptor,
        authTokenInterceptor
      ])
    )
  ]
};