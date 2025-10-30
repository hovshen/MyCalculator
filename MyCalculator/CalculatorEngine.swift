import Foundation

// 運算類型 (保持不變)
enum OperationType: String {
    case add = "+"
    case subtract = "−"
    case multiply = "×"
    case divide = "÷"
    case none = ""
}

// 負責所有計算的狀態和邏輯
struct CalculatorEngine {
    
    // --- 私有狀態 ---
    private var currentInput: String = "0"
    private var firstOperand: Double?
    private var pendingOperation: OperationType = .none
    private var isEnteringDigit: Bool = false
    private var fullExpressionHistory: String = ""
    
    // *** 新增 *** 記憶體狀態
    private var memory: Double = 0.0
    
    // --- 公開的顯示屬性 ---
    var displayValue: String {
        return formatForDisplay(currentInput)
    }
    
    var expressionDescription: String {
        return fullExpressionHistory
    }
    
    var enteringDigit: Bool {
        return isEnteringDigit
    }
    
    // --- 核心邏輯：處理按鈕點擊 (已更新) ---
    mutating func handleTap(_ button: CalculatorButton) {
        switch button {
        case .digit(let value):
            handleDigit(value)
            
        case .operation(let opString):
            handleOperation(opString)
            
        case .function(let funcString):
            handleFunction(funcString)
            
        case .control(let controlString):
            handleControl(controlString)
            
        // *** 新增 *** 處理記憶按鈕
        case .memory(let memString):
            handleMemory(memString)
            
        case .empty:
            break
        }
    }
    
    // --- 私有輔助函式 ---
    
    private mutating func handleDigit(_ digit: String) {
        if !isEnteringDigit {
            currentInput = digit
            isEnteringDigit = true
        } else if currentInput.count < 15 {
            if currentInput == "0" && digit != "." {
                currentInput = digit
            } else if digit == "." && currentInput.contains(".") {
                return
            }
            else {
                currentInput += digit
            }
        }
    }
    
    private mutating func handleOperation(_ opString: String) {
        isEnteringDigit = false
        guard let inputValue = Double(currentInput) else { return }
        
        if opString == "=" {
            if pendingOperation != .none && firstOperand != nil {
                let result = performCalculation(inputValue)
                fullExpressionHistory = "\(formatForDisplay(String(firstOperand!))) \(pendingOperation.rawValue) \(formatForDisplay(String(inputValue))) ="
                currentInput = String(result)
                resetPendingOperation()
            }
        }
        else if let op = OperationType(rawValue: opString) {
            if firstOperand == nil {
                firstOperand = inputValue
                fullExpressionHistory = "\(formatForDisplay(currentInput)) \(op.rawValue)"
            } else {
                let result = performCalculation(inputValue)
                firstOperand = result
                currentInput = String(result)
                fullExpressionHistory = "\(formatForDisplay(currentInput)) \(op.rawValue)"
            }
            pendingOperation = op
        }
    }
    
