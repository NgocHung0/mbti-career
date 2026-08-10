import { Routes } from '@angular/router';

/* =========================
   PUBLIC PAGES
========================= */
import { authGuard } from './core/auth.guard';
import { guestGuard } from './core/guest.guard';
import { LandingComponent } from './pages/landing/landing';
import { Login } from './pages/login/login';
import { MbtiTest } from './pages/mbti-test/mbti-test';
import { Majors } from './pages/majors/majors';
import { Admissions } from './pages/admissions/admissions';
import { About } from './pages/about/about';
import { TestComplete } from './pages/test-complete/test-complete';
import { ResultBasic } from './pages/result-basic/result-basic';
import { MePage } from './pages/me/me';
import { Courses } from './pages/courses/courses';
import { CourseLessons } from './features/admin/pages/course-lessons/course-lessons';
import { adminGuard } from './core/admin.guard';
/* =========================
   GUARDS
========================= */


export const routes: Routes = [
  /* =========================
     PUBLIC ROUTES
  ========================= */
  {
    path: '',
    component: LandingComponent,
  },
  { path: 'login', component: Login, canActivate: [guestGuard] },
  { path: 'mbti-test', component: MbtiTest },
  { path: 'me', component: MePage },
  { path: 'majors', component: Majors },
  { path: 'admissions', component: Admissions },
  { path: 'result-basic', component: ResultBasic },
  { path: 'about', component: About },
  { path: 'test-complete', component: TestComplete },

  /* =========================
     USER ROUTES
  ========================= */
  {
    path: 'interest-test',
    loadComponent: () =>
      import('./pages/interest-test/interest-test').then(m => m.InterestTest)
  },
  {
    path: 'interest-result',
    loadComponent: () =>
      import('./pages/interest-result/interest-result').then(m => m.InterestResult)
  },
  {
    path: 'ability-test',
    loadComponent: () =>
      import('./pages/ability-test/ability-test').then(m => m.AbilityTest)
  },
  {
    path: 'ability-result',
    loadComponent: () =>
      import('./pages/ability-result/ability-result').then(m => m.AbilityResult)
  },
  {
    path: 'courses',
    loadComponent: () =>
      import('./pages/courses/courses').then(m => m.Courses)
  },

  /* =========================
     ADMIN ROUTES
========================= */

  {
    path: 'admin/login',
    loadComponent: () =>
      import('./features/admin/pages/login/admin-login').then(
        m => m.AdminLogin
      )
  },

  {
  path: 'admin',
  loadComponent: () =>
    import('./features/admin/layout/admin-layout').then(
      m => m.AdminLayout
    ),
  canActivate: [adminGuard],
  data: {
    role: 'admin'
  },
  children: [
    {
      path: '',
      loadComponent: () =>
        import('./features/admin/pages/dashboard/admin-dashboard').then(
          m => m.AdminDashboard
        )
    },
    {
      path: 'dashboard',
      loadComponent: () =>
        import('./features/admin/pages/dashboard/admin-dashboard').then(
          m => m.AdminDashboard
        )
    },
    {
      path: 'users',
      loadComponent: () =>
        import('./features/admin/pages/users/admin-users').then(
          m => m.AdminUsers
        )
    },
    {
      path: 'mbti',
      loadComponent: () =>
        import('./features/admin/pages/mbti-admin/mbti-admin').then(m => m.MbtiAdminComponent),
      data: {
        title: 'Quản lý 16 nhóm MBTI'
      }
    },
    {
      path: 'tests',
      loadComponent: () =>
        import('./features/admin/pages/mbti/admin-mbti').then(
          m => m.AdminMbti
        )
    },
    {
      path: 'majors',
      loadComponent: () =>
        import('./features/admin/pages/majors/majors').then(
          m => m.AdminMajors
        )
    },
    {
      path: 'admissions',
      loadComponent: () =>
        import('./features/admin/pages/admissions/admissions').then(
          m => m.AdmissionsAdmin
        )
    },
    {
      path: 'packages',
      loadComponent: () =>
        import('./features/admin/pages/packages/packages').then(
          m => m.Packages
        )
    },
    {
      path: 'courses',
      loadComponent: () =>
        import('./features/admin/pages/courses/courses').then(
          m => m.Courses
        )
    },
    {
      path: 'courses/:id/lessons',
      component: CourseLessons
    },
    {
      path: 'settings',
      loadComponent: () =>
        import('./features/admin/pages/settings/settings').then(
          m => m.Settings
        ),
      data: {
        title: 'Cài đặt hệ thống'
      }
    },
    {
      path: 'settings/about',
      loadComponent: () =>
        import('./features/admin/pages/settings/about-settings/about-settings').then(
          m => m.AboutSettingsComponent
        ),
      data: {
        title: 'Nội dung trang Về chúng tôi'
      }
    }
  ]
},

  /* =========================
     FALLBACK
  ========================= */
  { path: '**', redirectTo: '' }
];