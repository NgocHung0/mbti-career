import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/package_service.dart';
import 'payment_qr_screen.dart';

class PackagesScreen extends StatefulWidget {
  final bool premiumOnly;

  const PackagesScreen({super.key, this.premiumOnly = false});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  String selectedPackage = 'premium';
  bool loadingPackage = true;
  Map<String, dynamic>? currentPackage;

  bool get isPremium => PackageService.isPremium(currentPackage);
  bool get isPlus => PackageService.isPlus(currentPackage);

  @override
  void initState() {
    super.initState();
    loadCurrentPackage();
  }

  Future<void> loadCurrentPackage() async {
    final package = await PackageService.getCurrentPackage();

    if (!mounted) return;

    setState(() {
      currentPackage = package;
      loadingPackage = false;
    });
  }

  List<Map<String, dynamic>> get packages {
    final all = [
      {
        'id': 3,
        'name': 'Premium',
        'price': 39000,
        'desc': 'Mở khóa bài test nâng cao, khóa học và phân tích đầy đủ.',
        'color': Color(0xFF9B7BEA),
      },
      {
        'id': 2,
        'name': 'Plus',
        'price': 19000,
        'desc': 'Mở khóa bài test sở thích và kết quả phân tích nâng cao.',
        'color': Color(0xFF45C58A),
      },
    ];

    if (widget.premiumOnly) {
      return [all.first];
    }

    return all;
  }

  bool packageAlreadyOwned(String name) {
    final lower = name.toLowerCase();

    if (isPremium) return true;

    if (isPlus && lower == 'plus') return true;

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Color(0xFF000000) : AppColors.lightBlue;
    final card = isDark ? Color(0xFF111111) : Colors.white;
    final title = isDark ? Color(0xFFEAF6FF) : AppColors.textDark;
    final sub = isDark ? Color(0xFF94A3B8) : AppColors.textGrey;

    if (loadingPackage) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final selected = packages.firstWhere(
      (item) => item['name'].toString().toLowerCase() == selectedPackage,
    );

    final selectedName = selected['name'].toString();
    final selectedOwned = packageAlreadyOwned(selectedName);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        foregroundColor: AppColors.title(context),
        elevation: 0,
        iconTheme: IconThemeData(color: title),
        title: Text(
          'Nâng cấp tài khoản',
          style: TextStyle(color: title, fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Container(
            padding: EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPremium ? 'Tài khoản đã mở khóa' : 'Chọn gói phù hợp',
                  style: TextStyle(
                    color: title,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  isPremium
                      ? 'Bạn đang dùng Premium nên đã mở khóa toàn bộ bài test nâng cao, khóa học và nội dung định hướng chuyên sâu.'
                      : 'Nâng cấp để mở khóa bài test nâng cao, khóa học và nội dung định hướng chuyên sâu.',
                  style: TextStyle(color: sub, height: 1.45),
                ),
              ],
            ),
          ),
          SizedBox(height: 18),

          ...packages.map((item) {
            final name = item['name'].toString();
            final isSelected = selectedPackage == name.toLowerCase();
            final color = item['color'] as Color;
            final owned = packageAlreadyOwned(name);

            return InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: owned
                  ? null
                  : () {
                      setState(() {
                        selectedPackage = name.toLowerCase();
                      });
                    },
              child: Container(
                margin: EdgeInsets.only(bottom: 14),
                padding: EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Row(
                  children: [
                    Icon(
                      owned
                          ? Icons.check_circle_rounded
                          : isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: owned
                          ? Colors.green
                          : isSelected
                          ? color
                          : sub,
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              color: title,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            owned
                                ? 'Gói này đã được kích hoạt.'
                                : item['desc'].toString(),
                            style: TextStyle(color: sub, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      owned ? 'Đã mở' : '${item['price']}đ',
                      style: TextStyle(
                        color: owned ? Colors.green : color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          SizedBox(height: 12),

          if (selectedOwned)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Text(
                'Tài khoản của bạn đã được mở khóa. Bạn không cần thanh toán lại.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          else
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  final paid = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentQrScreen(
                        packageId: selected['id'] as int,
                        packageName: selected['name'].toString(),
                        amount: selected['price'] as int,
                      ),
                    ),
                  );

                  if (paid == true && context.mounted) {
                    Navigator.pop(context, true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: selected['color'] as Color,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  'Thanh toán bằng PayOS',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
