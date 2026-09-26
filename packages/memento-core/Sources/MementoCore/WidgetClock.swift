import Foundation

/// Entries only when the displayed day changes or the reference is reached.
/// The system renders the second-by-second timer without waking the extension.
public enum WidgetClock {
    public static func dates(profile: Profile, now: Date = Date(), timeZone: TimeZone = .current) throws -> [Date] {
        let value = try Life.snapshot(profile, now: now, timeZone: timeZone)
        guard !value.passed else { return [now] }
        var dates = [now]
        let next = value.end.addingTimeInterval(-Double(value.days) * 86400 + 1)
        for offset in 0..<7 {
            let date = next.addingTimeInterval(Double(offset) * 86400)
            if date > now && date < value.end { dates.append(date) }
        }
        if let last = dates.last, value.end.timeIntervalSince(last) <= 86400 { dates.append(value.end) }
        return dates
    }
}
