# Hệ sinh thái Nhà Thông minh (ESP32 + Flutter + Python)

Hệ sinh thái IoT toàn diện cho tự động hóa gia đình, điều khiển khí hậu và giám sát năng lượng. Bao gồm backend ESP32-S3 dạng mô-đun, ứng dụng di động Flutter phản hồi nhanh và máy chủ tiện ích dựa trên Python.

## 🚀 Tính năng chính
- **Điều khiển Khí hậu**: Điều khiển điều hòa Daikin IR với phản hồi từ cảm biến DHT22 và logic Tự động ngủ (Auto-Sleep).
- **Phân tích Năng lượng**: Tích hợp PZEM-004T để theo dõi thông số điện năng thời gian thực, tính toán chi phí và lưu nhật ký CSV hàng tháng.
- **Quản lý Relay**: Điều khiển 6 kênh relay với bộ nhớ NVS để khôi phục trạng thái sau khi mất điện.
- **Điều khiển PC**: Bật máy tính từ xa (WOL) và Tắt máy thông qua API Python.
- **Giám sát Hệ thống**: Node "Health" để theo dõi trạng thái thiết bị và kết nối của điện thoại/PC (Ping).
- **Giao diện Đa nền tảng**: Ứng dụng Flutter (Android/Web) đồng bộ hóa thời gian thực với Firebase RTDB.

## 🛠️ Công nghệ sử dụng
- **Firmware**: C++ (Arduino/PlatformIO) trên ESP32-S3.
- **Frontend**: Flutter (Dart) sử dụng `firebase_database`.
- **Backend/Server**: Python (Flask/FastAPI) để cập nhật giá điện và điều khiển PC.
- **Lớp đồng bộ**: Firebase Realtime Database.

## 📦 Cấu trúc dự án
```text
.
├── src/                # Mã nguồn ESP32 (Các bộ điều khiển mô-đun)
├── flutter_app/        # Ứng dụng di động/Web Flutter
├── scripts/            # Script Python Server & Tiện ích
├── data/               # Tài nguyên giao diện Web
└── .env.example        # Tệp mẫu cấu hình môi trường
```

## ⚙️ Cài đặt & Triển khai

### 1. Cấu hình Môi trường
Sao chép `.env.example` thành ` .env` (lưu ý có dấu cách ở đầu để các script Python cục bộ nhận diện) và điền thông tin xác thực của bạn:
```bash
cp .env.example " .env"
```

### 2. Firmware ESP32 (PlatformIO)
Yêu cầu: Đã cài đặt [PlatformIO CLI](https://platformio.org/install/cli).
Thực hiện quy trình build bảo mật:
```bash
# 1. Giải mã các bí mật cho trình biên dịch
python3 scripts/unredact_code.py

# 2. Build và Nạp code (OTA mặc định)
pio run -t upload

# 3. Mã hóa lại các bí mật sau khi nạp xong
python3 scripts/redact_code.py
```

### 3. Ứng dụng Flutter
Yêu cầu: [Flutter SDK](https://docs.flutter.dev/get-started/install).
```bash
cd flutter_app
flutter pub get
flutter run -d <id_thiet_bi>
```

### 4. Python Server (Cập nhật giá & Điều khiển PC)
Yêu cầu các thư viện: `flask`, `requests`, `beautifulsoup4`, `easyocr`, `pillow`, `numpy`.
```bash
# Cài đặt phụ thuộc
pip install flask requests beautifulsoup4 easyocr pillow numpy

# Chạy server cục bộ
python3 scripts/home_server.py

# (Tùy chọn) Chạy script cập nhật giá điện tự động
python3 scripts/fetch_price_v2.py
```

## 🛡️ Bảo mật
Kho lưu trữ này sử dụng quy trình **Mã hóa-Build-Giải mã** để ngăn chặn việc vô tình lộ API key, thông tin WiFi và địa chỉ IP trong mã nguồn trong khi vẫn cho phép build PlatformIO liền mạch.

## 📜 Giấy phép
Dự án Cá nhân - Mọi quyền được bảo lưu.
