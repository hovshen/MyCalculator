import Foundation
import Combine
import SwiftUI // 導入 SwiftUI 以便使用 Color

// ObservableObject 讓 SwiftUI 視圖可以 "觀察" 它的變化
class CalculatorViewModel: ObservableObject {
    
    // --- Published 屬性 ---
    @Published var displayText: String = "0"
    @Published var fullExpressionText: String = ""
    @Published var isEnteringDigit: Bool = false
    
    // --- 私有屬性 ---
    private var engine = CalculatorEngine()
    
    // --- 按鈕佈局 ---
    let buttonLayout: [[CalculatorButton]] = [
        [
            .function("("), .function(")"), .memory("mc"), .memory("m+"), .memory("m-"), .memory("mr"),
            .control("AC"), .function("x²"), .function("%"), .operation("÷")
        ],
        [
            .function("2nd"), .function("x³"), .function("xʸ"), .function("eˣ"), .function("10ˣ"), .function("¹/ₓ"),
            .digit("7"), .digit("8"), .digit("9"), .operation("×")
        ],
        [
            .function("²√x"), .function("³√x"), .function("ʸ√x"), .function("ln"), .function("log₁₀"), .function("x!"),
            .digit("4"), .digit("5"), .digit("6"), .operation("−")
        ],
        [
            .function("sin"), .function("cos"), .function("tan"), .function("e"), .function("EE"), .function("Rand"),
            .digit("1"), .digit("2"), .digit("3"), .operation("+")
        ],
        [
            .function("sinh"), .function("cosh"), .function("tanh"), .function("π"), .function("Rad"), .empty,
            .digit("0"), .digit("."), .operation("=")
        ]
    ]
    
    // --- 按鈕點擊處理 ---
    func buttonTapped(_ button: CalculatorButton) {
        
        // 將點擊事件轉發給引擎
        engine.handleTap(button)
        
        // 從引擎更新顯示
        self.displayText = engine.displayValue
        self.fullExpressionText = engine.expressionDescription
        self.isEnteringDigit = engine.enteringDigit
    }
    
    // --- 輔助函式 (供 View 使用) ---
    
    // 讓 View 可以根據狀態知道 AC 按鈕的文字
    func getControlButtonTitle() -> String {
        return isEnteringDigit ? "C" : "AC"
    }
    
    // 讓 View 可以根據狀態知道 AC 按鈕的行為
    func getControlButtonAction() -> CalculatorButton {
        // "C" 只清除當前輸入, "AC" 清除所有
        return isEnteringDigit ? .control("C") : .control("AC")
    }
    
    // 讓 View 可以取得按鈕的顏色
    func getBackgroundColor(for button: CalculatorButton) -> Color {
        switch button {
        case .digit, .memory:
            return Color(hex: "505050") // 深灰
        case .operation:
            return .orange // 橘色
        case .control, .function:
             // 匹配所有 function 和 control
            return Color(hex: "A5A5A5") // 淺灰
        case .empty:
            return .clear
        }
    }
    
    // 讓 View 取得文字顏色
    func getForegroundColor(for button: CalculatorButton) -> Color {
        switch button {
        case .control, .function:
            return .black // 淺灰底配黑字
        default:
            return .white // 其他都是白字
        }
    }
}