    // *** (已更新) *** 加入更多數學函數
    private mutating func handleFunction(_ funcString: String) {
        guard let inputValue = Double(currentInput) else { return }
        var result: Double?
        
        switch funcString {
        // --- 基本 ---
        case "x²":
            result = inputValue * inputValue
            fullExpressionHistory = "(\(formatForDisplay(currentInput)))²"
        case "%":
            result = inputValue / 100.0
            fullExpressionHistory = "(\(formatForDisplay(currentInput)))%"
        case "¹/ₓ":
            if inputValue == 0 { result = 0 }
            else { result = 1.0 / inputValue }
            fullExpressionHistory = "1/(\(formatForDisplay(currentInput)))"
            
        // --- 新增：指數與次方 ---
        case "x³":
            result = pow(inputValue, 3)
            fullExpressionHistory = "(\(formatForDisplay(currentInput)))³"
        case "eˣ":
            result = exp(inputValue)
            fullExpressionHistory = "e^(\(formatForDisplay(currentInput)))"
        case "10ˣ":
            result = pow(10, inputValue)
            fullExpressionHistory = "10^(\(formatForDisplay(currentInput)))"

        // --- 新增：根號 ---
        case "²√x":
            result = sqrt(inputValue)
            fullExpressionHistory = "√(\(formatForDisplay(currentInput)))"
        case "³√x":
            result = cbrt(inputValue)
            fullExpressionHistory = "∛(\(formatForDisplay(currentInput)))"
            
        // --- 新增：常數與隨機 ---
        case "π":
            currentInput = String(Double.pi)
            isEnteringDigit = true
            fullExpressionHistory = ""
            return // 提前返回
        case "e":
            currentInput = String(M_E) // Euler's number
            isEnteringDigit = true
            fullExpressionHistory = ""
            return
        case "Rand":
            result = Double.random(in: 0...1)
            fullExpressionHistory = "rand()"
            
        // --- 新增：階乘 ---
        case "x!":
            if inputValue < 0 || inputValue != floor(inputValue) { result = .nan } // 階乘只適用非負整數
            else if inputValue > 20 { result = .infinity } // 避免過大
            else {
                result = (1...Int(max(1, inputValue))).map(Double.init).reduce(1, *)
            }
            fullExpressionHistory = "(\(formatForDisplay(currentInput)))!"
            
        // --- Log (已存在) ---
        case "ln":
            result = log(inputValue)
            fullExpressionHistory = "ln(\(formatForDisplay(currentInput)))"
        case "log₁₀":
            result = log10(inputValue)
            fullExpressionHistory = "log₁₀(\(formatForDisplay(currentInput)))"
            
        // --- Trig (已存在) ---
        case "sin": result = sin(inputValue); fullExpressionHistory = "sin(\(formatForDisplay(currentInput)))"
        case "cos": result = cos(inputValue); fullExpressionHistory = "cos(\(formatForDisplay(currentInput)))"
        case "tan": result = tan(inputValue); fullExpressionHistory = "tan(\(formatForDisplay(currentInput)))"

        // --- 新增：雙曲函數 ---
        case "sinh": result = sinh(inputValue); fullExpressionHistory = "sinh(\(formatForDisplay(currentInput)))"
        case "cosh": result = cosh(inputValue); fullExpressionHistory = "cosh(\(formatForDisplay(currentInput)))"
        case "tanh": result = tanh(inputValue); fullExpressionHistory = "tanh(\(formatForDisplay(currentInput)))"
            
        // ... 尚未實作的 ...
        default:
            print("尚未實作: \(funcString)")
            break
        }
        
        if let res = result {
            if res.isNaN { currentInput = "錯誤" }
            else if res.isInfinite { currentInput = "無限" }
            else { currentInput = String(res) }
            isEnteringDigit = false
        }
    }
    
    // *** (已更新) *** AC 現在也會清除記憶體
    private mutating func handleControl(_ controlString: String) {
        if controlString == "AC" {
            currentInput = "0"
            resetPendingOperation()
            isEnteringDigit = false
            fullExpressionHistory = ""
            memory = 0.0 // AC 也清除記憶
        } else if controlString == "C" {
            currentInput = "0"
            isEnteringDigit = true
        }
    }
    
    // *** 新增 *** 處理記憶功能的函式
    private mutating func handleMemory(_ memString: String) {
        guard let inputValue = Double(currentInput) else { return }
        
        switch memString {
        case "m+":
            memory += inputValue
            isEnteringDigit = false
        case "m-":
            memory -= inputValue
            isEnteringDigit = false
        case "mc":
            memory = 0.0
        case "mr":
            currentInput = String(memory)
            isEnteringDigit = true // 將記憶數字放入輸入框
        default:
            break
        }
    }
    
    private mutating func resetPendingOperation() {
        firstOperand = nil
        pendingOperation = .none
    }
    
    private func performCalculation(_ secondOperand: Double) -> Double {
        guard let first = firstOperand else { return secondOperand }
        
        switch pendingOperation {
        case .add: return first + secondOperand
        case .subtract: return first - secondOperand
        case .multiply: return first * secondOperand
        case .divide: return secondOperand == 0 ? 0 : first / secondOperand
        case .none: return secondOperand
        }
    }
    
    // 格式化輸出 (保持不變)
    private func formatForDisplay(_ value: String) -> String {
        guard let num = Double(value) else { return "錯誤" }
        
        if num.isNaN { return "錯誤" }
        if num.isInfinite { return "無限" }
        
        if num == floor(num) {
            return String(Int(num))
        }
        
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 8
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: num)) ?? "錯誤"
    }
}
