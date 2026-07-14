import WidgetKit
import SwiftUI

// ── Date Extension helpers for Calendar rendering ──────────────────────────────
extension Date {
    func startOfMonth() -> Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Calendar.current.startOfDay(for: self)))!
    }
    
    func daysInMonth() -> Int {
        Calendar.current.range(of: .day, in: .month, for: self)!.count
    }
}

// ── Widget Bundle ─────────────────────────────────────────────────────────────
@main
struct MoniaryWidgetsBundle: WidgetBundle {
    var body: some Widget {
        MoniaryWidget()
        MoniaryStreakCalendarWidget()
        MoniaryBudgetWidget()
    }
}

// ── Timeline Provider (Shared) ────────────────────────────────────────────────
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            balance: "12,500,000 ₫",
            spend: "250,000 ₫",
            labelBalance: "Số dư tổng",
            labelSpend: "Chi tiêu hôm nay",
            labelQuickAdd: "Ghi chép",
            labelScanReceipt: "Quét ảnh",
            userName: "Hoàng",
            streak: 3,
            longestStreak: 5,
            recordedDays: [],
            labelStreak: "Chuỗi ghi",
            labelLongest: "Kỷ lục",
            labelDays: "3 ngày",
            labelLongestDays: "5 ngày",
            budgetLimit: "10,000,000 ₫",
            budgetSpent: "3,200,000 ₫",
            budgetRemaining: "6,800,000 ₫",
            budgetProgress: 0.32,
            labelBudget: "Ngân sách",
            labelBudgetSpent: "Đã chi",
            labelBudgetRemaining: "Còn lại",
            labelOverBudget: "Vượt hạn mức"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = getLatestEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let entry = getLatestEntry()
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }

    private func getLatestEntry() -> SimpleEntry {
        let defaults = UserDefaults(suiteName: "group.com.moniary")
        let balance = defaults?.string(forKey: "total_balance") ?? "0 ₫"
        let spend = defaults?.string(forKey: "today_spending") ?? "0 ₫"
        let labelBalance = defaults?.string(forKey: "total_balance_label") ?? "Số dư tổng"
        let labelSpend = defaults?.string(forKey: "today_spending_label") ?? "Chi tiêu hôm nay"
        let labelQuickAdd = defaults?.string(forKey: "quick_add_label") ?? "Ghi chép"
        let labelScanReceipt = defaults?.string(forKey: "scan_receipt_label") ?? "Quét ảnh"
        
        let userName = defaults?.string(forKey: "user_name") ?? ""
        let streak = defaults?.integer(forKey: "recording_streak") ?? 0
        let longestStreak = defaults?.integer(forKey: "longest_streak") ?? 0
        
        let recordedDaysJson = defaults?.string(forKey: "recorded_days_json") ?? "[]"
        var recordedDays: [String] = []
        if let data = recordedDaysJson.data(using: .utf8) {
            recordedDays = (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        
        let labelStreak = defaults?.string(forKey: "label_streak") ?? "Chuỗi ghi"
        let labelLongest = defaults?.string(forKey: "label_longest") ?? "Kỷ lục"
        let labelDays = defaults?.string(forKey: "label_days") ?? "\(streak) ngày"
        let labelLongestDays = defaults?.string(forKey: "label_longest_days") ?? "\(longestStreak) ngày"
        
        let budgetLimit = defaults?.string(forKey: "budget_limit") ?? "0 ₫"
        let budgetSpent = defaults?.string(forKey: "budget_spent") ?? "0 ₫"
        let budgetRemaining = defaults?.string(forKey: "budget_remaining") ?? "0 ₫"
        let budgetProgress = defaults?.double(forKey: "budget_progress") ?? 0.0
        
        let labelBudget = defaults?.string(forKey: "label_budget") ?? "Ngân sách"
        let labelBudgetSpent = defaults?.string(forKey: "label_budget_spent") ?? "Đã chi"
        let labelBudgetRemaining = defaults?.string(forKey: "label_budget_remaining") ?? "Còn lại"
        let labelOverBudget = defaults?.string(forKey: "label_over_budget") ?? "Vượt hạn mức"
        
        return SimpleEntry(
            date: Date(),
            balance: balance,
            spend: spend,
            labelBalance: labelBalance,
            labelSpend: labelSpend,
            labelQuickAdd: labelQuickAdd,
            labelScanReceipt: labelScanReceipt,
            userName: userName,
            streak: streak,
            longestStreak: longestStreak,
            recordedDays: recordedDays,
            labelStreak: labelStreak,
            labelLongest: labelLongest,
            labelDays: labelDays,
            labelLongestDays: labelLongestDays,
            budgetLimit: budgetLimit,
            budgetSpent: budgetSpent,
            budgetRemaining: budgetRemaining,
            budgetProgress: budgetProgress,
            labelBudget: labelBudget,
            labelBudgetSpent: labelBudgetSpent,
            labelBudgetRemaining: labelBudgetRemaining,
            labelOverBudget: labelOverBudget
        )
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let balance: String
    let spend: String
    let labelBalance: String
    let labelSpend: String
    let labelQuickAdd: String
    let labelScanReceipt: String
    
    let userName: String
    let streak: Int
    let longestStreak: Int
    let recordedDays: [String]
    let labelStreak: String
    let labelLongest: String
    let labelDays: String
    let labelLongestDays: String
    
    let budgetLimit: String
    let budgetSpent: String
    let budgetRemaining: String
    let budgetProgress: Double
    let labelBudget: String
    let labelBudgetSpent: String
    let labelBudgetRemaining: String
    let labelOverBudget: String
}

// ── Widget 1: Moniary Dashboard Widget ─────────────────────────────────────────
struct MoniaryWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 6) {
                Image(systemName: "wallet.pass.fill")
                    .foregroundColor(Color(red: 0.4, green: 0.9, blue: 0.8)) // mint green
                    .imageScale(.medium)
                Text("Moniary")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                if entry.streak > 0 {
                    HStack(spacing: 2) {
                        Text("🔥")
                            .font(.system(size: 9))
                        Text("\(entry.streak)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(6)
                }
                
                Spacer()
            }
            .padding(.bottom, 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.labelBalance)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.gray)
                Text(entry.balance)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
            .padding(.bottom, 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.labelSpend)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.gray)
                Text(entry.spend)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4)) // soft red
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }

            if family == .systemMedium {
                Spacer()
                HStack(spacing: 12) {
                    Link(destination: URL(string: "moniary://quick-add")!) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .imageScale(.small)
                            Text(entry.labelQuickAdd)
                                .font(.system(size: 11, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(red: 0.4, green: 0.9, blue: 0.8).opacity(0.15))
                        .foregroundColor(Color(red: 0.4, green: 0.9, blue: 0.8))
                        .cornerRadius(10)
                    }

                    Link(destination: URL(string: "moniary://scan-receipt")!) {
                        HStack(spacing: 4) {
                            Image(systemName: "camera.fill")
                                .imageScale(.small)
                            Text(entry.labelScanReceipt)
                                .font(.system(size: 11, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.08))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding(14)
    }
}

struct MoniaryWidget: Widget {
    let kind: String = "MoniaryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MoniaryWidgetEntryView(entry: entry)
                .containerBackground(Color(red: 0.05, green: 0.05, blue: 0.07), for: .widget)
        }
        .configurationDisplayName("Moniary Dashboard")
        .description("Xem nhanh số dư và chi tiêu hôm nay của bạn.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// ── Widget 2: Moniary Streak Calendar Widget ────────────────────────────────────
struct Streak14DayRowView: View {
    let recordedDays: [String]
    let currentDate = Date()
    
    var body: some View {
        let calendar = Calendar.current
        HStack(spacing: 4) {
            ForEach((0..<14).reversed(), id: \.self) { dayOffset in
                let date = calendar.date(byAdding: .day, value: -dayOffset, to: currentDate)!
                let dayNum = calendar.component(.day, from: date)
                let dateStr = String(format: "%d-%02d-%02d", calendar.component(.year, from: date), calendar.component(.month, from: date), dayNum)
                let isRecorded = recordedDays.contains(dateStr)
                
                VStack(spacing: 4) {
                    Text(String(format: "%02d", dayNum))
                        .font(.system(size: 8))
                        .foregroundColor(.gray)
                    
                    Circle()
                        .fill(isRecorded ? Color.orange : Color.white.opacity(0.1))
                        .frame(width: 13, height: 13)
                        .overlay(
                            Group {
                                if isRecorded {
                                    Text("✓")
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                        )
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct StreakCalendarGridView: View {
    let recordedDays: [String]
    let currentDate = Date()
    
    var body: some View {
        let calendar = Calendar.current
        let startOfMonth = currentDate.startOfMonth()
        let daysCount = currentDate.daysInMonth()
        let startWeekday = calendar.component(.weekday, from: startOfMonth)
        let offset = (startWeekday + 5) % 7
        
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        let weekdayLabels = ["M", "T", "W", "T", "F", "S", "S"]
        
        VStack(spacing: 4) {
            HStack(spacing: 0) {
                ForEach(weekdayLabels, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            
            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(0..<offset, id: \.self) { _ in
                    Text("")
                        .font(.system(size: 8))
                        .frame(height: 12)
                }
                
                ForEach(1...daysCount, id: \.self) { day in
                    let dateStr = String(format: "%d-%02d-%02d", calendar.component(.year, from: currentDate), calendar.component(.month, from: currentDate), day)
                    let isRecorded = recordedDays.contains(dateStr)
                    
                    Text("\(day)")
                        .font(.system(size: 8, weight: isRecorded ? .bold : .regular))
                        .foregroundColor(isRecorded ? .white : .gray)
                        .frame(height: 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            Group {
                                if isRecorded {
                                    Circle()
                                        .fill(Color.orange)
                                } else {
                                    Color.clear
                                }
                            }
                        )
                }
            }
        }
    }
}

struct MoniaryStreakCalendarWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .center, spacing: 6) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.orange)
                    .imageScale(.medium)
                Text(entry.labelStreak)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                if entry.streak > 0 {
                    Text("🔥 \(entry.labelDays)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.orange)
                }
                
                Spacer()
            }
            .padding(.bottom, 10)

            if family == .systemMedium {
                // Streak Stats Summary
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.labelLongest)
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(.gray)
                        Text(entry.labelLongestDays)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(.bottom, 6)

                // 14-day row tracker
                Streak14DayRowView(recordedDays: entry.recordedDays)
            } else if family == .systemLarge {
                // Large layout shows full month grid
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        if !entry.userName.isEmpty {
                            Text(entry.userName)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                        
                        Text(entry.labelStreak)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.gray)
                        Text(entry.labelDays)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.bottom, 4)

                        Text(entry.labelLongest)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.gray)
                        Text(entry.labelLongestDays)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.orange)
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    // Calendar grid
                    VStack(alignment: .leading, spacing: 4) {
                        StreakCalendarGridView(recordedDays: entry.recordedDays)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(14)
    }
}

struct MoniaryStreakCalendarWidget: Widget {
    let kind: String = "MoniaryStreakCalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MoniaryStreakCalendarWidgetEntryView(entry: entry)
                .containerBackground(Color(red: 0.05, green: 0.05, blue: 0.07), for: .widget)
        }
        .configurationDisplayName("Moniary Streak")
        .description("Theo dõi chuỗi ngày ghi chép chi tiêu liên tục của bạn.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// ── Widget 3: Moniary Budget Widget ─────────────────────────────────────────────
struct CircularProgressView: View {
    let progress: Double
    let labelProgress: String
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 5)
                .opacity(0.1)
                .foregroundColor(.blue)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                .foregroundColor(progress > 1.0 ? .red : .blue)
                .rotationEffect(Angle(degrees: -90))
            
            Text(labelProgress)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

struct MoniaryBudgetWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        let isOver = entry.budgetProgress > 1.0
        
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .center, spacing: 6) {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(isOver ? .red : .blue)
                    .imageScale(.medium)
                Text(entry.labelBudget)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                if isOver {
                    Text(entry.labelOverBudget)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.red)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.red.opacity(0.15))
                        .cornerRadius(4)
                }
                
                Spacer()
            }
            .padding(.bottom, 12)

            if family == .systemSmall {
                // Linear Progress bar and remaining amount
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.labelBudgetRemaining)
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(.gray)
                    Text(entry.budgetRemaining)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(isOver ? .red : .white)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                    
                    // Simple Linear Bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(isOver ? Color.red : Color.blue)
                                .frame(width: geo.size.width * CGFloat(min(entry.budgetProgress, 1.0)), height: 6)
                        }
                    }
                    .frame(height: 6)
                    .padding(.top, 4)
                    
                    Text(String(format: "%.0f%%", entry.budgetProgress * 100))
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.gray)
                }
            } else if family == .systemMedium {
                // Side-by-side circular layout
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(entry.labelBudgetSpent)
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundColor(.gray)
                            Text(entry.budgetSpent)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(entry.labelBudgetRemaining)
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundColor(.gray)
                            Text(entry.budgetRemaining)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(isOver ? .red : Color(red: 0.4, green: 0.9, blue: 0.8))
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    // Circular progress dial
                    CircularProgressView(
                        progress: entry.budgetProgress,
                        labelProgress: String(format: "%.0f%%", entry.budgetProgress * 100)
                    )
                    .frame(width: 54, height: 54)
                }
            }
        }
        .padding(14)
    }
}

struct MoniaryBudgetWidget: Widget {
    let kind: String = "MoniaryBudgetWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MoniaryBudgetWidgetEntryView(entry: entry)
                .containerBackground(Color(red: 0.05, green: 0.05, blue: 0.07), for: .widget)
        }
        .configurationDisplayName("Moniary Budget")
        .description("Giám sát tiến trình chi tiêu theo hạn mức ngân sách tháng.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
