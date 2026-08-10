import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/admission.dart';
import '../../services/admission_service.dart';
import 'admission_detail_screen.dart';
import '../../services/auth_service.dart';
import '../../core/widgets/top_header.dart';

class AdmissionsScreen extends StatefulWidget {
  final String? initialSchool;
  final String? initialMajor;
  final bool autoOpen;

  const AdmissionsScreen({
    super.key,
    this.initialSchool,
    this.initialMajor,
    this.autoOpen = false,
  });

  @override
  State<AdmissionsScreen> createState() => _AdmissionsScreenState();
}

class _AdmissionsScreenState extends State<AdmissionsScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  String _selectedStatus = 'all';
  List<Admission> _items = [];

  final List<Map<String, String>> _filters = [
    {'value': 'all', 'label': 'Tất cả'},
    {'value': 'open', 'label': 'Đang mở'},
    {'value': 'coming_soon', 'label': 'Sắp mở'},
    {'value': 'closed', 'label': 'Đã đóng'},
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
    _loadAdmissions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAdmissions() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await AdmissionService.getAdmissions();

      if (!mounted) return;

      setState(() {
        _items = data;
        _loading = false;
      });

      if (widget.autoOpen &&
          widget.initialSchool != null &&
          widget.initialMajor != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openSelectedAdmission();
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  String _normalizeText(String value) {
    return value.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  void _openSelectedAdmission() {
    final school = _normalizeText(widget.initialSchool ?? '');
    final major = _normalizeText(widget.initialMajor ?? '');

    if (school.isEmpty && major.isEmpty) return;

    Admission? admission;

    for (final item in _items) {
      final itemSchool = _normalizeText(item.schoolName);
      final itemMajor = _normalizeText(item.majorName);

      final matchSchool =
          school.isEmpty ||
          itemSchool.contains(school) ||
          school.contains(itemSchool);

      final matchMajor =
          major.isEmpty ||
          itemMajor.contains(major) ||
          major.contains(itemMajor);

      if (matchSchool && matchMajor) {
        admission = item;
        break;
      }
    }

    admission ??= _items.cast<Admission?>().firstWhere((item) {
      if (item == null) return false;

      final itemSchool = _normalizeText(item.schoolName);
      final itemMajor = _normalizeText(item.majorName);

      return (school.isNotEmpty && itemSchool.contains(school)) ||
          (major.isNotEmpty && itemMajor.contains(major));
    }, orElse: () => null);

    if (admission == null) return;

    _selectedStatus = 'all';
    _searchController.text = '${admission.schoolName} ${admission.majorName}';

    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _openDetail(admission!);
    });
  }

  List<Admission> get _filteredItems {
    final keyword = _searchController.text;

    return _items.where((item) {
      final matchKeyword = item.matchesKeyword(keyword);
      final matchStatus =
          _selectedStatus == 'all' || item.status == _selectedStatus;

      return matchKeyword && matchStatus;
    }).toList();
  }

  void _openDetail(Admission item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdmissionDetailScreen(admissionId: item.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF000000) : AppColors.lightBlue,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAdmissions,
          child: CustomScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isDark),
                      SizedBox(height: 18),
                      _buildSearchBox(isDark),
                      SizedBox(height: 14),
                      _buildFilters(isDark),
                    ],
                  ),
                ),
              ),
              _buildContent(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return TopHeader(
      title: 'Thông tin tuyển sinh',
      subtitle: 'Khám phá các chương trình tuyển sinh mới nhất.',
      image:
          '${AuthService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '')}/images/emoji2/Admission.png',
    );
  }

  Widget _buildSearchBox(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF111111) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.04),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.textDark,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          hintText: 'Tìm trường, ngành, thành phố, học phí...',
          hintStyle: TextStyle(
            color: isDark
                ? Colors.white38
                : Colors.black.withValues(alpha: 0.35),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark
                ? Colors.white54
                : Colors.black.withValues(alpha: 0.35),
          ),
          suffixIcon: _searchController.text.trim().isEmpty
              ? null
              : IconButton(
                  onPressed: () => _searchController.clear(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildFilters(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          final selected = _selectedStatus == filter['value'];

          return Padding(
            padding: EdgeInsets.only(right: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                setState(() {
                  _selectedStatus = filter['value']!;
                });
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primaryBlue
                      : isDark
                      ? Color(0xFF111111)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Text(
                  filter['label']!,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : isDark
                        ? Colors.white70
                        : AppColors.textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_loading) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _StateMessage(
          icon: Icons.wifi_off_rounded,
          title: 'Không tải được dữ liệu',
          message: _error!,
          buttonText: 'Thử lại',
          onPressed: _loadAdmissions,
        ),
      );
    }

    final items = _filteredItems;

    if (items.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _StateMessage(
          icon: Icons.search_off_rounded,
          title: 'Không tìm thấy tuyển sinh',
          message: 'Thử đổi từ khóa tìm kiếm hoặc chọn bộ lọc khác.',
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
      sliver: SliverList.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(height: 14),
        itemBuilder: (context, index) {
          return _AdmissionCard(
            item: items[index],
            isDark: isDark,
            onTap: () => _openDetail(items[index]),
          );
        },
      ),
    );
  }
}

class _AdmissionCard extends StatelessWidget {
  final Admission item;
  final bool isDark;
  final VoidCallback onTap;

  const _AdmissionCard({
    required this.item,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = AdmissionService.resolveImageUrl(item.imageUrl);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 2),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.border(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
              blurRadius: 22,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                _LogoBox(
                  imageUrl: imageUrl,
                  fallbackText: _initials(item.schoolName),
                ),
                SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _StatusBadge(
                            status: item.status,
                            label: item.statusLabel,
                          ),
                          if (item.featured) ...[
                            SizedBox(width: 6),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFFFFF1C7),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'HOT',
                                style: TextStyle(
                                  color: Color(0xFFD97706),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 8),

                      Text(
                        item.schoolName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black45,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      SizedBox(height: 4),

                      Text(
                        item.majorName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.textDark,
                          fontSize: 20,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 8),

                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.primaryBlue,
                    size: 15,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.location_on_outlined,
                  value: item.city ?? 'Đang cập nhật',
                  isDark: isDark,
                ),
                _InfoChip(
                  icon: Icons.payments_outlined,
                  value: item.tuitionFee ?? 'Đang cập nhật',
                  isDark: isDark,
                ),
                _InfoChip(
                  icon: Icons.event_available_outlined,
                  value: item.applicationDeadline ?? 'Đang cập nhật',
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ),
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

class _LogoBox extends StatelessWidget {
  final String? imageUrl;
  final String fallbackText;

  const _LogoBox({required this.imageUrl, required this.fallbackText});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl == null
          ? Center(
              child: Text(
                fallbackText,
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontSize: 21,
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
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool isDark;

  const _InfoChip({
    required this.icon,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 170),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primaryBlue),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? Colors.white70 : AppColors.textDark,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
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
      padding: EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onPressed;

  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.buttonText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF111111) : Colors.white,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 46, color: AppColors.primaryBlue),
              SizedBox(height: 14),
              Text(
                title,
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
              if (buttonText != null && onPressed != null) ...[
                SizedBox(height: 16),
                ElevatedButton(onPressed: onPressed, child: Text(buttonText!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
