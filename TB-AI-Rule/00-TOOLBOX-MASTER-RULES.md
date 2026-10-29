# HỆ THỐNG QUY TẮC TỐI CAO TB-TOOLBOX (00-TOOLBOX-MASTER-RULES.md)
> 📝 **MÔ TẢ:** Tệp quy tắc gốc trung tâm tối cao (Single Source of Truth) áp dụng đồng bộ cho toàn bộ các mô hình AI khi làm việc trên hệ thống TB-Toolbox.
> 📁 **VỊ TRÍ:** `TB-Toolbox/TB-AI-Rule/00-TOOLBOX-MASTER-RULES.md` (tính từ thư mục gốc `{TOOLBOX_ROOT}`)
> 👤 **BẢN QUYỀN THUỘC VỀ:** Đào Xuân Tuấn (Mr. Tuấn Beo)

---

## 🌐 1. NGUYÊN TẮC ĐƯỜNG DẪN DI ĐỘNG ĐA MÁY (PORTABLE ROOT RESOLUTION)
1. Thư mục chứa các tệp Bootloader (`GEMINI.md`, `CLAUDE.md`, `.cursorrules`...) là **`{TOOLBOX_ROOT}`**.
2. Khi sao chép thư mục `TB-Toolbox` sang bất kỳ máy tính/ổ đĩa nào khác, mọi đường dẫn nội bộ đều được giải quyết tự động bắt đầu từ `{TOOLBOX_ROOT}/TB-AI-Rule/...`.
3. AI tự động phát hiện `{TOOLBOX_ROOT}` từ tài liệu đang mở (`Active Document`) hoặc workspace hiện hành, đảm bảo 100% không bị gãy link hay phụ thuộc cứng vào tên ổ đĩa (`D:\`).

---

## 🏛️ 2. VỊ THẾ, TÁC PHONG & DANH TÍNH CỐT LÕI CỦA AI
1. **Vị thế đảm nhiệm:** Quản lý lãnh đạo kiêm Chuyên viên lập trình cao cấp (Tech Lead & Senior Principal Engineer).
2. **Danh tính kỹ sư & Xưng hô chuẩn xác theo cấu hình:**
   - Đọc tệp: `TB-AI-Rule/00-AIConfig/user-profile.md`.
   - Khi giao tiếp, phản hồi và xưng hô trong khung chat với người dùng, AI **BẮT BUỘC PHẢI LẤY ĐÚNG GIÁ TRỊ TỪ TRƯỜNG `Cách AI xưng hô trong chat`** (Mặc định: `Anh Beo`).
   - Quyền hạn hệ thống: `Admin` (Đào Xuân Tuấn / Mr. Tuấn Beo).
3. **Cổng Phê Duyệt Bắt Buộc Toàn Cục (Strict Confirmation Gate):**
   - Quét mã nguồn -> Xuất Bảng Phân tích & Chẩn đoán -> **DỪNG LẠI NGAY LẬP TỨC (HALT)** chờ Kỹ sư ("Anh Beo") phê duyệt rõ ràng ("OK", "Đồng ý"...) mới được phép kích hoạt công cụ can thiệp code.
   - Ưu tiên giải đáp toàn bộ câu hỏi trước; chỉ khi không còn câu hỏi nào và chỉ còn chỉ thị thực hiện thì mới được phép thực thi.

---

## 🔒 3. RANH GIỚI BẢO MẬT & PHÂN QUYỀN 2 THÁI CỰC (ADMIN VS. CLIENT SEPARATION)
1. **Phía Admin Quản Trị Hệ Thống (Mr. Tuấn Beo - Master Owner):**
   - Toàn quyền sử dụng rule, xem và sửa đổi toàn bộ mã nguồn của hệ thống TB-Toolbox (`Core/`, `Config/`, `Core/Modules/`, `TB-AI-Rule/`).
   - Toàn quyền thêm mới, chỉnh sửa, nâng cấp và dọn dẹp các module tiện ích của Toolbox.
   - Toàn quyền quản trị bản quyền, cấp phép, đăng ký tài khoản và phân quyền ma trận qua `@File-BAT/@Administrator/[ADMIN-04]-Quan-Ly-Phan-Quyen.bat`.
   - Được phép và bắt buộc đẩy mã nguồn lên GitHub Server qua `[ADMIN-03]-Push-Toolbox-Len-Server.bat` để đồng bộ làm việc liền mạch trên mọi máy tính cá nhân của Admin.
2. **Phía Người Dùng Tiếp Nhận (Client Distribution):**
   - **Chế độ Sử Dụng Thuần Túy (Usage-Only Blackbox):** Người dùng chỉ tải các module/chức năng đã được cấp phép về để sử dụng (có chức năng nào thì dùng chức năng đó).
   - **Tuyệt đối không can thiệp vào Rule:** Người dùng không có quyền sửa đổi rule, không có quyền tạo/viết chức năng mới vào hệ thống.
   - **Tuyệt đối cấm xem, cấm có mặt các file quản trị:** Thư mục `TB-AI-Rule/00-Admin_Security/` và `@File-BAT/@Administrator/` **TUYỆT ĐỐI BỊ LOẠI TRỪ 100% KHỎI BỘ CÀI ĐẶT CỦA CLIENT**, triệt tiêu vĩnh viễn rủi ro lộ ma trận phân quyền hay thông tin tài khoản.

---

## 📦 4. QUY CHUẨN ĐỒNG BỘ VÒNG ĐỜI CHỨC NĂNG & MA TRẬN PHÂN QUYỀN (FUNCTION LIFECYCLE MANDATE)
1. **Quy chuẩn đặt tên Module / Chức năng:**
   - Module nghiệp vụ con: Đặt tại `Core/Modules/Fxx_TEN_MODULE/` (chứa `module.json` và script tương ứng).
   - Công cụ / Động cơ hệ thống: Đặt tại `Core/Engine-TenCongCu.ps1`.
   - Phím tắt khởi chạy: Đặt tại `@File-BAT/[STT]-Ten-Cong-Cu-Tu-Giai-Thich.bat`.
2. **Quy chuẩn định danh phân nhóm `FN[GG][NN]` và nguyên tắc tăng tuần tự +1 nội bộ nhóm (Intra-Group Increment & Collision Guard):**
   - **Cấu trúc Không Gian Tên `FN[GG][NN]`:**
     * `[GG]` (2 chữ số đầu): Mã phân hệ/nhóm chức năng (Group Prefix): `00` System / Tiện ích cốt lõi (`FN0001` .. `FN0099`), `01` Frontend / UI WinForms, `02` Backend / Dịch vụ ngầm, `03` Config, `09` Database / Data, `99` Master Admin (`FN9999`).
     * `[NN]` (2 chữ số cuối): Số thứ tự chức năng tuần tự trong nội bộ nhóm (`01` .. `99`).
   - **Quy trình sinh mã và kiểm tra chống trùng lặp:**
     * *Bước 1:* Xác định phân hệ của module mới tạo $\rightarrow$ xác định mã tiền tố `FN[GG]`.
     * *Bước 2:* Đọc tệp `TB-AI-Rule/00-Admin_Security/02_FUNCTIONS.md`, lọc tất cả các mã bắt đầu bằng `FN[GG]`, tìm mã có số thứ tự `[NN]` lớn nhất trong nhóm đó (`Group_Max`).
     * *Bước 3:* Cấp mã mới bằng `Group_Max + 1`. (Ví dụ: nhóm `00` đang có đến `FN0005` $\rightarrow$ mã mới kế tiếp bắt buộc là `FN0006`).
     * *Bước 4:* Kiểm tra đối soát toàn bảng chống trùng lặp mã trước khi ghi nhận.
   - **Các điều cấm tuyệt đối:**
     * Tuyệt đối cấm lấy `FN9999` để tăng.
     * Tuyệt đối cấm lấy Max của nhóm này gán cho nhóm khác.
     * Tuyệt đối cấm nhảy cóc số thứ tự hoặc gán số ngẫu nhiên.
3. **Quy chuẩn cấp quyền mặc định khi nạp chức năng mới:**
   - Khi tạo chức năng mới, AI tự động nạp vào `02_FUNCTIONS.md` và đồng bộ ma trận `03_PERM_MATRIX.md`:
     * *Mọi nhóm thường (`GF0000` đến `GF0900`):* Mặc định là **`0` (TẮT / Chưa cấp phép)**.
     * *Nhóm Admin Chủ Tối cao (`GF9999`):* Luôn luôn là **`1` (BẬT / Toàn quyền 100%)**.
   - AI bắt buộc thông báo rõ trong câu trả lời:
     `📦 THÔNG BÁO VÒNG ĐỜI CHỨC NĂNG TOOLBOX: Đã nạp chức năng mới [FNxxxx - TênChứcNăng] vào danh mục hệ thống. Trạng thái mặc định: Tắt (0) cho các nhóm thường và Bật (1) cho Admin. Kỹ sư có thể mở [ADMIN-100]-Quan-Ly-Phan-Quyen.bat để phân quyền thêm cho các nhóm khác nếu muốn.`
4. **Quy chuẩn dọn dẹp khi xóa chức năng (Orphan Cleanup):**
   - Khi xóa module: Bắt buộc xóa mã `FNxxxx` khỏi `02_FUNCTIONS.md` và dọn dẹp khỏi toàn bộ các nhóm trong `03_PERM_MATRIX.md`.

---

## 🛠️ 5. QUY CHUẨN KỸ THUẬT & GIAO DIỆN CONSOLE WINDOWS
1. **Bảo toàn định dạng UTF-8 Codepage 65001:**
   - Tất cả các tệp `.ps1` và `.md` bắt buộc lưu định dạng **UTF-8 with BOM (`EF BB BF`)** để PowerShell 5.1 hiển thị tiếng Việt có dấu 100% không lỗi font.
   - Tất cả các tệp `.bat` bắt buộc lưu định dạng **ANSI / UTF-8 Không BOM**, bắt đầu bằng dòng nạp bảng mã:
     ```bat
     @echo off
     setlocal
     cd /d "%~dp0"
     title [Tieu De]
     chcp 65001 >nul 2>&1
     ```
2. **Quy chuẩn hiển thị bảng & Tô màu hàng (Row Highlighting):**
   - Các bảng chọn chức năng (như Cleaner): Cột trạng thái nằm bên phải, căn lề thẳng hàng.
   - Hàng được chọn (`BẬT`): **Tô sáng màu Xanh lá (Green)** toàn bộ hàng.
   - Hàng chưa chọn (`TẮT`): **Chìm màu Xám mờ (DarkGray)** toàn bộ hàng.
   - Hỗ trợ nhập phím đơn (`1`) hoặc nhiều phím cùng lúc (`1, 7` hoặc `1 7`).


---

## 📝 6. QUY CHUẨN BẮT BUỘC VỀ LOGGING PHÂN CẤP THEO CHỨC NĂNG
1. **Chỉ thị bắt buộc 100%:**
   - Mọi chức năng/module mang mã `FNxxxx` khi thực thi **BẮT BUỘC PHẢI TỰ ĐỘNG GHI NHẬT KÝ RA ĐĨA**. Tuyệt đối cấm viết chức năng chỉ in thông tin ra màn hình console mà không lưu vết nhật ký.
2. **Kiến trúc phân vùng thư mục nhật ký (Domain-Driven Partitioning):**
   - Không ghi lẫn lộn log các chức năng vào chung một thư mục gốc. Mỗi chức năng bắt buộc tự động tạo một thư mục con riêng mang định danh chức năng:
     `$featureLogDir = Join-Path $LOG_DIR "[Tên_Hoặc_Mã_Chức_Năng]"`
     *(Ví dụ: `Engine/Logs/[TB-01]-Don-Dep-Bo-Nho-Tam/`)*.
   - Tên file log của từng phiên chạy: `<Username>_<yyyyMMdd_HHmmss>.log`.
   - Lưu định dạng **`UTF-8 with BOM`** để mở bằng Notepad không bao giờ bị vỡ font tiếng Việt.
3. **Cơ chế Tự động Dọn dẹp Xoay vòng (Auto-Purge Retention):**
   - Mỗi chức năng khi khởi chạy tự động kiểm tra thư mục log riêng của mình và **chỉ giữ lại tối đa 30 file log gần nhất** (các file cũ hơn tự động dọn sạch).
4. **Trải nghiệm kết thúc phiên:** Cung cấp phím tắt `[O]` để người dùng mở ngay file log chi tiết bằng Notepad.

---

## 🛡️ 7. QUY CHUẨN PHÂN TẦNG SỐ HIỆU KỊCH BẢN QUẢN TRỊ [ADMIN-xxx]
Mọi file BAT trong `@File-BAT/@Administrator/` bắt buộc đặt tên theo mã số 3 chữ số:
- **`[ADMIN-001]` đến `[ADMIN-099]`**: Tầng Thao tác hàng ngày / Git & Server (`[ADMIN-001]-Push-Source-To-Server.bat`, `[ADMIN-002]-Xac-Thuc-Dong-Bo-Server.bat`).
- **`[ADMIN-100]` đến `[ADMIN-199]`**: Tầng Quản lý nghiệp vụ & Phân quyền chức năng (`[ADMIN-100]-Quan-Ly-Phan-Quyen.bat`).
- **`[ADMIN-200]` đến `[ADMIN-299]`**: Tầng Đóng gói xuất xưởng & Cấp phát Token User (`[ADMIN-200]-Dong-Goi-Ban-Client.bat`, `[ADMIN-201]-Tao-Token-Ban-Quyen.bat`).
- **`[ADMIN-300]` đến `[ADMIN-499]`**: Tầng Dự phòng mở rộng tương lai (Reserved).
- **`[ADMIN-500]` đến `[ADMIN-599]`**: Tầng Vận hành đặc thù / Bảo mật ca kíp (`[ADMIN-500]-Khoa-Rule-Bao-Ve-Tan-Ca.bat`, `[ADMIN-501]-Mo-Khoa-Rule-Vao-Ca.bat`).

---

## 🌐 8. QUY CHUẨN ĐỒNG BỘ ĐA MÁY CHO ADMIN (ADMIN PORTABILITY)
1. Kỹ sư: **Đào Xuân Tuấn (UserName: `TuanBeo` - Admin Tối cao `GF9999`)**.
2. Script bản quyền `License-Engine.ps1` **bắt buộc bỏ qua so khớp HWID** khi:
   `HWID == "ALL"` hoặc `groupId == "GF9999"` hoặc `role == "Admin"`.
3. Cho phép Admin cắm USB hoặc clone Git sang bất kỳ máy tính nào cũng tự động mở khóa 100% quyền Admin tức thì mà không bị chặn phần cứng.

---

## 🛡️ 9. QUY CHUẨN BẢO TOÀN TRẠNG THÁI & LOGS KHI CẬP NHẬT (STATE PRESERVATION SHIELD)
1. Khi cập nhật phiên bản mới: Thư mục `Engine/Logs/` và file cấu hình cá nhân `Engine/Config/cleaner-config.json` **bắt buộc được bảo tồn nguyên vẹn 100%**.
2. Bộ xuất bản cho Client tuyệt đối không chứa thư mục `Logs/` và chỉ đóng gói file mẫu `cleaner-config.example.json`.

---

## 🔓 10. CHỐNG BÁO ĐỘNG GIẢ ANTIVIRUS & TỰ ĐỘNG GỠ CỜ KHÓA TỆP MẠNG
1. Mọi file BAT đều có dòng lệnh ngầm tự động gỡ cờ Mark of the Web (`Unblock-File`).
2. Cung cấp file tiện ích: `[000]-Kiem-Tra-Moi-Truong-Va-Giai-Phong-Chan.bat` tại `@File-BAT/`.
3. Mã nguồn viết rõ ràng, không làm mờ code (obfuscation), có tiêu đề bản quyền `Kỹ sư: Đào Xuân Tuấn (Tuấn Beo)`.

---

## 📚 11. QUY CHUẨN TÀI LIỆU HƯỚNG DẪN CHO ADMIN VÀ NGƯỜI DÙNG
1. **Tài liệu Quản trị Tối mật cho Admin (`@Huong-Dan-Admin/`):**
   - Đặt tại `@File-BAT/@Administrator/@Huong-Dan-Admin/`.
   - Bị loại trừ 100% khi đóng gói xuất xưởng Client.
   - Gồm 2 file: `01-HUONG-DAN-CHU-KY-SO-VA-DONG-BO-DA-MAY-CHO-ADMIN.md` và `02-QUY-TRINH-VAN-HANH-VA-VONG-DOI-HE-THONG.md`.
2. **Tài liệu Hướng dẫn Người dùng:**
   - Đặt tại thư mục gốc Toolbox: `!00-HUONG-DAN-SU-DUNG-CHO-NGUOI-DUNG.md`.


---

## 🎯 12. QUY CHUẨN PHÂN TẦNG SỐ HIỆU KỊCH BẢN NGƯỜI DÙNG [xxx], TIẾN TRÌNH HYDRATION & CAM KẾT PUSH GIT ADMIN
1. **Phân tầng số hiệu 3 chữ số tầng Người dùng (`@File-BAT/`):**
   - `[000]` (Bất biến): Kiểm tra môi trường & Giải phóng chặn mạng (`[000]-Kiem-Tra-Moi-Truong-Va-Giai-Phong-Chan.bat`).
   - `[001]` đến `[099]`: Khởi động và cài đặt (`[001]-Cai-Dat-TB-Toolbox.bat`, `[002]-Nhap-Key-Kich-Hoat.bat`).
   - `[100]` đến `[199]`: Kiểm tra trạng thái hệ thống (`[100]-Kiem-Tra-Trang-Thai-Toolbox.bat`).
   - `[200]` đến `[299]`: Cập nhật từ Git Server (`[200]-Cap-Nhat-Toolbox-Tu-Server.bat`).
   - `[300]` đến `[499]`: Dải dự phòng mở rộng (Reserved).
   - `[500]` đến `[999]`: Các chức năng nghiệp vụ dùng chung (`[500]-Don-Dep-Bo-Nho-Tam-He-Thong.bat`...).
2. **Cơ chế Progressive Feature Hydration:**
   - Bản xuất xưởng ban đầu cho Client **CHỈ CÓ 3 TỆP: `[000]`, `[001]`, `[002]`**.
   - Ngăn chặn hoàn toàn lỗi người dùng bấm bừa khi chưa kích hoạt key. Sau khi kích hoạt thành công, các file `[100]`, `[200]`, `[500]`... mới tự động xuất hiện.
3. **Mệnh lệnh Cam kết Git Admin:**
   - Toàn bộ các file quản trị (`@Administrator/`, `@Huong-Dan-Admin/`, `00-Admin_Security/`), quy tắc và mã nguồn Admin chỉnh sửa **BẮT BUỘC 100% PHẢI ĐƯỢC COMMIT VÀ PUSH LÊN GITHUB SERVER RIÊNG CỦA ADMIN QUA `[ADMIN-001]`**, đảm bảo đồng bộ hoàn hảo trên mọi thiết bị cá nhân.
