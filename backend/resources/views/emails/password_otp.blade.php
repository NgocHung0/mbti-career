<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <title>Mã OTP đổi mật khẩu NAVI</title>
</head>
<body style="margin:0;padding:0;background:#eef6ff;font-family:Arial,sans-serif;color:#17384a;">
  <div style="max-width:680px;margin:0 auto;padding:28px 14px;">
    <div style="background:#ffffff;border-radius:24px;overflow:hidden;box-shadow:0 14px 40px rgba(23,57,76,.12);">

      <div style="padding:32px 24px;text-align:center;background:linear-gradient(135deg,#f8fcff,#eaf5ff);">
        <img src="{{ $message->embed(public_path('images/Logonew.png')) }}" alt="NAVI" style="width:90px;height:90px;border-radius:50%;object-fit:cover;margin-bottom:12px;">

        <h1 style="margin:0;color:#1d6fe8;font-size:34px;letter-spacing:3px;">NAVI</h1>
        <p style="margin:6px 0 0;color:#5d7687;font-size:15px;">Định hướng nghề nghiệp</p>
      </div>

      <div style="padding:34px 28px;text-align:center;">
        <h2 style="margin:0 0 12px;font-size:28px;color:#102a56;">
          Mã OTP đổi mật khẩu
        </h2>

        <p style="margin:0 0 24px;color:#5d7687;font-size:16px;line-height:1.7;">
          Bạn vừa yêu cầu đổi mật khẩu cho tài khoản NAVI.
          Vui lòng nhập mã OTP bên dưới để xác nhận.
        </p>

        <div style="background:#f8fbff;border:1px solid #dceaf8;border-radius:22px;padding:26px 18px;margin:0 auto 22px;">
          <p style="margin:0 0 16px;color:#1d6fe8;font-weight:bold;font-size:15px;letter-spacing:1px;">
            MÃ OTP CỦA BẠN LÀ
          </p>

          <div style="font-size:42px;font-weight:900;letter-spacing:12px;color:#1d6fe8;background:#ffffff;border:1px solid #d8e8ff;border-radius:18px;padding:18px 12px;">
            {{ $otp }}
          </div>

          <div style="margin-top:18px;background:#fff7e6;border:1px solid #ffd58a;border-radius:14px;padding:12px;color:#9a5a00;font-weight:bold;">
            Mã có hiệu lực trong 5 phút
          </div>
        </div>

        <p style="margin:0;color:#6a7f91;font-size:14px;line-height:1.7;">
          Nếu bạn không thực hiện yêu cầu này, vui lòng bỏ qua email.
          Không chia sẻ mã OTP này cho bất kỳ ai.
        </p>
      </div>

      <div style="padding:24px;background:linear-gradient(135deg,#2498f2,#135fe6);color:#ffffff;text-align:center;">
        <h3 style="margin:0 0 6px;font-size:22px;">NAVI</h3>
        <p style="margin:0;font-size:14px;opacity:.9;">Hệ thống tư vấn ngành nghề dựa vào tính cách cá nhân</p>
        <p style="margin:16px 0 0;font-size:12px;opacity:.85;">© 2026 NAVI. Email này được gửi tự động.</p>
      </div>

    </div>
  </div>
</body>
</html>