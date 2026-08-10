import { RouterLink } from '@angular/router';
import { Component, AfterViewInit, Inject, PLATFORM_ID } from '@angular/core';
import { isPlatformBrowser, CommonModule } from '@angular/common';

type MbtiType = {
  code: string;
  name: string;
  emoji: string;
  short: string;
  detail: string;
};

@Component({
  selector: 'app-landing',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './landing.html',
  styleUrl: './landing.css'
})
export class LandingComponent implements AfterViewInit {
  selectedMbti: MbtiType | null = null;

mbtiTypes: MbtiType[] = [
  { code: 'ISTJ', name: 'Người trách nhiệm', emoji: '/images/emoji/ISTJ.png', short: 'Thực tế, kỷ luật và đáng tin cậy.', detail: 'ISTJ là nhóm tính cách thực tế, nghiêm túc và có trách nhiệm. Họ thích sự rõ ràng, làm việc có kế hoạch và luôn cố gắng hoàn thành nhiệm vụ một cách chính xác.' },
  { code: 'ISFJ', name: 'Người bảo vệ', emoji: '/images/emoji/ISFJ.png', short: 'Tận tâm, chu đáo và biết quan tâm.', detail: 'ISFJ là nhóm tính cách ấm áp, chu đáo và đáng tin cậy. Họ thường quan tâm đến người khác, thích giúp đỡ và luôn âm thầm hỗ trợ mọi người xung quanh.' },
  { code: 'INFJ', name: 'Người cố vấn', emoji: '/images/emoji/INFJ.png', short: 'Sâu sắc, lý tưởng và truyền cảm hứng.', detail: 'INFJ là nhóm tính cách sâu sắc, giàu trực giác và sống có lý tưởng. Họ thường quan tâm đến ý nghĩa cuộc sống và mong muốn tạo ra điều tích cực cho người khác.' },
  { code: 'INTJ', name: 'Nhà chiến lược', emoji: '/images/emoji/INTJ.png', short: 'Độc lập, logic và định hướng tương lai.', detail: 'INTJ là nhóm tính cách độc lập, lý trí và có tầm nhìn dài hạn. Họ thích phân tích vấn đề, lập kế hoạch và tìm ra cách làm hiệu quả hơn.' },

  { code: 'ISTP', name: 'Nhà cơ học', emoji: '/images/emoji/ISTP.png', short: 'Linh hoạt, thực tế và thích hành động.', detail: 'ISTP là nhóm tính cách thực tế, linh hoạt và thích tự mình khám phá. Họ thường bình tĩnh, thích hành động hơn lời nói và giỏi xử lý tình huống.' },
  { code: 'ISFP', name: 'Nghệ sĩ', emoji: '/images/emoji/ISFP.png', short: 'Nhạy cảm, tinh tế và yêu tự do.', detail: 'ISFP là nhóm tính cách nhẹ nhàng, tinh tế và sống theo cảm xúc cá nhân. Họ yêu cái đẹp, thích tự do và thường thể hiện bản thân qua hành động hơn lời nói.' },
  { code: 'INFP', name: 'Người lý tưởng', emoji: '/images/emoji/INFP.png', short: 'Sáng tạo, chân thành và giàu cảm xúc.', detail: 'INFP là nhóm tính cách giàu cảm xúc, chân thành và sống theo giá trị riêng. Họ thường có trí tưởng tượng phong phú và luôn muốn làm điều có ý nghĩa.' },
  { code: 'INTP', name: 'Nhà tư duy', emoji: '/images/emoji/INTP.png', short: 'Logic, tò mò và thích khám phá.', detail: 'INTP là nhóm tính cách tò mò, thích suy nghĩ và khám phá ý tưởng mới. Họ thường yêu thích logic, đặt nhiều câu hỏi và muốn hiểu bản chất của vấn đề.' },

  { code: 'ESTP', name: 'Người năng động', emoji: '/images/emoji/ESTP.png', short: 'Nhanh nhạy, thực tế và thích thử thách.', detail: 'ESTP là nhóm tính cách năng động, thực tế và thích trải nghiệm. Họ nhanh nhạy, thích hành động và thường tự tin trong các tình huống mới.' },
  { code: 'ESFP', name: 'Người trình diễn', emoji: '/images/emoji/ESFP.png', short: 'Vui vẻ, hòa đồng và thích sự chú ý.', detail: 'ESFP là nhóm tính cách vui vẻ, hòa đồng và giàu năng lượng. Họ thích tương tác với mọi người, sống tích cực và dễ tạo không khí thoải mái.' },
  { code: 'ENFP', name: 'Người truyền cảm hứng', emoji: '/images/emoji/ENFP.png', short: 'Nhiệt tình, sáng tạo và kết nối tốt.', detail: 'ENFP là nhóm tính cách nhiệt huyết, sáng tạo và giàu cảm hứng. Họ thích khám phá điều mới, kết nối với mọi người và lan tỏa năng lượng tích cực.' },
  { code: 'ENTP', name: 'Nhà tranh luận', emoji: '/images/emoji/ENTP.png', short: 'Thông minh, linh hoạt và thích ý tưởng mới.', detail: 'ENTP là nhóm tính cách nhanh trí, thích tranh luận và yêu thích ý tưởng mới. Họ thường linh hoạt, sáng tạo và không ngại thử thách quan điểm cũ.' },

  { code: 'ESTJ', name: 'Người quản lý', emoji: '/images/emoji/ESTJ.png', short: 'Quyết đoán, tổ chức và thực tế.', detail: 'ESTJ là nhóm tính cách rõ ràng, quyết đoán và có khả năng tổ chức. Họ thích sự trật tự, làm việc theo mục tiêu và đề cao trách nhiệm.' },
  { code: 'ESFJ', name: 'Người quan tâm', emoji: '/images/emoji/ESFJ.png', short: 'Ấm áp, trách nhiệm và thích hỗ trợ.', detail: 'ESFJ là nhóm tính cách thân thiện, chu đáo và coi trọng cộng đồng. Họ thường quan tâm đến cảm xúc của người khác và thích tạo sự gắn kết.' },
  { code: 'ENFJ', name: 'Người dẫn dắt', emoji: '/images/emoji/ENFJ.png', short: 'Truyền cảm hứng, giao tiếp tốt và biết định hướng.', detail: 'ENFJ là nhóm tính cách ấm áp, có khả năng truyền cảm hứng và dẫn dắt người khác. Họ giỏi lắng nghe, kết nối và giúp mọi người phát triển.' },
  { code: 'ENTJ', name: 'Chỉ huy', emoji: '/images/emoji/ENTJ.png', short: 'Tự tin, chiến lược và hướng mục tiêu.', detail: 'ENTJ là nhóm tính cách tự tin, quyết đoán và có tố chất lãnh đạo. Họ thích đặt mục tiêu, lập kế hoạch và thúc đẩy mọi việc tiến về phía trước.' }
];

  constructor(@Inject(PLATFORM_ID) private platformId: Object) {}

  ngAfterViewInit(): void {
    if (!isPlatformBrowser(this.platformId)) return;
    setTimeout(() => this.runCounters(), 300);
  }

  toggleMbti(item: MbtiType): void {
    this.selectedMbti =
      this.selectedMbti?.code === item.code ? null : item;
  }

  runCounters(): void {
    if (!isPlatformBrowser(this.platformId)) return;

    const counters = document.querySelectorAll('.counter');

    counters.forEach((counter: any) => {
      const target = Number(counter.getAttribute('data-target') || 0);
      let current = 0;
      const step = Math.ceil(target / 60);

      const timer = setInterval(() => {
        current += step;
        if (current >= target) {
          current = target;
          clearInterval(timer);
        }
        counter.textContent = current.toString();
      }, 25);
    });
  }
}