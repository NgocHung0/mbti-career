import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Router } from '@angular/router';
import { HttpClient } from '@angular/common/http';

@Component({
  selector: 'app-admin-layout',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './admin-layout.html',
  styleUrl: './admin-layout.css'
})
export class AdminLayout {

  sidebarOpen = false;

  private router = inject(Router);
  private http = inject(HttpClient);

  toggleSidebar() {
    this.sidebarOpen = !this.sidebarOpen;
  }

  closeSidebar() {
    this.sidebarOpen = false;
  }

  logout() {

    this.http.post('/api/logout', {}).subscribe({
      next: () => {
        localStorage.removeItem('token');
        localStorage.removeItem('role');
        this.router.navigateByUrl('/admin/login');
      },
      error: () => {
        localStorage.removeItem('token');
        localStorage.removeItem('role');
        this.router.navigateByUrl('/admin/login');
      }
    });

  }

}