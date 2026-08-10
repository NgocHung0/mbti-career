import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../services/payment_service.dart';

class PaymentQrScreen extends StatefulWidget {
  final int packageId;
  final String packageName;
  final int amount;

  const PaymentQrScreen({
    super.key,
    required this.packageId,
    required this.packageName,
    required this.amount,
  });

  @override
  State<PaymentQrScreen> createState() => _PaymentQrScreenState();
}

class _PaymentQrScreenState extends State<PaymentQrScreen> {
  bool loading = true;
  bool checking = false;
  String error = '';

  Map<String, dynamic>? payment;
  Timer? timer;

  int? get orderCode {
    final raw = payment?['order_code'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '');
  }

  String get qrCode {
    return payment?['qr_code']?.toString() ??
        payment?['qrCode']?.toString() ??
        payment?['qr']?.toString() ??
        '';
  }

  String get checkoutUrl {
    return payment?['checkout_url']?.toString() ??
        payment?['checkoutUrl']?.toString() ??
        '';
  }

  @override
  void initState() {
    super.initState();
    createPayment();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> createPayment() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final data = await PaymentService.createMbtiPayment(
        packageId: widget.packageId,
      );

      print('PAYMENT DATA = $data');

      if (!mounted) return;

      setState(() {
        payment = data;
        loading = false;
      });

      startPolling();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void startPolling() {
    timer?.cancel();

    timer = Timer.periodic(Duration(seconds: 4), (_) {
      checkStatus(silent: true);
    });
  }

  Future<void> checkStatus({bool silent = false}) async {
    final code = orderCode;
    if (code == null) return;

    if (!silent) {
      setState(() {
        checking = true;
      });
    }

    try {
      final data = await PaymentService.getMbtiPaymentStatus(orderCode: code);

      final status = data['status']?.toString().toUpperCase() ?? '';
      final isPaid =
          data['is_paid'] == true ||
          status == 'PAID' ||
          status == 'SUCCESS' ||
          status == 'COMPLETED';

      if (isPaid) {
        timer?.cancel();

        if (!mounted) return;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: Text('Thanh toán thành công'),
            content: Text(
              'Gói ${widget.packageName} đã được kích hoạt cho tài khoản của bạn.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                child: Text('Hoàn tất'),
              ),
            ],
          ),
        );
      }
    } catch (_) {
      // Không hiện lỗi liên tục khi polling.
    } finally {
      if (mounted && !silent) {
        setState(() {
          checking = false;
        });
      }
    }
  }

  Future<void> openCheckout() async {
    final url = checkoutUrl.isNotEmpty ? checkoutUrl : qrCode;
    if (url.isEmpty) return;

    final uri = Uri.parse(url);

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String formatMoney(int value) {
    final text = value.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final indexFromEnd = text.length - i;

      buffer.write(text[i]);

      if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
        buffer.write('.');
      }
    }

    return '${buffer}đ';
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? Color(0xFF000000) : AppColors.lightBlue;
    final card = dark ? Color(0xFF111111) : Colors.white;
    final title = dark ? Color(0xFFEAF6FF) : AppColors.textDark;
    final sub = dark ? Color(0xFF94A3B8) : AppColors.textGrey;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        foregroundColor: AppColors.title(context),
        elevation: 0,
        iconTheme: IconThemeData(color: title),
        title: Text(
          'Thanh toán PayOS',
          style: TextStyle(color: title, fontWeight: FontWeight.w900),
        ),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : error.isNotEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: title),
                ),
              ),
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: qrCode.isNotEmpty
                            ? QrImageView(
                                data: qrCode,
                                version: QrVersions.auto,
                                size: 220,
                                backgroundColor: Colors.white,
                              )
                            : Icon(
                                Icons.qr_code_2_rounded,
                                size: 72,
                                color: AppColors.primaryBlue,
                              ),
                      ),
                      SizedBox(height: 14),
                      Text(
                        widget.packageName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: title,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        formatMoney(widget.amount),
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Quét mã QR bằng ứng dụng ngân hàng để thanh toán.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: sub, height: 1.45),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
