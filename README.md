# 🧰 TB-Toolbox (TuanBeoToolbox)
> 🚀 **Hệ thống tiện ích, dọn dẹp và tinh chỉnh Windows toàn diện (All-in-One Windows Utility & Tweaks)**  
> 👤 **Tác giả:** Đào Xuân Tuấn (Mr. Tuấn Beo)  
> 🏢 **Tổ chức:** Công ty Cổ phần Giải pháp Giáo dục ASC  
> 🌐 **Kho mã nguồn GitHub:** `TuanBeoToolbox`  

---

## 📌 GIỚI THIỆU DỰ ÁN

**TB-Toolbox** là bộ công cụ mã nguồn mở được phát triển nhằm tự động hóa quá trình bảo trì, tối ưu hóa hiệu năng và cung cấp các tiện ích hệ thống nhanh chóng cho người dùng Windows và kỹ sư phần mềm. 

Bộ công cụ được thiết kế theo triết lý:
1. 🛡️ **An toàn tuyệt đối (Safety First):** Không xóa ngầm, luôn có màn hình tóm tắt xác nhận trước khi thực hiện, cho phép quay lại hoặc hủy bỏ ở mọi bước.
2. ⚡ **Mượt mà & Trực quan (Modern Console UI):** Thanh tiến trình hiển thị mượt mà không nhấp nháy (Zero-Flicker), nhảy số dung lượng giải phóng theo thời gian thực.
3. 📝 **Nhật ký minh bạch (Audit Trail):** Tự động ghi chép toàn bộ tiến trình dọn dẹp vào tệp Log UTF-8 có BOM để kiểm tra đối soát.
4. 🔌 **Plug & Play:** Không cần cài đặt rườm rà, tải từ GitHub về là chạy được ngay qua các phím tắt 1-Click.

---

## 🧹 CHỨC NĂNG 1: DỌN DẸP BỘ NHỚ TẠM (TB-CLEANER)

### 📋 Danh mục các hạng mục hỗ trợ:
| STT | Hạng mục | Mặc định | Mô tả |
| :---: | :--- | :---: | :--- |
| **1** | **Xóa bộ nhớ tạm (User & System Temp)** | **[1] BẬT** | Dọn dẹp `%TEMP%` và `C:\Windows\Temp`. Tự động bỏ qua an toàn các tệp đang được ứng dụng sử dụng. |
| **2** | **Xóa bộ nhớ đệm Prefetch** | [0] TẮT | Dọn dẹp `C:\Windows\Prefetch` (Yêu cầu quyền Administrator). |
| **3** | **Xóa tệp tải Windows Update cũ** | [0] TẮT | Tạm dừng service cập nhật an toàn, xóa cache tải về tại `SoftwareDistribution\Download` và CBS Logs. |
| **4** | **Xóa file báo cáo sự cố sập ứng dụng (Crash Dumps)** | [0] TẮT | Giải phóng các file dump dung lượng lớn tại `%LOCALAPPDATA%\CrashDumps` và `Minidump`. |
| **5** | **Xóa cache tối ưu tải Windows Store (Delivery)** | [0] TẮT | Dọn dẹp `SoftwareDistribution\DeliveryOptimization`. |
| **6** | **Xóa bộ nhớ đệm ảnh thu nhỏ (Thumbnails)** | [0] TẮT | Dọn cache icon `thumbcache_*.db` của Windows Explorer. |
| **7** | **Dọn sạch Thùng rác (Recycle Bin)** | [0] TẮT | Làm rỗng Thùng rác vĩnh viễn trên tất cả các ổ đĩa. |
| **8** | **Xóa cache trình duyệt (Chrome, Edge)** | [0] TẮT | Chỉ dọn bộ nhớ đệm web tĩnh, **bảo toàn 100% Mật khẩu, Cookie và Lịch sử**. |
| **9** | **Xóa cache thư viện .NET (NuGet Packages)** | [0] TẮT | Dọn dẹp thư mục `%userprofile%\.nuget\packages` cho lập trình viên. |

---

## 🚀 HƯỚNG DẪN SỬ DỤNG (HOÀN TOÀN KHÔNG CẦN CÀI ĐẶT THÊM GÌ)

Bộ công cụ được đóng gói độc lập (Zero-Dependency), sử dụng 100% công cụ có sẵn nguyên bản của Windows. Người dùng **KHÔNG CẦN CÀI GIT**, không cần cài Python hay Node.js.

### 📥 1. Tải về máy:
- **Cách 1 (Đơn giản nhất cho mọi máy tính - Không cần Git):**
  1. Trên trang GitHub `TuanBeoToolbox`, bấm vào nút màu xanh **Code** ➔ Chọn **Download ZIP**.
  2. Chuột phải vào file vừa tải về ➔ Chọn **Extract All... (Giải nén)** ra bất kỳ thư mục nào (Desktop, ổ D:, ổ C:...).
- **Cách 2 (Dành cho lập trình viên có sẵn Git):**
  ```cmd
  git clone https://github.com/TuanBeo/TuanBeoToolbox.git
  ```

### ⚡ 2. Khởi chạy 1-Click:
- Mở thư mục vừa giải nén, vào thư mục **`@File-BAT/`**.
- Nhấp đúp chuột vào file:  
  👉 **`[01]-Don-Dep-Bo-Nho-Tam-He-Thong.bat`**  
  *(Mẹo: Nếu muốn dọn cả mục Prefetch hoặc Windows Update, hãy chuột phải chọn **Run as administrator**).*
3. **Thao tác trên Menu:**
   - Nhập phím số `1` .. `9` để Bật/Tắt hạng mục tương ứng.
   - Nhập `A` để Chọn tất cả (Select All).
   - Nhập `C` để Hủy tất cả (Clear All).
   - Nhấn `Enter` hoặc `S` để chuyển sang màn hình xác nhận.
   - Tại màn hình xác nhận: Nhấn `Y` (Đồng ý dọn dẹp), `B` (Quay lại chỉnh sửa), hoặc `Q` (Hủy bỏ và thoát).

---

## 🗺️ LỘ TRÌNH PHÁT TRIỂN TIẾP THEO (ROADMAP)

- [x] **V1.0:** Hệ thống dọn dẹp bộ nhớ tạm & tối ưu Windows (TB-Cleaner).
- [ ] **V1.1:** Tiện ích Hẹn giờ tắt máy / Khởi động lại / Hủy hẹn giờ (Shutdown Scheduler).
- [ ] **V1.2:** Tiện ích Đổi mật khẩu tài khoản Windows cục bộ an toàn.
- [ ] **V1.3:** Tiện ích Đổi tên máy tính (Rename PC) có cảnh báo Domain/SQL Server.
- [ ] **V1.4:** Quản lý ứng dụng khởi động cùng Windows (Startup Manager) qua Task Scheduler.
- [ ] **V1.5:** Tinh chỉnh định dạng ngày (`dd/MM/yyyy`) và giờ (`HH:mm:ss`) đồng bộ toàn hệ thống.

---

## ⚖️ BẢN QUYỀN & GIẤY PHÉP

Dự án được phát hành dưới giấy phép mã nguồn mở **MIT License**. Mọi cá nhân và tổ chức đều có thể sử dụng và đóng góp phát triển.
Bản quyền © 2026 thuộc về **Mr. Tuấn Beo (Đào Xuân Tuấn)**.
