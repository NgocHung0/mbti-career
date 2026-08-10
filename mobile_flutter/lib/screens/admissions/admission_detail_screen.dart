import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../models/admission.dart';
import '../../services/admission_service.dart';

class AdmissionDetailScreen extends StatefulWidget {
  final int admissionId;

  const AdmissionDetailScreen({super.key, required this.admissionId});

  @override
  State<AdmissionDetailScreen> createState() => _AdmissionDetailScreenState();
}

class _AdmissionDetailScreenState extends State<AdmissionDetailScreen> {
  late Future<Admission> _future;

  @override
  void initState() {
    super.initState();
    _future = AdmissionService.getAdmissionDetail(widget.admissionId);
  }

  Future<void> _reload() async {
    setState(() {
      _future = AdmissionService.getAdmissionDetail(widget.admissionId);
    });

    await _future;
  }

  Future<void> _openRegisterLink(String link) async {
    final rawLink = link.trim();

    if (rawLink.isEmpty) {
      _showNoRegisterLink();
      return;
    }

    final fixedLink =
        rawLink.startsWith('http://') || rawLink.startsWith('https://')
        ? rawLink
        : 'https://$rawLink';

    final uri = Uri.parse(fixedLink);

    final canOpen = await canLaunchUrl(uri);

    if (!canOpen) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể mở trang đăng ký.')),
      );
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showNoRegisterLink() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Trường này chưa cập nhật link đăng ký.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF000000) : AppColors.lightBlue,
      body: SafeArea(
        child: FutureBuilder<Admission>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _ErrorView(
                message: snapshot.error.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
                onRetry: _reload,
              );
            }

            final item = snapshot.data!;

            return _DetailContent(
              item: item,
              isDark: isDark,
              onOpenRegisterLink: _openRegisterLink,
              onNoRegisterLink: _showNoRegisterLink,
            );
          },
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  final Admission item;
  final bool isDark;
  final ValueChanged<String> onOpenRegisterLink;
  final VoidCallback onNoRegisterLink;

  const _DetailContent({
    required this.item,
    required this.isDark,
    required this.onOpenRegisterLink,
    required this.onNoRegisterLink,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = AdmissionService.resolveImageUrl(item.imageUrl);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TopBar(isDark: isDark),
                SizedBox(height: 16),
                _HeroCard(item: item, imageUrl: imageUrl, isDark: isDark),
                SizedBox(height: 16),
                _InfoGrid(item: item, isDark: isDark),
                SizedBox(height: 16),
                _SectionCard(
                  isDark: isDark,
                  title: 'Mô tả',
                  icon: Icons.article_outlined,
                  child: Text(
                    item.shortDescription ??
                        'Thông tin mô tả tuyển sinh đang được cập nhật.',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white70
                          : Colors.black.withValues(alpha: 0.68),
                      fontSize: 13,
                      height: 1.6,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 14),
                _SectionCard(
                  isDark: isDark,
                  title: 'Phương thức xét tuyển',
                  icon: Icons.fact_check_outlined,
                  child: Text(
                    item.admissionMethod ??
                        'Phương thức xét tuyển đang được cập nhật.',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white70
                          : Colors.black.withValues(alpha: 0.68),
                      fontSize: 13,
                      height: 1.6,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 14),
                _ContactCard(item: item, isDark: isDark),
              ],
            ),
          ),
        ),
        _BottomButton(
          item: item,
          isDark: isDark,
          onOpenRegisterLink: onOpenRegisterLink,
          onNoRegisterLink: onNoRegisterLink,
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool isDark;

  const _TopBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filled(
          style: IconButton.styleFrom(
            backgroundColor: isDark ? Color(0xFF111111) : Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : AppColors.textDark,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Chi tiết tuyển sinh',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final Admission item;
  final String? imageUrl;
  final bool isDark;

  const _HeroCard({
    required this.item,
    required this.imageUrl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18, 20, 18, 22),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFFE4EEF8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.07),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _DetailLogoBox(
                imageUrl: imageUrl,
                fallbackText: _initials(item.schoolName),
              ),

              Positioned(
                right: -8,
                top: -8,
                child: _StatusBadge(
                  status: item.status,
                  label: item.statusLabel,
                ),
              ),
            ],
          ),

          SizedBox(height: 18),

          Text(
            item.schoolName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black45,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),

          SizedBox(height: 6),

          Text(
            item.majorName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textDark,
              fontSize: 28,
              height: 1.08,
              fontWeight: FontWeight.w900,
            ),
          ),

          if (item.tags.isNotEmpty) ...[
            SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: item.tags.take(5).map((tag) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFFE4EEF8),
                    ),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _initials(String text) {
    final words = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (words.isEmpty) return 'TS';
    if (words.length == 1) {
      return words.first.characters.take(2).toString().toUpperCase();
    }

    return '${words.first.characters.first}${words.last.characters.first}'
        .toUpperCase();
  }
}

