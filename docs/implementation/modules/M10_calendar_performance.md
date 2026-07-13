# M10 — Calendar Performance

## Goal
Giảm API calls và improve render performance cho calendar screen.

## Review Issues Handled
- #9: `SupabaseImage` trong calendar day cells → 30+ signed URL API calls mỗi render
- #22: `CalendarMonthData` computed getters tính lại mỗi lần access
- #4.3: `day_detail` dùng spread `...transactions.map()` → không lazy-load

## Severity: 🟠 Medium
## Difficulty: Medium (~1 giờ)
## Dependencies: M09 (shared utils đã extract)

## Scope Lock
CHỈ sửa 4 files dưới đây. KHÔNG sửa file khác.

## Files to Change

| # | File | Thay đổi |
|---|---|---|
| 1 | `lib/features/calendar/domain/month/calendar_month_data.dart` | Computed getters → `late final` cached |
| 2 | `lib/features/calendar/domain/month/calendar_filters.dart` | Thêm `==` và `hashCode` |
| 3 | `lib/features/calendar/presentation/month/calendar_screen.dart` | Bỏ SupabaseImage → dot indicator |
| 4 | `lib/features/transactions/presentation/detail/day_detail_screen.dart` | Spread → `ListView.builder` |

## Step-by-step Implementation

1. `calendar_month_data.dart`:
   - Đổi `get incomeTotal =>` → `late final incomeTotal =`
   - Đổi `get expenseTotal =>` → `late final expenseTotal =`
   - Đổi `get activeDays =>` → `late final activeDays =`
   - Giữ nguyên logic tính toán

2. `calendar_filters.dart`:
   - Thêm `@override operator ==` so sánh tất cả fields
   - Thêm `@override int get hashCode` dùng `Object.hash(...)`

3. `calendar_screen.dart`:
   - Tìm `_CalendarDayCell` widget
   - Tìm `SupabaseImage` bên trong
   - Thay bằng dot indicator: `Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: mintColor))`

4. `day_detail_screen.dart`:
   - Tìm `...transactions.map((txn) => ...)` spread
   - Đổi sang `ListView.builder(itemCount: transactions.length, itemBuilder: ...)`

5. Chạy build gate

## Acceptance Criteria
- [ ] Calendar không load image cho mỗi cell (0 API calls cho images)
- [ ] Computed getters cached — chỉ tính 1 lần
- [ ] Day detail dùng lazy list builder
- [ ] CalendarFilters có proper equality
- [ ] `flutter analyze` pass

## Test/Build Commands
```bash
flutter analyze
flutter test
```

## Risks
Medium. Bỏ SupabaseImage cần đảm bảo UI vẫn đẹp với indicator thay thế.

## Dev Prompt
```
Bạn là Flutter engineer. Improve calendar performance trong Moniary:

1. calendar_month_data.dart: computed getters → late final
2. calendar_filters.dart: thêm == và hashCode
3. calendar_screen.dart: thay SupabaseImage trong day cells bằng dot indicator
4. day_detail_screen.dart: spread → ListView.builder

Chạy: flutter analyze && flutter test
```

## Handoff Checklist
- [ ] Code changed
- [ ] `flutter analyze` pass
- [ ] `flutter test` pass
- [ ] Commit: `perf(M10): remove SupabaseImage from calendar cells + cache getters + lazy list`
- [ ] Update `../handoff/current_status.md`
- [ ] Ghi issues mới (nếu có) vào `../handoff/issues_backlog.md`
