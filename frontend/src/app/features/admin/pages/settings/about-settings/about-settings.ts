import { CommonModule } from '@angular/common';
import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { FormArray, FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { finalize } from 'rxjs/operators';
import {
  AboutSettingItem,
  AboutSettingsService,
  AboutStatItem
} from '../../../services/about-settings.service';

@Component({
  selector: 'app-about-settings',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './about-settings.html',
  styleUrl: './about-settings.css'
})
export class AboutSettingsComponent implements OnInit {
  private fb = inject(FormBuilder);
  private service = inject(AboutSettingsService);

  loading = signal(false);
  saving = signal(false);
  uploadingBanner = signal(false);
  uploadingSecondary = signal(false);
  deletingStatId = signal<number | null>(null);

  successMessage = signal('');
  errorMessage = signal('');

  form = this.fb.group({
    hero_title: ['Về chúng tôi', [Validators.maxLength(255)]],
    short_description: [''],
    full_description: [''],
    mission_title: ['Sứ mệnh', [Validators.maxLength(255)]],
    mission_description: [''],
    vision_title: ['Tầm nhìn', [Validators.maxLength(255)]],
    vision_description: [''],
    privacy_policy: [''],
    banner_image: [''],
    secondary_image: [''],
    stats: this.fb.array([])
  });

  readonly statsControls = computed(() => this.statsArray.controls);

  get statsArray(): FormArray {
    return this.form.get('stats') as FormArray;
  }

  ngOnInit(): void {
    this.loadData();
  }

  loadData(): void {
    this.loading.set(true);
    this.clearMessages();

    this.service.getAboutSettings()
      .pipe(finalize(() => this.loading.set(false)))
      .subscribe({
        next: (res) => {
          const setting = res?.setting;

          this.form.patchValue({
            hero_title: setting?.hero_title ?? 'Về chúng tôi',
            short_description: setting?.short_description ?? '',
            full_description: setting?.full_description ?? '',
            mission_title: setting?.mission_title ?? 'Sứ mệnh',
            mission_description: setting?.mission_description ?? '',
            vision_title: setting?.vision_title ?? 'Tầm nhìn',
            vision_description: setting?.vision_description ?? '',
            privacy_policy: setting?.privacy_policy ?? '',
            banner_image: setting?.banner_image ?? '',
            secondary_image: setting?.secondary_image ?? ''
          });

          this.statsArray.clear();

          (res?.stats ?? []).forEach((item) => {
            this.statsArray.push(this.createStatGroup(item));
          });
        },
        error: (err) => {
          console.error(err);
          this.errorMessage.set(err?.error?.message || 'Không tải được dữ liệu trang Về chúng tôi.');
        }
      });
  }

  createStatGroup(item?: AboutStatItem) {
    return this.fb.group({
      id: [item?.id ?? null],
      label: [item?.label ?? '', [Validators.required, Validators.maxLength(255)]],
      value: [item?.value ?? '', [Validators.required, Validators.maxLength(255)]],
      sort_order: [item?.sort_order ?? (this.statsArray.length + 1), [Validators.required, Validators.min(1)]],
      is_active: [item?.is_active ?? true]
    });
  }

  addStat(): void {
    this.statsArray.push(this.createStatGroup({
      label: '',
      value: '',
      sort_order: this.statsArray.length + 1,
      is_active: true
    }));
  }

  save(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    this.saving.set(true);
    this.clearMessages();

    const raw = this.form.getRawValue();

    const payload: AboutSettingItem = {
      hero_title: this.normalize(raw.hero_title),
      short_description: this.normalize(raw.short_description),
      full_description: this.normalize(raw.full_description),
      mission_title: this.normalize(raw.mission_title),
      mission_description: this.normalize(raw.mission_description),
      vision_title: this.normalize(raw.vision_title),
      vision_description: this.normalize(raw.vision_description),
      privacy_policy: this.normalize(raw.privacy_policy),
      banner_image: this.normalize(raw.banner_image),
      secondary_image: this.normalize(raw.secondary_image)
    };

    this.service.saveAboutSettings(payload)
      .pipe(finalize(() => this.saving.set(false)))
      .subscribe({
        next: (res) => {
          this.successMessage.set(res?.message || 'Lưu thành công.');
        },
        error: (err) => {
          console.error(err);
          this.errorMessage.set(err?.error?.message || 'Lưu thất bại.');
        }
      });
  }

  saveStat(index: number): void {
    const group = this.statsArray.at(index);

    if (group.invalid) {
      group.markAllAsTouched();
      return;
    }

    const raw = group.getRawValue();
    const payload: AboutStatItem = {
      label: (raw.label ?? '').trim(),
      value: (raw.value ?? '').trim(),
      sort_order: Number(raw.sort_order || index + 1),
      is_active: !!raw.is_active
    };

    const id = raw.id;
    const request$ = id
      ? this.service.updateStat(Number(id), payload)
      : this.service.createStat(payload);

    this.clearMessages();

    request$.subscribe({
      next: (res) => {
        if (!id && res?.id) {
          group.patchValue({ id: res.id });
        }

        this.successMessage.set(id ? 'Cập nhật thống kê thành công.' : 'Tạo thống kê thành công.');
      },
      error: (err) => {
        console.error(err);
        this.errorMessage.set(err?.error?.message || 'Lưu thống kê thất bại.');
      }
    });
  }

  removeStat(index: number): void {
    const group = this.statsArray.at(index);
    const statId = group.get('id')?.value;

    if (!statId) {
      this.statsArray.removeAt(index);
      return;
    }

    const ok = window.confirm('Bạn có chắc muốn xóa thống kê này không?');
    if (!ok) return;

    this.deletingStatId.set(Number(statId));
    this.clearMessages();

    this.service.deleteStat(Number(statId))
      .pipe(finalize(() => this.deletingStatId.set(null)))
      .subscribe({
        next: () => {
          this.statsArray.removeAt(index);
          this.successMessage.set('Xóa thống kê thành công.');
        },
        error: (err) => {
          console.error(err);
          this.errorMessage.set(err?.error?.message || 'Xóa thống kê thất bại.');
        }
      });
  }

  onUploadBanner(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;

    this.uploadingBanner.set(true);
    this.clearMessages();

    this.service.uploadAboutImage(file, 'banner')
      .pipe(finalize(() => {
        this.uploadingBanner.set(false);
        input.value = '';
      }))
      .subscribe({
        next: (res) => {
          this.form.patchValue({ banner_image: res.url });
          this.successMessage.set(res.message || 'Tải banner thành công.');
        },
        error: (err) => {
          console.error(err);
          this.errorMessage.set(err?.error?.message || 'Tải banner thất bại.');
        }
      });
  }

  onUploadSecondary(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;

    this.uploadingSecondary.set(true);
    this.clearMessages();

    this.service.uploadAboutImage(file, 'secondary')
      .pipe(finalize(() => {
        this.uploadingSecondary.set(false);
        input.value = '';
      }))
      .subscribe({
        next: (res) => {
          this.form.patchValue({ secondary_image: res.url });
          this.successMessage.set(res.message || 'Tải ảnh phụ thành công.');
        },
        error: (err) => {
          console.error(err);
          this.errorMessage.set(err?.error?.message || 'Tải ảnh phụ thất bại.');
        }
      });
  }

  private normalize(value: string | null | undefined): string | null {
    const v = (value ?? '').trim();
    return v ? v : null;
  }

  private clearMessages(): void {
    this.successMessage.set('');
    this.errorMessage.set('');
  }
}