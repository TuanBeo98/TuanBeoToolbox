# HƯỚNG DẪN CÀI ĐẶT & SỬ DỤNG BỘ CÔNG CỤ TB-TOOLBOX
> 👤 **TÁC GIẢ & BẢN QUYỀN:** ĐÀO XUÂN TUẤN (MR. TUẤN BEO)  
> 🏷️ **PHIÊN BẢN:** v2.0 Enterprise  
> 📁 **VỊ TRÍ:** `!00-HUONG-DAN-SU-DUNG-CHO-NGUOI-DUNG.md` (nằm tại thư mục gốc TB-Toolbox)

---

## 🌟 GIỚI THIỆU TỔNG QUAN
**TB-Toolbox** là bộ công cụ tiện ích hệ thống cao cấp do Kỹ sư Đào Xuân Tuấn (Tuấn Beo) phát triển, được thiết kế tối ưu hóa chuyên sâu cho hệ điều hành Windows:
- Quét và dọn dẹp sạch sẽ toàn bộ các vùng rác hệ thống (Temp, Prefetch, Windows Update cache, Crash dumps...).
- Thanh tiến trình mượt mà, tốc độ xử lý tức thì dưới 15 giây.
- Cơ chế bảo vệ an toàn 100%: Tuyệt đối không xóa nhầm tài liệu đang soạn thảo, giữ nguyên mật khẩu và lịch sử trình duyệt web.

---

## 🚀 4 BƯỚC SỬ DỤNG DÀNH CHO NGƯỜI DÙNG

### 🔹 BƯỚC 1: GIẢI NÉN VÀO THƯ MỤC CỐ ĐỊNH
- Sau khi tải file `.zip` về máy, hãy bấm chuột phải chọn **Extract All... (Giải nén)** vào một thư mục làm việc cố định trên máy tính (ví dụ: `D:\TB-Toolbox` hoặc `C:\Tools\TB-Toolbox`).
- ⚠️ *Lưu ý quan trọng:* Không chạy trực tiếp công cụ từ bên trong file nén `.zip` mà chưa giải nén.

---

### 🔹 BƯỚC 2: MỞ KHÓA MÔI TRƯỜNG (CHỈ LÀM 1 LẦN ĐẦU TIÊN)
Do tải về từ Internet, Windows thường tự động gắn cờ bảo vệ ngầm (Mark of the Web) khiến các file script bị chặn không chạy được:
1. Mở thư mục **`@File-BAT/`**.
2. Bấm đúp chuột chạy file: **`[000]-Kiem-Tra-Moi-Truong-Va-Giai-Phong-Chan.bat`**.
3. Công cụ sẽ tự động:
   - Gỡ bỏ hoàn toàn cờ chặn tải về (`Unblock-File`).
   - Cấp quyền thực thi an toàn cho PowerShell (`RemoteSigned`).
4. Khi màn hình hiện thông báo **"MÔI TRƯỜNG MÁY TÍNH ĐÃ SẴN SÀNG"**, bạn bấm phím bất kỳ để đóng cửa sổ.

> [!NOTE] **Nếu gặp màn hình xanh "Windows protected your PC" (SmartScreen):**
> Hãy bấm vào dòng chữ gạch chân **`More info` (Xem thêm)** $\rightarrow$ Bấm nút **`Run anyway` (Vẫn chạy)**. Đây là cảnh báo tiêu chuẩn của Windows đối với các tệp script tự viết.

---

### 🔹 BƯỚC 3: KHỞI CHẠY CÁC CHỨC NĂNG TIỆN ÍCH
Vào thư mục **`@File-BAT/`** và lựa chọn công cụ bạn muốn sử dụng:

👉 **Dọn dẹp hệ thống:** Bấm đúp file **`[500]-Don-Dep-Bo-Nho-Tam-He-Thong.bat`**.
- Màn hình Console hiển thị danh sách các hạng mục dọn dẹp có đánh số:
  * Hàng màu **Xanh lá (Green)**: Trạng thái đang **BẬT [1]** (sẽ được dọn dẹp).
  * Hàng màu **Xám mờ (DarkGray)**: Trạng thái đang **TẮT [0]** (sẽ được bỏ qua).
- **Cách bật/tắt nhanh:**
  * Gõ số thứ tự và nhấn Enter (ví dụ: gõ `2` để bật mục Prefetch).
  * Hỗ trợ bật/tắt nhiều mục cùng lúc: gõ `1, 2, 3` hoặc `1 3 5`.
- **Bắt đầu dọn dẹp:** Sau khi chọn xong các mục ưng ý, chỉ cần nhấn phím **`Enter`** (hoặc gõ `Y`).

---

### 🔹 BƯỚC 4: XEM LẠI NHẬT KÝ KẾT QUẢ (LOGS)
- Ngay sau khi dọn dẹp xong, hệ thống xuất bảng báo cáo: Tổng số tệp đã xóa, tổng dung lượng ổ đĩa đã giải phóng (MB/GB).
- **Xem file log tức thì:** Nhấn phím **`[O]`** (Open) để mở ngay file nhật ký chi tiết bằng Notepad.
- **Tra cứu lịch sử:** Toàn bộ nhật ký các lần chạy được lưu trữ khoa học theo từng chức năng tại:
  `Engine/Logs/[TB-01]-Don-Dep-Bo-Nho-Tam/<Tên_Bạn>_<NgàyGiờ>.log`

---

## 🛡️ CAM KẾT AN TOÀN VÀ BẢO VỆ DỮ LIỆU
1. **Rào chắn an toàn 24 giờ cho Temp:** Hệ thống chỉ xóa những tệp rác mồ côi đã tồn tại trên 24 giờ qua. Tuyệt đối không xóa những tệp đính kèm Word/Excel vừa mở trong ngày.
2. **Không mất dữ liệu cá nhân trên trình duyệt:** Chức năng dọn cache trình duyệt chỉ xóa các tệp ảnh/video web tải tạm; giữ nguyên 100% Mật khẩu đã lưu, Cookie đăng nhập và Lịch sử duyệt web.
3. **Tự phục hồi dịch vụ hệ thống:** Luôn đảm bảo dịch vụ Windows Update hoạt động trơn tru sau khi dọn dẹp.
