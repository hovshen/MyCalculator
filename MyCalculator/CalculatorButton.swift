import Foundation
import SwiftUI

// 使用 enum 來定義所有可能的按鈕
enum CalculatorButton: Hashable, Identifiable {
    case digit(String)          // 數字 0-9
    case operation(String)      // +, −, ×, ÷, =
    case control(String)        // AC, C (我們用 "AC" 代表這個位置, "C" 是動態的)
    case function(String)       // x², %, π, sin, cos, etc.
    case memory(String)         // mc, m+, m-
    case empty                  // 用於佈局的空白格

    // 'id' 是 'Identifiable' 協議所必需的，方便 SwiftUI 遍歷
    var id: String {
        return self.title
    }

    // 按鈕上顯示的文字
    var title: String {
        switch self {
        case .digit(let val):     return val
        case .operation(let val): return val
        case .control(let val):   return val
        case .function(let val):  return val
        case .memory(let val):    return val
        case .empty:              return ""
        }
    }

    // 按鈕佔用的網格寬度 (用於實現 '0' 按鈕)
    var span: Int {
        if case .digit("0") = self {
            return 2 // "0" 佔 2 格
        }
        return 1 // 其他佔 1 格
    }
}

// 輔助工具：讓我們可以用 16 進位色碼
// (這個 extension 保持不變)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
