import {
  Component,
  OnDestroy,
  OnInit,
  computed,
  inject,
  signal
} from '@angular/core';
import { CommonModule, Location } from '@angular/common';
import { Router } from '@angular/router';
import { finalize } from 'rxjs/operators';
import {
  PackageAdminService,
  TestPackage
} from '../../features/admin/services/package-admin.service';

type PackageType = 'free' | 'basic' | 'full';

@Component({
  selector: 'app-test-complete',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './test-complete.html',
  styleUrl: './test-complete.css'
})
export class TestComplete implements OnInit, OnDestroy {
  private router = inject(Router);
  private location = inject(Location);
  private packageService = inject(PackageAdminService);

  loading = signal(false);
  errorMessage = signal('');

  packages = signal<TestPackage[]>([]);
  selectedPackageId = signal<number | 'free'>('free');

  showAdModal = false;
  adCountdown = 5;
  adTimer: any = null;

  packageOptions = computed(() => {
    return [...this.packages()]
      .filter(item => !!item.is_active)
      .sort((a, b) => {
        const aWeight = a.include_ability_test ? 2 : 1;
        const bWeight = b.include_ability_test ? 2 : 1;

        if (aWeight !== bWeight) return aWeight - bWeight;

        if ((a.sort_order ?? 0) !== (b.sort_order ?? 0)) {
          return (a.sort_order ?? 0) - (b.sort_order ?? 0);
        }

        return a.id - b.id;
      });
  });

  ngOnInit(): void {
    this.loadPackages();
  }

  loadPackages(): void {
    this.loading.set(true);
    this.errorMessage.set('');

    this.packageService.getPackages()
      .pipe(finalize(() => this.loading.set(false)))
      .subscribe({
        next: (res) => {
          this.packages.set(res?.packages ?? []);
        },
        error: (err) => {
          console.error(err);
          this.errorMessage.set('Không tải được gói dịch vụ từ API admin.');
        }
      });
  }

  selectPackage(packageId: number | 'free'): void {
    this.selectedPackageId.set(packageId);
  }

  isSelected(packageId: number | 'free'): boolean {
    return this.selectedPackageId() === packageId;
  }

  continueWithPackage(): void {
    const selectedId = this.selectedPackageId();

    if (selectedId === 'free') {
      this.savePackageToStorage('free', null, false);
      this.startAdFlow();
      return;
    }

    const selectedPkg = this.packageOptions().find(item => item.id === selectedId);

    if (!selectedPkg) {
      this.errorMessage.set('Không tìm thấy gói đã chọn.');
      return;
    }

    const packageType: PackageType = selectedPkg.include_ability_test ? 'full' : 'basic';

    this.savePackageToStorage(
      packageType,
      selectedPkg.id,
      !!selectedPkg.include_ability_test
    );

    this.goToResult(packageType);
  }

  startAdFlow(): void {
    this.clearTimer();
    this.showAdModal = true;
    this.adCountdown = 5;

    this.adTimer = setInterval(() => {
      this.adCountdown--;

      if (this.adCountdown <= 0) {
        this.clearTimer();
        this.showAdModal = false;
        this.goToResult('free');
      }
    }, 1000);
  }

  skipAdNow(): void {
    this.clearTimer();
    this.showAdModal = false;
    this.goToResult('free');
  }

  closePopup(): void {
    this.clearTimer();

    if (history.length > 1) {
      this.location.back();
      return;
    }

    this.router.navigateByUrl('/mbti-test');
  }

  getPackageTypeLabel(item: TestPackage): string {
    return item.include_ability_test ? 'GÓI FULL' : 'GÓI CƠ BẢN';
  }

  getPackageTitle(item: TestPackage): string {
    return item.name?.trim()
      || (item.include_ability_test
        ? 'Gói test tính cách + năng lực'
        : 'Gói test tính cách');
  }

  getPackageDesc(item: TestPackage): string {
    return item.short_description?.trim()
      || item.description?.trim()
      || (item.include_ability_test
        ? 'Gồm test tính cách và năng lực, không quảng cáo, mở khóa toàn bộ khóa học.'
        : 'Gồm test tính cách, không quảng cáo, xem kết quả ngay.');
  }

  getFeatures(item: TestPackage): string[] {
    const features = ['Test tính cách', 'Không cần xem quảng cáo'];

    if (item.include_ability_test) {
      features.push('Test năng lực');
      features.push('Mở khóa toàn bộ khóa học');
    } else {
      features.push('Xem kết quả ngay');
    }

    return features;
  }

  private savePackageToStorage(
    type: PackageType,
    packageId: number | null,
    isFull: boolean
  ): void {
    if (typeof window === 'undefined') return;

    localStorage.setItem('selected_package', type);

    if (packageId !== null) {
      localStorage.setItem('selected_package_id', String(packageId));
    } else {
      localStorage.removeItem('selected_package_id');
    }

    localStorage.setItem(
      'package_features',
      JSON.stringify({
        free: type === 'free',
        personality: type === 'basic' || type === 'full',
        ability: isFull,
        noAds: type === 'basic' || type === 'full',
        unlockAllCourses: isFull
      })
    );
  }

  private goToResult(type: PackageType): void {
    if (type === 'full') {
      this.router.navigateByUrl('/ability-result');
      return;
    }

    this.router.navigateByUrl('/result-basic');
  }

  private clearTimer(): void {
    if (this.adTimer) {
      clearInterval(this.adTimer);
      this.adTimer = null;
    }
  }

  ngOnDestroy(): void {
    this.clearTimer();
  }
}