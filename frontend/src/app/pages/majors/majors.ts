import { Component, OnInit, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { finalize } from 'rxjs/operators';
import { ResultApiService } from '../../services/result-api.service';

type MajorItem = {
  id: number;
  title: string;
  code: string;
  group: string;
  desc: string;
  image: string;
  tags: string[];
  prospects: string;
  schools: string[];
};

@Component({
  selector: 'app-majors',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './majors.html',
  styleUrl: './majors.css'
})
export class Majors implements OnInit {
  private api = inject(ResultApiService);
  private cdr = inject(ChangeDetectorRef);

  keyword = '';
  majors: MajorItem[] = [];

  loading = false;
  error = '';

  selectedMajor: MajorItem | null = null;

  currentPage = 1;
  readonly pageSize = 9;

  ngOnInit(): void {
    this.loadMajors();
  }

  /**
   * Tự động xử lý URL hình ảnh tương thích cả Localhost lẫn Production
   */
  getImageUrl(imagePath: string | null | undefined): string {
    if (!imagePath) return '/images/major-default.png';

    const isLocalhost = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1';
    const prodBackendDomain = 'https://mbti-career.onrender.com';
    const localBackendDomain = 'http://localhost:8000'; // Đổi port nếu Laravel local của bạn dùng port khác

    // 1. Trường hợp là URL tuyệt đối (bắt đầu bằng http/https)
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      // Nếu đang chạy trên Vercel/Production nhưng Backend lại trả về localhost (do chưa config APP_URL)
      if (!isLocalhost && (imagePath.includes('localhost') || imagePath.includes('127.0.0.1'))) {
        return imagePath.replace(/^https?:\/\/[^\/]+/, prodBackendDomain);
      }
      return imagePath;
    }

    // 2. Trường hợp là đường dẫn tương đối (ví dụ /storage/majors/xxx.png)
    const baseDomain = isLocalhost ? localBackendDomain : prodBackendDomain;
    return `${baseDomain}${imagePath.startsWith('/') ? '' : '/'}${imagePath}`;
  }

  loadMajors(): void {
    this.loading = true;
    this.error = '';

    this.api.getPublicMajors()
      .pipe(
        finalize(() => {
          this.loading = false;
          this.ensureValidCurrentPage();
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: (res: any) => {
          try {
            const rawItems = Array.isArray(res)
              ? res
              : Array.isArray(res?.data)
                ? res.data
                : [];

            this.majors = rawItems.map((item: any) => {
              const rawSkills = item?.skills;
              let tags: string[] = [];

              if (Array.isArray(rawSkills)) {
                tags = rawSkills.map((x: any) => String(x).trim()).filter(Boolean);
              } else if (typeof rawSkills === 'string') {
                tags = rawSkills
                  .split(',')
                  .map((x: string) => x.trim())
                  .filter(Boolean);
              } else if (Array.isArray(item?.tags)) {
                tags = item.tags.map((x: any) => String(x).trim()).filter(Boolean);
              }

              const rawImg = item?.image ?? item?.image_url;

              return {
                id: Number(item?.id ?? 0),
                title: String(item?.name ?? item?.title ?? 'Chưa có tên ngành'),
                code: String(item?.code ?? ''),
                group: String(item?.group ?? item?.category ?? 'Ngành nghề'),
                desc: String(item?.description ?? item?.desc ?? ''),
                image: this.getImageUrl(rawImg),
                prospects: String(item?.career_prospects ?? item?.prospects ?? ''),
                schools: Array.isArray(item?.top_schools)
                  ? item.top_schools.map((x: any) => String(x))
                  : typeof item?.top_schools === 'string'
                    ? item.top_schools.split(',').map((x: string) => x.trim()).filter(Boolean)
                    : [],
                tags
              };
            });

            this.currentPage = 1;
            this.error = '';
            this.ensureValidCurrentPage();
            this.cdr.detectChanges();
          } catch (err) {
            console.error('Lỗi xử lý dữ liệu majors:', err, res);
            this.majors = [];
            this.currentPage = 1;
            this.error = 'Dữ liệu ngành nghề không đúng định dạng.';
            this.cdr.detectChanges();
          }
        },
        error: (err) => {
          console.error('Lỗi lấy majors:', err);
          this.majors = [];
          this.currentPage = 1;
          this.error = 'Không tải được danh sách ngành';
          this.cdr.detectChanges();
        }
      });
  }

  get filteredMajors(): MajorItem[] {
    const q = this.keyword.trim().toLowerCase();

    return this.majors.filter((item) => {
      return (
        !q ||
        item.title.toLowerCase().includes(q) ||
        item.code.toLowerCase().includes(q) ||
        item.group.toLowerCase().includes(q) ||
        item.desc.toLowerCase().includes(q) ||
        item.prospects.toLowerCase().includes(q) ||
        item.tags.some(tag => tag.toLowerCase().includes(q))
      );
    });
  }

  get totalPages(): number {
    const total = Math.ceil(this.filteredMajors.length / this.pageSize);
    return total > 0 ? total : 1;
  }

  get paginatedMajors(): MajorItem[] {
    const start = (this.currentPage - 1) * this.pageSize;
    return this.filteredMajors.slice(start, start + this.pageSize);
  }

  get pageNumbers(): Array<number | string> {
    const total = this.totalPages;
    const current = this.currentPage;

    if (total <= 7) {
      return Array.from({ length: total }, (_, i) => i + 1);
    }

    if (current <= 4) {
      return [1, 2, 3, 4, 5, '...', total];
    }

    if (current >= total - 3) {
      return [1, '...', total - 4, total - 3, total - 2, total - 1, total];
    }

    return [1, '...', current - 1, current, current + 1, '...', total];
  }

  onKeywordChange(): void {
    this.currentPage = 1;
    this.ensureValidCurrentPage();
    this.cdr.detectChanges();
  }

  goToPage(page: number | string): void {
    if (page === '...') return;

    const pageNumber = Number(page);

    if (pageNumber < 1 || pageNumber > this.totalPages || pageNumber === this.currentPage) return;

    this.currentPage = pageNumber;
    this.cdr.detectChanges();
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  prevPage(): void {
    if (this.currentPage > 1) {
      this.goToPage(this.currentPage - 1);
    }
  }

  nextPage(): void {
    if (this.currentPage < this.totalPages) {
      this.goToPage(this.currentPage + 1);
    }
  }

  openDetail(item: MajorItem): void {
    this.selectedMajor = { ...item };
    this.cdr.detectChanges();
  }

  closeDetail(): void {
    this.selectedMajor = null;
    this.cdr.detectChanges();
  }

  trackByMajorId(_: number, item: MajorItem): number {
    return item.id;
  }

  trackByPage(_: number, page: number | string): number | string {
    return page;
  }

  private ensureValidCurrentPage(): void {
    if (this.currentPage > this.totalPages) {
      this.currentPage = this.totalPages;
    }
    if (this.currentPage < 1) {
      this.currentPage = 1;
    }
  }
}