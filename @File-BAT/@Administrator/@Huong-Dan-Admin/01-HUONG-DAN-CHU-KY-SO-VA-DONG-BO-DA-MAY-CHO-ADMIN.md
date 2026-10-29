# HƯỚNG DẪN CHỮ KÝ SỐ & ĐỒNG BỘ ĐA MÁY DÀNH CHO ADMIN
> ⚠️ **TÀI LIỆU TỐI MẬT QUẢN TRỊ - TUYỆT ĐỐI KHÔNG CUNG CẤP CHO CLIENT**  
> 👤 **BẢN QUYỀN:** ĐÀO XUÂN TUẤN (MR. TUẤN BEO - TECHNICAL CONSULTANT)  
> 📁 **VỊ TRÍ:** `@File-BAT/@Administrator/@Huong-Dan-Admin/01-HUONG-DAN-CHU-KY-SO-VA-DONG-BO-DA-MAY-CHO-ADMIN.md`

---

## 🔑 I. CƠ CHẾ BẢN QUYỀN CHỮ KÝ SỐ MASTER KEY (RSA-2048 & HMAC-SHA256)

Hệ thống bảo vệ bản quyền của Anh Beo hoạt động dựa trên mô hình **Khóa Bất Đối Xứng RSA kết hợp Băm Bảo Mật HMAC-SHA256**:

1. **Khóa Bí Mật Quản Trị (Master Private Key / Master Key):**
   - Nằm tại: `admin-private.rsa` hoặc mật mã lõi `Tuanbeo1998@`.
   - Chỉ có máy của Anh Beo mới nắm giữ khóa này để ký phát hành License Token cho các nhóm người dùng.
2. **Khóa Công Khai (Public Key):**
   - Nằm tại: `tb-public.rsa`.
   - Phân phối kèm bộ cài đặt Client để máy người dùng tự động giải mã và kiểm tra tính toàn vẹn của Token mà không thể tự ý giả mạo quyền hạn.
3. **Mã Token Bất Biến của Admin:**
   ```text
   TBKEY-ACTIVE|TuanBeo|Admin|null|ADMIN|LIFETIME|ALL|2026-10-20|SIG_MASTER_AUTH
   ```

---

## 🌐 II. QUY TẮC "HWID == ALL" (VŨ KHÍ ĐỒNG BỘ ĐA MÁY)

Thông thường, mỗi máy tính người dùng đều có một mã vân tay phần cứng **`HWID`** duy nhất (kết hợp từ Mainboard Serial + CPU ProcessorId + Windows MachineGuid).

### Điểm đặc biệt dành riêng cho Admin Tuấn Beo:
- Trong License Token của Anh Beo, trường phần cứng mang giá trị: **`ALL`** (hoặc nhóm tối cao `GF9999`).
- Mọi script kiểm tra bản quyền (`Activate-License.ps1`, `License-Engine.ps1`) đều có cơ chế ngầm:
  ```powershell
  if ($payload.hwid.ToUpper() -eq "ALL" -or $payload.groupId -eq "GF9999" -or $payload.role -eq "Admin") {
      # BỎ QUA SO KHỚP PHẦN CỨNG 100% -> MỞ KHÓA TOÀN QUYỀN ADMIN TỨC THÌ
  }
  ```
- **Lợi ích thực tế:** Anh Beo có thể mang thư mục dự án đi bất kỳ máy tính nào (máy ở cơ quan, máy tính ở nhà, laptop di động, máy ảo) mà **KHÔNG BAO GIỜ BỊ KHÓA BẢN QUYỀN**.

---

## 🚀 III. QUY TRÌNH KHI LÀM VIỆC TRÊN MÁY TÍNH MỚI HOÀN TOÀN

Khi Anh Beo ngồi vào một máy tính mới, chỉ cần thực hiện 3 bước đơn giản:

### Cách 1: Sử dụng qua GitHub (Khuyên dùng)
1. **Bước 1:** Mở Git và clone kho mã nguồn:
   ```bash
   git clone <URL_REPO_CỦA_ANH_BEO>
   ```
2. **Bước 2 (Chỉ làm 1 lần trên máy mới):**
   Chạy file `[TB-00]-Kiem-Tra-Moi-Truong-Va-Giai-Phong-Chan.bat` để mở khóa chính sách PowerShell.
3. **Bước 3:** Bắt đầu làm việc!
   - Mở AI IDE (Antigravity / Cursor / VSCode) chat bình thường: AI tự nhận diện Profile `TuanBeo` và Token `ALL`.
   - Khởi chạy các công cụ Admin tại `@File-BAT/@Administrator/` mà không cần nhập lại bất kỳ Key nào.

### Cách 2: Sử dụng qua USB / Ổ Cứng Di Động (Offline)
1. Copy nguyên vẹn thư mục `AI` hoặc `TB-Toolbox` vào USB.
2. Cắm vào máy tính mới.
3. Bấm đúp chạy thẳng các file kịch bản trong `@File-BAT/@Administrator/`. Hệ thống nhận diện Master Session và cấp toàn quyền tức thì.

---

## 🔄 IV. HƯỚNG DẪN TẠO LẠI / GIA HẠN TOKEN ADMIN NẾU BỊ MẤT
Nếu vô tình làm mất file cấu hình hoặc muốn cấp lại Token Admin cho chính mình:
1. Vào thư mục `@File-BAT/@Administrator/`.
2. Bấm chạy: **`[ADMIN-201]-Quan-Ly-Va-Tao-Key.bat`**.
3. Chọn tính năng **Tạo Key mới**:
   - Tên người dùng: `TuanBeo`
   - Nhóm quyền: Chọn nhóm `Admin` (`GF9999`)
   - Khóa phần cứng (HWID): Nhập chữ **`ALL`**
   - Hạn dùng: Chọn **Vĩnh viễn (LIFETIME)**
4. Copy chuỗi Token tạo ra và lưu vào trường `Mã License Token hiện hành` trong `user-profile.md`.
