# Quy tắc triển khai

**Archive notice (2026-07-10)**: Các scope lock/commit rule dưới đây chỉ áp dụng cho kế hoạch M01-M14 đã hoàn thành; không áp dụng mặc định cho task hiện tại.

## 1. Scope Lock
- Mỗi module chỉ sửa **files đã liệt kê** trong spec module đó.
- KHÔNG lan sang file khác dù thấy issue.
- Nếu phát hiện issue mới → ghi vào `handoff/issues_backlog.md`, KHÔNG sửa.

## 2. Commit nhỏ
- 1 module = 1 commit (hoặc 2 nếu module lớn: code + test).
- Format: `fix(M01): mô tả ngắn`
- Prefix theo loại: `fix`, `feat`, `refactor`, `perf`, `chore`, `test`

## 3. Build Gate
- Sau mỗi module **BẮT BUỘC** chạy:
  ```bash
  flutter analyze
  flutter test
  ```
- Cả 2 phải pass trước khi commit.
- Nếu fail → fix trong scope module đó, không skip.

## 4. Không refactor lan rộng
- KHÔNG đổi architecture (Clean Architecture + Riverpod giữ nguyên).
- KHÔNG rename folder structure.
- KHÔNG rewrite toàn bộ file — chỉ sửa đoạn code liên quan.
- KHÔNG thêm package mới trừ khi module yêu cầu rõ ràng.

## 5. Acceptance Criteria
- Mỗi module có danh sách acceptance criteria trong file `modules/Mxx_*.md`.
- Check từng criteria trước khi đánh dấu hoàn thành.

## 6. Handoff
- Sau khi xong 1 module → cập nhật `handoff/current_status.md`.
- Ghi lại quyết định kỹ thuật vào `handoff/decisions.md`.
- Issues ngoài scope → `handoff/issues_backlog.md`.

## 7. Test trên device
- Modules liên quan camera (M07) cần test trên device/emulator thật.
- Modules liên quan Supabase (M03, M04, M12) nên verify với backend thật nếu có.

## 8. Vietnamese text
- Tất cả user-facing strings phải có dấu tiếng Việt đầy đủ.
- Error messages, labels, button text → tiếng Việt.
- Code comments, commit messages → tiếng Anh hoặc tiếng Việt đều OK.