class _DetailLogoBox extends StatelessWidget {
  final String? imageUrl;
  final String fallbackText;

  const _DetailLogoBox({required this.imageUrl, required this.fallbackText});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      height: 118,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: const Color(0xFFE4EEF8),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl == null
          ? Center(
              child: Text(
                fallbackText,
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          : Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Center(
                  child: Text(
                    fallbackText,
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final Admission item;
  final bool isDark;

  const _InfoGrid({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final infos = [
      _InfoItem(
        icon: Icons.location_on_rounded,
        label: 'Thành phố',
        value: item.city ?? 'Đang cập nhật',
      ),
      _InfoItem(
        icon: Icons.payments_rounded,
        label: 'Học phí',
        value: item.tuitionFee ?? 'Đang cập nhật',
      ),
      _InfoItem(
        icon: Icons.menu_book_rounded,
        label: 'Tín chỉ',
        value: item.duration ?? 'Đang cập nhật',
      ),
      _InfoItem(
        icon: Icons.event_available_rounded,
        label: 'Hạn nộp',
        value: item.applicationDeadline ?? 'Đang cập nhật',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: infos.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, index) {
        final info = infos[index];

        return Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFE4EEF8),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.045),
                blurRadius: 14,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(info.icon, color: AppColors.primaryBlue, size: 20),
              ),
              SizedBox(height: 10),
              Text(
                info.label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black45,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 4),
              Text(
                info.value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textDark,
                  fontSize: 13,
                  height: 1.18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _SectionCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.isDark,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF111111) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE4EEF8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryBlue, size: 20),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final Admission item;
  final bool isDark;

  const _ContactCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      isDark: isDark,
      title: 'Liên hệ',
      icon: Icons.support_agent_rounded,
      child: Column(
        children: [
          _ContactRow(
            icon: Icons.phone_outlined,
            label: 'SĐT',
            value: item.contactPhone ?? 'Đang cập nhật',
            isDark: isDark,
          ),
          SizedBox(height: 10),
          _ContactRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: item.contactEmail ?? 'Đang cập nhật',
            isDark: isDark,
          ),
          SizedBox(height: 10),
          _ContactRow(
            icon: Icons.school_outlined,
            label: 'Bậc học',
            value: item.degree ?? 'Đang cập nhật',
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryBlue, size: 18),
        SizedBox(width: 9),
        Text(
          '$label: ',
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.black45,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomButton extends StatelessWidget {
  final Admission item;
  final bool isDark;
  final ValueChanged<String> onOpenRegisterLink;
  final VoidCallback onNoRegisterLink;

  const _BottomButton({
    required this.item,
    required this.isDark,
    required this.onOpenRegisterLink,
    required this.onNoRegisterLink,
  });

  @override
  Widget build(BuildContext context) {
    final canRegister =
        item.registerLink != null && item.registerLink!.trim().isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 18),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF000000) : AppColors.lightBlue,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : Color(0xFFE5EEF8),
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: canRegister
                ? AppColors.primaryBlue
                : Colors.grey.shade400,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          onPressed: canRegister
              ? () => onOpenRegisterLink(item.registerLink!)
              : onNoRegisterLink,
          child: Text(
            canRegister ? 'Đăng ký ngay' : 'Chưa có link đăng ký',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final String label;

  const _StatusBadge({required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (status) {
      case 'open':
        bg = Color(0xFFE8F8EF);
        fg = Color(0xFF16A34A);
        break;
      case 'closed':
        bg = Color(0xFFFFEAEA);
        fg = Color(0xFFEF4444);
        break;
      case 'coming_soon':
      default:
        bg = Color(0xFFFFF4D6);
        fg = Color(0xFFE59F00);
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Container(
          padding: EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF111111) : Colors.white,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: AppColors.primaryBlue,
              ),
              SizedBox(height: 14),
              Text(
                'Không tải được chi tiết',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: Text('Thử lại')),
            ],
          ),
        ),
      ),
    );
  }
}
