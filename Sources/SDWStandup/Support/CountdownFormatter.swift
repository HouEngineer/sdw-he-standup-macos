import Foundation

/// 倒计时文本格式化：1 小时内显示 mm:ss，超过 1 小时显示「X 小时 YY 分」。
enum CountdownFormatter {
    static func text(to date: Date, from now: Date = Date()) -> String {
        let remain = max(0, Int(date.timeIntervalSince(now).rounded()))
        let h = remain / 3600
        let m = remain % 3600 / 60
        let s = remain % 60
        if h > 0 {
            return "\(h) 小时 \(String(format: "%02d", m)) 分"
        }
        return String(format: "%02d:%02d", m, s)
    }
}
