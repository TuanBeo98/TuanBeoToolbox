# 📜 SỔ CÁI LỊCH SỬ TIẾN HÓA QUY TẮC AI (99-RULE-CHANGE-LOG.md)
> 📝 **MÔ TẢ:** Nguồn chân lý duy nhất (Single Source of Truth) lưu trữ toàn bộ lịch sử cải tiến, mã phiên bản, bối cảnh thiết kế và các quyết định kiến trúc của hệ sinh thái quy chuẩn TuanBeoAI.
> 👤 **TÁC GIẢ & QUẢN TRỊ VIÊN TỐI CAO:** Đào Xuân Tuấn (Mr. Tuấn Beo)
> 🌐 **KHO LƯU TRỮ TRÊN GITHUB:** `TuanBeoAI` (Đồng bộ đa máy cá nhân, bất tử liên kết, không bị cắt tỉa theo thời gian)

---

## 📌 BẢNG TRA CỨU PHIÊN BẢN TIẾN HÓA NHANH (QUICK INDEX)

| Mã Bản | Ngày | Tên Cải Tiến & Tính Năng | Trọng Tâm Thay Đổi |
| :---: | :---: | :--- | :--- |
| [TBRULE-31](#tbrule-31) | 29/10/2026 | Thiết Lập Sổ Cái Rule `99-RULE-CHANGE-LOG.md` & Bộ 5 Bootloader | Ban hành Sổ cái tiến hóa vĩnh cửu, vá dead-links đa máy, đồng bộ `.cursorrules` & `.windsurfrules`. |
| [TBRULE-30](#tbrule-30) | 29/10/2026 | Chốt Chặn Bắt Buộc Bộ 3 Tệp (Trinity Gate) & Log Phần 1 - 9 - 10 | Bắt buộc đủ Bộ 3 tệp (`01-PLAN`, `02-VERIFY`, `70-LOG`), cấu trúc phân khu số, tách bạch DB Jira và 12 icon chuẩn. |
| [TBRULE-29](#tbrule-29) | 28/10/2026 | Chốt Chặn Chống Báo Hoàn Thành Ảo (`004-Q`) & Báo Động Ready Queue | Lệnh `004-Q` đóng băng khảo sát; cảnh báo bắt buộc hàng đợi Ready Queue ngay đầu phiên chat. |
| [TBRULE-28](#tbrule-28) | 28/10/2026 | Cơ Chế Cắt Tỉa Cưỡng Chế Cửa Sổ Trượt 2 Tuần Weekly Table | Cắt tỉa bảng chỉ mục tuần giữ 2 tuần gần nhất, chống quá tải bộ nhớ đệm AI. |
| [TBRULE-27](#tbrule-27) | 28/10/2026 | Bộ Phân Giải Jira REST API, Fast-Resume & Mã Lệnh Cập Nhật `004-U` | REST API thay browser subagent nạp Jira <2s, Fast-Resume <5s, lệnh delta `004-U`. |
| [TBRULE-26](#tbrule-26) | 27/10/2026 | Kiến Trúc Đa Nền Tảng, Thẩm Định 4 Tầng & Học Hỏi Tiến Hóa Rule | Phân tách WinForms/Web, Anti-False-Green, Zero-Dead-Variables, thư mục `98-Learned-Lessons/`. |
| [TBRULE-25](#tbrule-25) | 24/10/2026 | Giải Quyết Triệt Để 7 Điểm Mù Hệ Thống Bản Quyền & Khóa Phần Cứng HWID | CompanyScope, HWID `ALL` cho Admin, chống lùi giờ Time-Vault, xử lý 100% điểm mù. |
| [TBRULE-24](#tbrule-24) | 24/10/2026 | Chuẩn Hóa Cú Pháp Nhập Target Company `[MÃ]` & Tệp Công Ty Mẫu | Định dạng `[MÃ]`, kiểm tra cú pháp, tự cập nhật danh sách khả dụng, mẫu `00-Company-Template.md`. |
| [TBRULE-23](#tbrule-23) | 24/10/2026 | Quy Chuẩn Target Company Trong Profile, Self-Healing & Định Danh Task | Cơ chế tự sửa lỗi format công ty, lưu vết mã công ty trong Fast Snapshot và hồ sơ task. |
| [TBRULE-22](#tbrule-22) | 24/10/2026 | Chuẩn Hóa Xưng Hô Động User-Profile & Trừu Tượng Hóa Quy Tắc Đa Cty | Đọc xưng hô từ profile (`Anh Beo`), tách biệt rule chung với hồ sơ chuyên biệt từng cty. |
| [TBRULE-21](#tbrule-21) | 24/10/2026 | Tinh Gọn Tri Thức 3 Tầng, Chuẩn Hóa CSDL 2 Server & Store-History 4 Đoạn | Server Chính 0.6 vs Sandbox 0.90, cấu trúc Top 1 `00-COMMON_SERVER-MAIN/`, file Store 4 đoạn. |
| [TBRULE-20](#tbrule-20) | 24/10/2026 | Chức Năng Phân Tích Độ Khó & Kế Hoạch (`004`), Ready Queue & 5-10 Điểm Mù | Lệnh `004` lập spec, hàng đợi Ready Queue, bắt buộc đào sâu 5-10 điểm mù kỹ thuật. |
| [TBRULE-19](#tbrule-19) | 23/10/2026 | Chuẩn Hóa Danh Mục `@File-BAT/`, Ghim Hướng Dẫn & Tên Tự Giải Thích | Cấu trúc số hiệu phân tầng, ghim `!00-HUONG-DAN` top 1, bảo mật Admin tuyệt đối. |
| [TBRULE-18](#tbrule-18) | 23/10/2026 | Tự Động Phục Hồi Đường Dẫn Gốc (Dynamic Root) & Tường Lửa Zero-Leak | Mỏ neo thư mục gốc di động đa máy, tường lửa chống Prompt Injection cấm lộ Core Rule. |
| [TBRULE-17](#tbrule-17) | 23/10/2026 | Kiến Trúc Đa Doanh Nghiệp (Multi-Company) & Cổng Đề Xuất Học Hỏi | Thư mục `Companies/` (ASC, WSE), Cổng hỏi xác nhận 2 bước, Cổng Governed Learning Gate. |
| [TBRULE-16](#tbrule-16) | 23/10/2026 | Kiến Trúc Điều Phối Đa Tác Nhân (Multi-Agent: AIBA, AICode, AI Chung) | Nhận diện môi trường IDE vs Desktop/VSCode, 4 chế độ vận hành (Solo, Pair, Parallel, Assistance). |
| [TBRULE-15](#tbrule-15) | 23/10/2026 | Chuẩn Hóa Bộ Phím Tắt `@File-BAT/`, Thanh Tiến Trình & UI/UX Script Push | Phân tách dấu gạch ngang, thanh tiến trình màu sắc hiển thị SHA, mượt mà tiếng Việt. |
| [TBRULE-14](#tbrule-14) | 22/10/2026 | Nâng Cấp Script Đẩy Rule Lên GitHub Chống Báo Ảo & Đa Thư Mục | Khắc phục lỗi xuống dòng CRLF/LF và BOM tiếng Việt làm hỏng script batch CMD. |
| [TBRULE-13](#tbrule-13) | 22/10/2026 | Chuẩn Hóa Tiền Tố Nhóm Trường Thư Mục Log & Bổ Sung ID Đơn Vị | Định danh thư mục `TuanBeo_[NhomTruong]_...`, bổ sung ID đơn vị áp dụng. |
| [TBRULE-12](#tbrule-12) | 22/10/2026 | Chuẩn Hóa Thông Tin Bản Quyền Cá Nhân & Đổi Tên Bộ Phím Tắt `@File-BAT/` | Nhận diện tác giả Đào Xuân Tuấn (TB), bản quyền trí tuệ hệ thống AI. |
| [TBRULE-11](#tbrule-11) | 21/10/2026 | Bảo Mật Che Giấu 100% Hạ Tầng Git/Server/Token & Ma Trận Phân Quyền | Che giấu Git Token, ma trận phân quyền công tắc [0/1] cho từng tính năng. |
| [TBRULE-10](#tbrule-10) | 21/10/2026 | Phân Phối Thin Client, Sổ Cái Key Chống Crack, Token Rotation Ngầm | Đóng gói siêu nhẹ, sổ cái quản lý key, tự động đổi token xoay vòng bảo mật. |
| [TBRULE-09](#tbrule-09) | 21/10/2026 | Chuyển Hệ Thống Rule Lên Server GitHub TuanBeoAI & Bộ Đồng Bộ 1-Click | Thiết lập kho Git Server TuanBeoAI, script đồng bộ 1-click tự động hóa. |
| [TBRULE-08](#tbrule-08) | 21/10/2026 | Khóa & Mở Khóa Rule Khi Tan Ca / Vào Ca & Chuẩn Hóa Phím Tắt | Script bảo vệ tan ca mã hóa rule, mở khóa ca làm việc, an toàn mã nguồn. |
| [TBRULE-06](#tbrule-06) | 20/10/2026 | Chuẩn Hóa Tiền Tố UserName Trong Log & Vòng Đời Bản Quyền Free/Licensed | Tiền tố `[UserName]_`, cơ chế fallback key Free mặc định và phục hồi license. |
| [TBRULE-05](#tbrule-05) | 20/10/2026 | Chuẩn Hóa Universal Action Key (UAK), Khóa UserName & Menu Admin | Phím hành động UAK toàn năng, khóa cứng UserName tránh sửa trái phép. |
| [TBRULE-04](#tbrule-04) | 20/10/2026 | Chuẩn Hóa Đường Dẫn Tương Đối Đa Máy & Phân Quyền User Whitelist | Xóa bỏ hardcode ổ đĩa D:\, phân lập User Whitelist vs Protected Core Rules. |
| [TBRULE-03](#tbrule-03) | 20/10/2026 | Nâng Cấp Mã Hóa Rule, KeyManager Admin, Đóng Gói Client & Lệnh 021-024 | Bộ công cụ cấp key Admin, đóng gói Client xuất xưởng, bộ lệnh tạm ngưng 021-024. |
| [TBRULE-02](#tbrule-02) | 19/10/2026 | Lưu Vết Comment Đa Phiên & Cổng Đối Soát Khi Chốt Sổ | Cơ chế lưu vết comment `/* TB... */`, đối soát Git Diff trước khi đóng task. |
| [TBRULE-01](#tbrule-01) | 19/10/2026 | Chuẩn Hóa Quy Chuẩn Rẽ Nhánh Điều Kiện Theo Trường | Cấm hardcode số nguyên, bắt buộc dùng Enum `UniversityID` từ Database. |

---

## 📜 CHI TIẾT CÁC PHIÊN BẢN TIẾN HÓA

### <a id="tbrule-31"></a> 🌟 [TBRULE-31] (29/10/2026) - Thiết Lập Sổ Cái Tiến Hóa Rule `99-RULE-CHANGE-LOG.md`, Đồng Bộ Đa Máy Bất Tử Link & Hoàn Thiện Bộ 5 Bootloader Đa AI
- **Bối cảnh & Mục tiêu:** 
  1. Khắc phục triệt để vấn nạn **Dead-Link (404)** khi Kỹ sư chuyển máy cá nhân làm việc (do `.gitignore` chặn thư mục `99-Task-History/` khiến các link trong `1-TB-Current-Task.md` bị gãy).
  2. Khắc phục nguy cơ mất trắng dấu vết lịch sử cải tiến từ `TBRULE-01` đến `TBRULE-25` do cơ chế cắt tỉa cưỡng chế 2 tuần (`TBRULE-28`).
  3. Vá điểm mù bỏ sót của AICode: Đồng bộ hóa 100% nội dung quy chuẩn sang hai tệp Bootloader còn thiếu: `.cursorrules` và `.windsurfrules`.
- **Tệp tác động:** 
  - `TB-AI-Rule/99-RULE-CHANGE-LOG.md` (Tạo mới - Sổ cái vĩnh cửu theo dõi bởi Git).
  - `.cursorrules` (Đồng bộ Trinity Gate & Log Phần 1 - 9 - 10).
  - `.windsurfrules` (Đồng bộ Trinity Gate & Log Phần 1 - 9 - 10).
  - `TB-AI-Rule/1-TB-Current-Task.md` (Cập nhật toàn bộ link `00-RULE` sang Sổ cái).
- **Nội dung thay đổi cốt lõi:**
  1. Ban hành `99-RULE-CHANGE-LOG.md` thuộc vùng quản lý Sổ cái & Lịch sử (`99-`), được Git theo dõi và đồng bộ lên GitHub Server.
  2. Tích hợp bảng Quick Index và chi tiết đầy đủ 31 phiên bản tiến hóa với anchor tags `<a id="..."></a>`.
  3. Cập nhật các liên kết của nhóm nhiệm vụ Rule trong `1-TB-Current-Task.md` trỏ trực tiếp vào Sổ cái: `[Xem log](TB-AI-Rule/99-RULE-CHANGE-LOG.md#tbrule-xx)`.
  4. Đạt chuẩn đồng nhất 100% trên toàn bộ 5 tệp Bootloader: `GEMINI.md`, `CLAUDE.md`, `COPILOT.md`, `.cursorrules`, `.windsurfrules`.

---

### <a id="tbrule-30"></a> 🛡️ [TBRULE-30] (29/10/2026) - Chuẩn Hóa Chốt Chặn Bắt Buộc Bộ 3 Tệp (Mandatory Trinity Gate), Cấu Trúc Log-Work (Phần 1 - Phần 9 - Phần 10), Bộ Icon Chuẩn & Tách Bạch Tóm Tắt DB Jira vs Kỹ Thuật
- **Bối cảnh & Mục tiêu:** Khắc phục tình trạng đóng task sót tệp nghiệm thu `02-VERIFY-HANDOVER.md` (như ở task `TLU-1429`), lộn xộn cấu trúc phân cấp số/chữ của log work, và vỡ font icon trên Jira WorklogPRO.
- **Tệp tác động:** `00-AI-MASTER-RULES.md`, `4-quy-chuan-luu-tru-lich-su-task.md`, `GEMINI.md`, `CLAUDE.md`, `COPILOT.md`, `1-TB-Current-Task.md`, task history `TLU-1429`.
- **Nội dung thay đổi cốt lõi:**
  1. Cài đặt **Chốt chặn bắt buộc Bộ 3 tệp (Mandatory Trinity Pre-Closure Gate)** cho lệnh chốt task `001`: Bắt buộc kiểm tra đủ 3 tệp `01-PLAN-SPEC.md`, `02-VERIFY-HANDOVER.md`, `70-Log-Work.md`.
  2. Chuẩn hóa cấu trúc `70-Log-Work.md` sang phân khu số: **Phần 1 (Trí nhớ AI)**, **Phần 9 (Tóm tắt Jira)**, **Phần 10 (Mô tả kỹ thuật chuyên sâu)**; khóa bảo lưu các phân khu 2..8.
  3. Tách bạch DB trong Phần 9: Chỉ tóm tắt ý chính (tên store/bảng, cột, param, logic rẽ nhánh); cấm chèn code SQL dài, dồn toàn bộ xuống Phần 10.
  4. Ban hành bộ 12 Icon Whitelisted Unicode (`🧠`, `📌`, `🎯`, `⚡`, `🗄️`, `💻`, `🖥️`, `🔄`, `🛠️`, `🔍`, `📂`, `✅`).

---

### <a id="tbrule-29"></a> ⚡ [TBRULE-29] (28/10/2026) - Thiết Lập Chốt Chặn Chống Báo Hoàn Thành Ảo (`004-Q`), Báo Động Hàng Đợi (Bootloader Ready Queue Alert) & Đồng Bộ 100% Bộ 5 Tệp Bootloader Đa AI
- **Bối cảnh & Mục tiêu:** Triệt tiêu tình trạng báo hoàn thành ảo khi AI mới chỉ dừng ở khảo sát đặc tả; chống trôi ticket trong hàng đợi khi bắt đầu phiên làm việc mới.
- **Tệp tác động:** `GEMINI.md`, `CLAUDE.md`, `.cursorrules`, `COPILOT.md`, `.windsurfrules`, `1-TB-Current-Task.md`.
- **Nội dung thay đổi cốt lõi:**
  1. Bổ sung mã lệnh `004-Q` (`DongBangKhaoSat`): Đóng băng khảo sát và chuyển task vào Ready Queue, nghiêm cấm gõ lệnh `1` / `001` khi chưa có Git Diff hoặc chưa test DB thực tế.
  2. Ban hành quy tắc Báo Động Hàng Đợi Đầu Phiên Chat (Bootloader Ready Queue Alert): Bắt buộc in cảnh báo nhắc nhở kèm mã kích hoạt (`30x` / `ACT [MãTask]`) ngay lời chào đầu phiên.
  3. Đồng bộ hóa 5 tệp Bootloader cho toàn bộ các IDE và AI Assistant.

---

### <a id="tbrule-28"></a> 🧹 [TBRULE-28] (28/10/2026) - Thiết Lập Cơ Chế Cắt Tỉa Cưỡng Chế Cửa Sổ Trượt 2 Tuần (Bi-Weekly Sliding Window Pruning Mandate) Cho Bảng Weekly Table
- **Bối cảnh & Mục tiêu:** Bảng `Weekly Table` trong `1-TB-Current-Task.md` phình to sau nhiều tuần làm việc, ngốn bộ nhớ đệm Context Window và làm chậm tốc độ xử lý của AI.
- **Tệp tác động:** `1-TB-Current-Task.md`, `00-AI-MASTER-RULES.md`, `GEMINI.md`.
- **Nội dung thay đổi cốt lõi:**
  1. Ban hành cơ chế Cửa sổ trượt 2 tuần (Bi-Weekly Sliding Window): Bảng chỉ mục tuần chỉ giữ task của tuần hiện tại và tuần kế trước liền kề.
  2. Các task cũ hơn 2 tuần tự động được cắt tỉa khỏi bảng, dữ liệu đầy đủ được bảo lưu và tra cứu tại `99-Task-History/`.

---

### <a id="tbrule-27"></a> 🚀 [TBRULE-27] (28/10/2026) - Nâng Cấp Bộ Phân Giải Jira Regex, Cơ Chế PowerShell REST API Read-Only (Thay Thế Browser Subagent), Giao Thức Fast-Resume (<5s) & Mã Lệnh Cập Nhật Delta `004-U`
- **Bối cảnh & Mục tiêu:** Khắc phục tình trạng dùng Browser subagent cồng kềnh, chậm chạp và dễ timeout khi lấy thông tin Jira; hỗ trợ cập nhật delta spec cho task trong hàng đợi.
- **Tệp tác động:** `GEMINI.md`, `00-AI-MASTER-RULES.md`, `1-TB-Current-Task.md`.
- **Nội dung thay đổi cốt lõi:**
  1. Chuyển đổi 100% sang cơ chế gọi REST API bằng PowerShell Read-Only, nạp dữ liệu ticket Jira dưới 2 giây.
  2. Bổ sung mã lệnh `004-U` (`UPDATE [MãTask]`): Cập nhật yêu cầu phát sinh trực tiếp vào `01-PLAN-SPEC.md`, cấm tạo thư mục trùng lặp.
  3. Chuẩn hóa giao thức Fast-Resume Snapshot nạp trí nhớ dưới 5 giây.

---

### <a id="tbrule-26"></a> 🏗️ [TBRULE-26] (27/10/2026) - Chuẩn Hóa Kiến Trúc Đa Nền Tảng (WinForms vs Web), Cổng Thẩm Định Khép Kín 4 Tầng (Anti-False-Green) & Cơ Chế Tiến Hóa Rule `98-Learned-Lessons/`
- **Bối cảnh & Mục tiêu:** Phân tách rạch ròi quy chuẩn WinForms và Web MVC/OneGate; xây dựng cơ chế học hỏi từ sai sót và kiểm toán tiêu thụ biến chống bug ngầm.
- **Tệp tác động:** `00-AI-MASTER-RULES.md`, `98-Learned-Lessons/`, `GEMINI.md`.
- **Nội dung thay đổi cốt lõi:**
  1. Phân định kiến trúc Đa Nền tảng: Desktop WinForms (BLL Cache, binding DataGridView) vs Web OneGate (REST API, MVC, JSON).
  2. Thiết lập Cổng thẩm định 4 tầng: Build exit 0, Trace luồng dữ liệu khép kín, Zero-Dead-Variables, Git Staging Hygiene.
  3. Khởi tạo kho tri thức tiến hóa `TB-AI-Rule/98-Learned-Lessons/` gồm 3 phân khu: `01-Feedback-Vault/`, `02-Case-Studies/`, `03-Evolution-Proposals/`.

---

### <a id="tbrule-25"></a> 🔐 [TBRULE-25] (24/10/2026) - Giải Quyết Triệt Để 7 Điểm Mù Hệ Thống Bản Quyền: Phân Tầng Dữ Liệu Theo Công Ty, Khóa Phần Cứng (HWID), Chống Clone Folder & Xử Lý 100% Điểm Mù
- **Bối cảnh & Mục tiêu:** Bịt toàn bộ lỗ hổng bảo mật bản quyền, hỗ trợ Admin di động đa máy không bị giới hạn phần cứng, ngăn chặn gian lận lùi đồng hồ hệ thống.
- **Tệp tác động:** `00-AIConfig/security-config.md`, `Activate-License.ps1`, `GEMINI.md`, `00-AI-MASTER-RULES.md`.
- **Nội dung thay đổi cốt lõi:**
  1. Trường `HWID == ALL` hoặc `Role == Admin` tự động bypass kiểm tra phần cứng, cho phép Admin cắm USB/clone Git sang bất kỳ máy nào cũng kích hoạt bản quyền vĩnh viễn.
  2. Cơ chế két sắt thời gian (Time-Vault) và chống gian lận lùi ngày giờ hệ thống.
  3. Quy định mệnh lệnh bắt buộc: AI chỉ điểm 5-10 điểm mù thì một khi Kỹ sư duyệt "OK" bắt buộc phải lập kế hoạch giải quyết dứt điểm 100%, cấm bỏ sót.

---

### <a id="tbrule-24"></a> 🏢 [TBRULE-24] (24/10/2026) - Chuẩn Hóa Cú Pháp Nhập Target Company Dạng `[MÃ]`, Kiểm Tra Định Dạng & Tệp Công Ty Mẫu Đa Doanh Nghiệp
- **Bối cảnh & Mục tiêu:** Thống nhất cú pháp khai báo công ty trong profile cá nhân, tránh lỗi cú pháp parse chuỗi đa doanh nghiệp.
- **Tệp tác động:** `user-profile.md`, `00-Company-Template.md`, `GEMINI.md`.
- **Nội dung thay đổi cốt lõi:**
  1. Cú pháp chuẩn dạng `[MÃ]` (ví dụ: `[ASC]` cho 1 cty; `[ASC; WSE]` cho đa cty; `[]` để trống).
  2. Cung cấp file mẫu chuẩn hóa `Companies/00-Company-Template.md` để dễ dàng nhân bản hồ sơ khi mở rộng sang doanh nghiệp mới.

---

### <a id="tbrule-23"></a> 🔄 [TBRULE-23] (24/10/2026) - Quy Chuẩn Cấu Hình Target Company Trong Profile, Cơ Chế Tự Sửa Lỗi Self-Healing & Định Danh Doanh Nghiệp Trong Lịch Sử Task
- **Bối cảnh & Mục tiêu:** AI tự động khắc phục lỗi người dùng gõ sai cú pháp công ty; lưu vết mã công ty xuyên suốt toàn bộ vòng đời tác vụ.
- **Tệp tác động:** `user-profile.md`, `1-TB-Current-Task.md`, `GEMINI.md`.
- **Nội dung thay đổi cốt lõi:**
  1. Tự sửa lỗi Self-Healing: Tự động chuẩn hóa format công ty về chữ HOA đóng ngoặc vuông và quét cập nhật danh sách công ty khả dụng.
  2. Bắt buộc lưu vết `Company Code` trong Fast Snapshot, Active Task, Weekly Index Table và bộ hồ sơ task.

---

### <a id="tbrule-22"></a> 👤 [TBRULE-22] (24/10/2026) - Chuẩn Hóa Xưng Hô Động Theo User-Profile, Bảo Tồn Bản Quyền Tác Giả & Trừu Tượng Hóa Quy Tắc Chung Đa Doanh Nghiệp
- **Bối cảnh & Mục tiêu:** Cá nhân hóa cách xưng hô của AI theo cấu hình cá nhân (`Anh Beo`), đảm bảo AI thích ứng linh hoạt với từng kỹ sư mà không làm mất bản quyền hệ thống.
- **Tệp tác động:** `user-profile.md`, `GEMINI.md`, `00-AI-MASTER-RULES.md`.
- **Nội dung thay đổi cốt lõi:**
  1. AI bắt buộc đọc và xưng hô 100% theo trường `Cách AI xưng hô trong chat` từ `user-profile.md`.
  2. Trừu tượng hóa các quy tắc lõi để áp dụng chung cho mọi doanh nghiệp, tách các thông số IP/DB vào profile công ty riêng.

---

### <a id="tbrule-21"></a> 🗄️ [TBRULE-21] (24/10/2026) - Tinh Gọn Tri Thức 3 Tầng, Chuẩn Hóa CSDL 2 Server & Cấu Trúc Store-History 4 Đoạn
- **Bối cảnh & Mục tiêu:** Ngăn chặn nhầm lẫn dữ liệu giữa Server Chính và Server Sandbox; chuẩn hóa quy cách đặt tên file Store Procedure bảo trì.
- **Tệp tác động:** `00-AI-MASTER-RULES.md`, `09-Database/`, `GEMINI.md`.
- **Nội dung thay đổi cốt lõi:**
  1. Quy chuẩn mô hình 2 Server: Server Chính (Golden Source 0.6 chứa `*_ORG` cấm test) vs Server Thử Nghiệm (Sandbox 0.90 chia theo trường `_[Truong]`).
  2. Cấu trúc thư mục Store History 2 cấp (Top 1 `00-COMMON_SERVER-MAIN/`).
  3. Tên file Store chuẩn 4 đoạn: `[UserName]_[YYYYMMDD]_[MãTask]_[TênStore]_[GOC|SUA].sql`.

---

### <a id="tbrule-20"></a> 📋 [TBRULE-20] (24/10/2026) - Chuẩn Hóa Chức Năng Phân Tích Độ Khó & Lên Kế Hoạch (`004`), Ready Queue & Quy Chuẩn Đào Sâu 5-10 Điểm Mù Kỹ Thuật
- **Bối cảnh & Mục tiêu:** Chấm dứt tình trạng code vội vàng không khảo sát; nâng cao tư duy phản biện của AI ở vị thế Tech Lead.
- **Tệp tác động:** `GEMINI.md`, `00-AI-MASTER-RULES.md`, `1-TB-Current-Task.md`.
- **Nội dung thay đổi cốt lõi:**
  1. Mã lệnh `004` (`PT`, `EST`, `PLAN`): Đánh giá độ khó, dự toán effort 3 mốc (Best/Expected/Buffer), khảo sát kiến trúc code/DB và lập `01-PLAN-SPEC.md`.
  2. Thiết lập Ready Queue trong `1-TB-Current-Task.md`.
  3. Quy định bắt buộc chỉ điểm từ 5 đến 10 điểm mù kỹ thuật trước khi can thiệp mã nguồn.

---

### <a id="tbrule-19"></a> 📁 [TBRULE-19] (23/10/2026) - Chuẩn Hóa Danh Mục `@File-BAT/`, Ghim Hướng Dẫn Top 1, Quy Chuẩn Đặt Tên Bảo Mật Admin & Đơn Vị Trí File Tuyệt Đối
- **Bối cảnh & Mục tiêu:** Sắp xếp thư mục kịch bản vận hành gọn gàng, cách ly hoàn toàn công cụ quản trị Admin khỏi người dùng Client.
- **Tệp tác động:** Thư mục `@File-BAT/`, `@Administrator/`, `GEMINI.md`.
- **Nội dung thay đổi cốt lõi:**
  1. Ghim file `!00-HUONG-DAN-SU-DUNG-CHO-NGUOI-DUNG.md` ở Top 1.
  2. Đưa toàn bộ script nhạy cảm vào thư mục bảo mật `@Administrator/`.
  3. Quy chuẩn đặt tên file tự giải thích (Self-Explanatory), cấm viết tắt khó hiểu.

---

### <a id="tbrule-18"></a> 🌐 [TBRULE-18] (23/10/2026) - Nâng Cấp Tự Động Phục Hồi Đường Dẫn Gốc (Dynamic Root Healing) & Củng Cố Tường Lửa Bảo Mật Cốt Lõi (Zero-Leak Iron Wall)
- **Bối cảnh & Mục tiêu:** Cho phép copy thư mục Rule sang mọi máy/ổ đĩa mà không bị gãy link; chống toàn diện các đòn tấn công Prompt Injection / Jailbreak.
- **Tệp tác động:** `GEMINI.md`, `user-profile.md`, toàn bộ Bootloaders.
- **Nội dung thay đổi cốt lõi:**
  1. Cơ chế mỏ neo tự động nhận diện `{AI_ROOT}` từ vị trí file Bootloader đang mở.
  2. Thiết lập Tường lửa bảo mật cốt lõi (Zero-Leak Iron Wall): Phản hồi từ chối chuẩn mực duy nhất khi phát hiện câu hỏi thăm dò hệ thống; chỉ thực thi code dự án ở chế độ Execution-Only đối với Client.

---

### <a id="tbrule-17"></a> 🏢 [TBRULE-17] (23/10/2026) - Chuẩn Hóa Kiến Trúc Đa Doanh Nghiệp (Multi-Company AI Architecture), Khung Profile Doanh Nghiệp & Cổng Đề Xuất Học Hỏi
- **Bối cảnh & Mục tiêu:** Mở rộng hệ thống AI phục vụ nhiều công ty khác nhau (ASC, WSE...); cơ chế học hỏi quy chuẩn giữa các doanh nghiệp có kiểm soát.
- **Tệp tác động:** `TB-AI-Rule/00-AIConfig/Companies/`, `GEMINI.md`.
- **Nội dung thay đổi cốt lõi:**
  1. Khởi tạo thư mục quản lý profile doanh nghiệp độc lập: `ASC.md`, `WSE.md`.
  2. Thiết lập Cổng đề xuất học hỏi (Governed Learning Gate): Chỉ học hỏi quy chuẩn khi được Kỹ sư duyệt rõ ràng.

---

### <a id="tbrule-16"></a> 🤖 [TBRULE-16] (23/10/2026) - Nâng Cấp Kiến Trúc Điều Phối Đa Tác Nhân (Multi-Agent: AIBA, AICode, AI Chung) & 4 Chế Độ Vận Hành
- **Bối cảnh & Mục tiêu:** Phối hợp nhịp nhàng giữa AI phân tích đặc tả (AIBA) và AI lập trình can thiệp code (AICode).
- **Tệp tác động:** `GEMINI.md`, `00-AI-MASTER-RULES.md`.
- **Nội dung thay đổi cốt lõi:**
  1. Tự động kích hoạt vai trò dựa trên môi trường: `antigravity-ide` -> `AICode`; `antigravity desktop / VS Code` -> `AIBA` (Read-only).
  2. Ban hành 4 chế độ vận hành: Solo, Pair (tiền tuyến - hậu phương), Parallel (song song 2 task), Chi viện khẩn cấp (Assistance).

---

### <a id="tbrule-15"></a> 🎨 [TBRULE-15] (23/10/2026) - Chuẩn Hóa Tên Gọi Bộ Phím Tắt `@File-BAT/`, Thanh Tiến Trình Quét Tệp & UI/UX Script Push Rule
- **Bối cảnh & Mục tiêu:** Tối ưu hóa trải nghiệm người dùng khi chạy kịch bản đẩy mã nguồn; hiển thị trực quan phần trăm nạp file.
- **Tệp tác động:** `@File-BAT/`, `Push-RuleToServer.ps1`.
- **Nội dung thay đổi cốt lõi:**
  1. Chuẩn hóa tên phím tắt phân tách bằng dấu gạch ngang (`-`).
  2. Xây dựng thanh tiến trình console bằng ký tự Unicode `█` và `─`, phối màu Cyan/Yellow/Green chuyên nghiệp.

---

### <a id="tbrule-14"></a> 🛠️ [TBRULE-14] (22/10/2026) - Nâng Cấp Script Đẩy Rule Lên Server GitHub Chống Báo Ảo & Đa Thư Mục
- **Bối cảnh & Mục tiêu:** Sửa lỗi file `.bat` bị CMD văng lỗi do lệch pha encoding UTF-8 BOM và xuống dòng CRLF/LF.
- **Tệp tác động:** `Push-RuleToServer.ps1`, launcher batch files.
- **Nội dung thay đổi cốt lõi:**
  1. Chuyển 100% logic hiển thị tiếng Việt và điều khiển sang PowerShell UTF-8 with BOM.
  2. File `.bat` đóng vai trò launcher ASCII thuần sạch sẽ.

---

### <a id="tbrule-13"></a> 🏷️ [TBRULE-13] (22/10/2026) - Chuẩn Hóa Tiền Tố Nhóm Trường Thư Mục Log & Bổ Sung "ID Đơn Vị Áp Dụng"
- **Bối cảnh & Mục tiêu:** Quản lý lịch sử task khoa học theo từng trường đại học đối tác.
- **Tệp tác động:** `00-AI-MASTER-RULES.md`, `4-quy-chuan-luu-tru-lich-su-task.md`.
- **Nội dung thay đổi cốt lõi:**
  1. Bắt buộc tiền tố nhóm trường trong tên folder log: `[UserName]_[NhomTruong]_[YYYYMMDD]_[MãTask]_[TênTask]`.
  2. Bổ sung trường thông tin `ID đơn vị áp dụng` vào đầu file task header.

---

### <a id="tbrule-12"></a> 👤 [TBRULE-12] (22/10/2026) - Chuẩn Hóa Thông Tin Bản Quyền Cá Nhân & Đổi Tên Bộ Phím Tắt `@File-BAT/`
- **Bối cảnh & Mục tiêu:** Định danh quyền sở hữu trí tuệ hệ sinh thái AI cho Kỹ sư Đào Xuân Tuấn.
- **Tệp tác động:** `GEMINI.md`, `00-AI-MASTER-RULES.md`, `@File-BAT/`.
- **Nội dung thay đổi cốt lõi:**
  1. Ban hành thông tin bản quyền chuẩn xác trên toàn bộ tài liệu và mã nguồn.
  2. Đồng bộ hóa tên thư mục `@File-BAT/`.

---

### <a id="tbrule-11"></a> 🔒 [TBRULE-11] (21/10/2026) - Bảo Mật Che Giấu 100% Hạ Tầng Git/Server/Token & Ma Trận Phân Quyền Công Tắc [0/1]
- **Bối cảnh & Mục tiêu:** Chống rò rỉ token truy cập GitHub Server cá nhân khi phân phối công cụ cho người khác.
- **Tệp tác động:** `rule-manifest.json`, `00-AIConfig/Tools/`.
- **Nội dung thay đổi cốt lõi:**
  1. Mã hóa và che giấu toàn bộ URL repo, Personal Access Token (PAT).
  2. Thiết lập ma trận công tắc [0/1] điều khiển bật/tắt quyền truy cập từng phân hệ.

---

### <a id="tbrule-10"></a> 📦 [TBRULE-10] (21/10/2026) - Phân Phối Thin Client, Sổ Cái Key Chống Crack, Token Rotation Ngầm & Cảnh Báo 15 Ngày
- **Bối cảnh & Mục tiêu:** Xây dựng mô hình phân phối siêu nhẹ cho người dùng cuối (Thin Client); cơ chế cấp phép bản quyền tự động xoay vòng token.
- **Tệp tác động:** `Build-ClientDist.ps1`, `Activate-License.ps1`.
- **Nội dung thay đổi cốt lõi:**
  1. Kịch bản đóng gói xuất xưởng loại bỏ toàn bộ dữ liệu nội bộ và script Admin.
  2. Cơ chế Sổ cái Key bản quyền, cảnh báo gia hạn trước 15 ngày.

---

### <a id="tbrule-09"></a> ☁️ [TBRULE-09] (21/10/2026) - Chuyển Hệ Thống Rule Lên Server GitHub TuanBeoAI & Bộ Công Cụ Đồng Bộ 1-Click
- **Bối cảnh & Mục tiêu:** Đưa kho Rule lên máy chủ GitHub đám mây an toàn, cho phép đồng bộ hóa dữ liệu mọi lúc mọi nơi.
- **Tệp tác động:** `@File-BAT/`, `Push-RuleToServer.ps1`, `Pull-RuleFromServer.ps1`.
- **Nội dung thay đổi cốt lõi:**
  1. Khởi tạo repository `TuanBeoAI` trên GitHub.
  2. Cung cấp bộ phím tắt 1-click đẩy/kéo rule thuận tiện.

---

### <a id="tbrule-08"></a> 🌙 [TBRULE-08] (21/10/2026) - Khóa & Mở Khóa Rule Khi Tan Ca / Vào Ca & Chuẩn Hóa Phím Tắt
- **Bối cảnh & Mục tiêu:** Bảo vệ tài sản trí tuệ khi rời khỏi máy làm việc tại cơ quan.
- **Tệp tác động:** `[ADMIN-500]-Khoa-Rule-Bao-Ve-Tan-Ca.bat`, `[ADMIN-501]-Mo-Khoa-Rule-Vao-Ca.bat`.
- **Nội dung thay đổi cốt lõi:**
  1. Tính năng khóa mã hóa toàn bộ rule khi kết thúc ngày làm việc.
  2. Mở khóa giải mã tức thì khi bắt đầu ca làm việc mới bằng Master Key.

---

### <a id="tbrule-06"></a> 🏷️ [TBRULE-06] (20/10/2026) - Chuẩn Hóa Tiền Tố UserName Trong Log & Vòng Đời Bản Quyền Free / Licensed
- **Bối cảnh & Mục tiêu:** Phân lập nhật ký công việc theo từng tài khoản kỹ sư; hỗ trợ cơ chế dùng thử Free không gián đoạn.
- **Tệp tác động:** `00-AI-MASTER-RULES.md`, `user-profile.md`.
- **Nội dung thay đổi cốt lõi:**
  1. Mọi tệp log phải có tiền tố `[UserName]_...`.
  2. Tự động nạp key Free mặc định khi chưa kích hoạt để không làm gián đoạn công việc.

---

### <a id="tbrule-05"></a> 🔑 [TBRULE-05] (20/10/2026) - Chuẩn Hóa Universal Action Key (UAK), Khóa UserName & Menu Admin
- **Bối cảnh & Mục tiêu:** Đơn giản hóa các thao tác điều khiển của kỹ sư; bảo vệ UserName gốc.
- **Tệp tác động:** `00-AI-MASTER-RULES.md`, `GEMINI.md`.
- **Nội dung thay đổi cốt lõi:**
  1. Phím hành động UAK toàn năng điều phối nhanh các tác vụ.
  2. Khóa cứng trường UserName trong profile cá nhân.

---

### <a id="tbrule-04"></a> 🔗 [TBRULE-04] (20/10/2026) - Chuẩn Hóa Đường Dẫn Tương Đối Đa Máy & Phân Quyền User Whitelist
- **Bối cảnh & Mục tiêu:** Xóa bỏ hoàn toàn tình trạng lỗi đường dẫn tuyệt đối khi clone code sang máy khác.
- **Tệp tác động:** Toàn bộ hệ thống rule.
- **Nội dung thay đổi cốt lõi:**
  1. Chuyển toàn bộ đường dẫn nội bộ sang đường dẫn tương đối tính từ gốc `{AI_ROOT}`.
  2. Phân định rõ 2 vùng: User Whitelist (được sửa) và Protected Core Rules (bảo mật).

---

### <a id="tbrule-03"></a> ⚙️ [TBRULE-03] (20/10/2026) - Nâng Cấp Mã Hóa Rule, KeyManager Admin, Đóng Gói Client & Bộ Lệnh Tạm Ngưng `021`-`024`
- **Bối cảnh & Mục tiêu:** Xây dựng nền móng hệ thống cấp bản quyền và bộ lệnh điều phối tạm hoãn công việc.
- **Tệp tác động:** `00-AI-MASTER-RULES.md`, `GEMINI.md`.
- **Nội dung thay đổi cốt lõi:**
  1. Khởi tạo bộ công cụ KeyManager quản trị bản quyền cho Admin.
  2. Ban hành nhóm mã lệnh tạm ngưng: `021` (New Chat), `022` (Việc gấp), `023` (Task tiền đề), `024` (Việc riêng).

---

### <a id="tbrule-02"></a> 💬 [TBRULE-02] (19/10/2026) - Lưu Vết Comment Đa Phiên & Cổng Đối Soát Khi Chốt Sổ
- **Bối cảnh & Mục tiêu:** Truy vết nguồn gốc mã nguồn qua từng phiên làm việc; chống đóng task khi chưa kiểm tra diff.
- **Tệp tác động:** `00-Global/1-cac-quy-tac-va-quy-uoc-lap-trinh.md`, `GEMINI.md`.
- **Nội dung thay đổi cốt lõi:**
  1. Quy chuẩn thẻ comment code: `/* [TiềnTố][YYYY][WW][D]-[branch]: [Lý do] */`.
  2. Cổng đối soát Git Diff / DB trước khi cho phép chốt sổ task.

---

### <a id="tbrule-01"></a> 🏛️ [TBRULE-01] (19/10/2026) - Chuẩn Hóa Quy Chuẩn Rẽ Nhánh Điều Kiện Theo Trường
- **Bối cảnh & Mục tiêu:** Loại bỏ hoàn toàn lỗi hardcode mã trường trong code C# và SQL gây xung đột khi triển khai đa trường.
- **Tệp tác động:** `00-Global/1-cac-quy-tac-va-quy-uoc-lap-trinh.md`, `09-Database/02-quy-chuan-viet-sql.md`.
- **Nội dung thay đổi cốt lõi:**
  1. Tuyệt đối cấm hardcode số nguyên mã trường (`if (id == 1)`).
  2. Bắt buộc sử dụng Enum `UniversityID` từ Database hoặc tham số truyền vào chuẩn hóa.