import Foundation

public enum SplitSeconds {
    public static func text(_ seconds: Int64) -> String {
        let value = max(0, seconds)
        guard value >= 1_000_000 else { return "\(value.formatted(.number.locale(Locale(identifier: "en_US"))))초" }
        let prefix = (value / 1_000_000).formatted(.number.locale(Locale(identifier: "en_US")))
        let tail = value % 1_000_000
        return "\(prefix),\n\(String(format: "%03lld,%03lld", tail / 1_000, tail % 1_000))초"
    }
}
