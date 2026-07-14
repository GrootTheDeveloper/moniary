import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), balance: "12,500,000 ₫", spend: "250,000 ₫")
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
        return SimpleEntry(date: Date(), balance: balance, spend: spend)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let balance: String
    let spend: String
}

struct MoniaryWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "wallet.pass.fill")
                    .foregroundColor(Color(red: 0.4, green: 0.9, blue: 0.8)) // mint green
                    .imageScale(.medium)
                Text("Moniary")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.bottom, 12)

            VStack(alignment: .leading, spacing: 2) {
                Text("Số dư tổng")
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
                Text("Chi tiêu hôm nay")
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
                            Text("Ghi chép")
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
                            Text("Quét ảnh")
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
                .containerBackground(Color(red: 0.05, green: 0.05, blue: 0.07), for: .widget) // dark premium background
        }
        .configurationDisplayName("Moniary")
        .description("Xem nhanh số dư và chi tiêu hôm nay của bạn.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    MoniaryWidget()
} timeline: {
    SimpleEntry(date: .now, balance: "12,500,000 ₫", spend: "250,000 ₫")
}

#Preview(as: .systemMedium) {
    MoniaryWidget()
} timeline: {
    SimpleEntry(date: .now, balance: "12,500,000 ₫", spend: "250,000 ₫")
}
