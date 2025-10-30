import SwiftUI
import Foundation
#if canImport(PhotosUI)
import PhotosUI
#endif
#if canImport(Vision)
import Vision
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif
import ImageIO

// 定義可用的模式
enum CalculatorMode: String, CaseIterable, Identifiable {
    case standard = "科學計算機"
    case twoVar = "二元一次聯立方程式"
    case threeVar = "三元一次聯立方程式"
    case photo = "拍照解題"
    
    var id: String { self.rawValue }
}

struct ContentView: View {
    @State private var selectedMode: CalculatorMode = .standard

    private let fixedWidth: CGFloat = 720
    private let fixedHeight: CGFloat = 900

    var body: some View {
        VStack(spacing: 0) {
            
            // --- 模式選擇器 (已改用自訂樣式) ---
            HStack(spacing: 5) {
                ForEach(CalculatorMode.allCases) { mode in
                    Button(action: {
                        selectedMode = mode
                    }) {
                        Text(mode.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 5)
                            .background(selectedMode == mode ? Color.orange : Color(hex: "505050"))
                            .foregroundColor(selectedMode == mode ? .white : Color(hex: "D3D3D3")) // 讓未選中的更亮
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color.black)
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 5) // 增加一點和內容的間距

            
            // --- 內容切換 ---
            Group {
                switch selectedMode {
                case .standard:
                    CalculatorView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .twoVar:
                    EquationSolverView(mode: .twoVar)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .threeVar:
                    EquationSolverView(mode: .threeVar)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .photo:
                    PhotoSolverView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .frame(width: fixedWidth, height: fixedHeight)
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}


// --- 方程式求解器視圖 ---
struct EquationSolverView: View {
    var mode: CalculatorMode

    @State private var coefficients: [[String]]
    @State private var constants: [String]
    @State private var solution: [Double]? = nil
    @State private var errorMessage: String? = nil

    private let fieldWidth: CGFloat = 70

    init(mode: CalculatorMode) {
        self.mode = mode
        let variableCount = mode == .twoVar ? 2 : 3
        _coefficients = State(initialValue: Array(repeating: Array(repeating: "", count: variableCount), count: variableCount))
        _constants = State(initialValue: Array(repeating: "", count: variableCount))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(mode.rawValue)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 16) {
                ForEach(coefficients.indices, id: \.self) { row in
                    equationRow(for: row)
                }
            }

            HStack(spacing: 16) {
                Button(action: solveSystem) {
                    Text("計算")
                        .font(.system(size: 16, weight: .semibold))
                        .padding(.vertical, 10)
                        .frame(width: 120)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Button(action: clearInputs) {
                    Text("清除")
                        .font(.system(size: 16, weight: .semibold))
                        .padding(.vertical, 10)
                        .frame(width: 120)
                        .background(Color(hex: "505050"))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }

            if let solution = solution {
                VStack(alignment: .leading, spacing: 8) {
                    Text("解答")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    ForEach(solution.indices, id: \.self) { index in
                        Text("\(variableSymbols[index]) = \(formatSolution(solution[index]))")
                            .foregroundColor(.white)
                    }
                }
            }

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.system(size: 15, weight: .medium))
            }

            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.black)
    }

    private var variableSymbols: [String] {
        switch mode {
        case .twoVar: return ["x", "y"]
        case .threeVar: return ["x", "y", "z"]
        default: return []
        }
    }

    @ViewBuilder
    private func equationRow(for row: Int) -> some View {
        let lastColumnIndex = coefficients[row].count - 1

        HStack(spacing: 8) {
            ForEach(coefficients[row].indices, id: \.self) { column in
                EquationInputField(text: $coefficients[row][column], placeholder: "0", width: fieldWidth)

                Text(variableSymbols[column])
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .medium))

                if column < lastColumnIndex {
                    Text("+")
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .medium))
                } else {
                    Text("=")
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .medium))
                }
            }

            EquationInputField(text: $constants[row], placeholder: "0", width: fieldWidth)
        }
    }

    private func solveSystem() {
        errorMessage = nil
        solution = nil

        do {
            let numericCoefficients = try coefficients.map { row in
                try row.map { try parseValue($0) }
            }
            let numericConstants = try constants.map { try parseValue($0) }

            guard let answers = gaussianElimination(coefficients: numericCoefficients, constants: numericConstants) else {
                errorMessage = "此聯立方程式沒有唯一解。"
                return
            }

            solution = answers
        } catch let parseError as EquationInputError {
            switch parseError {
            case .invalidNumber:
                errorMessage = "請輸入有效的數字。"
            }
        } catch {
            errorMessage = "發生未知錯誤。"
        }
    }

    private func clearInputs() {
        for row in coefficients.indices {
            for column in coefficients[row].indices {
                coefficients[row][column] = ""
            }
        }
        for index in constants.indices {
            constants[index] = ""
        }
        solution = nil
        errorMessage = nil
    }

    private func parseValue(_ text: String) throws -> Double {
        guard let value = Double(text.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw EquationInputError.invalidNumber
        }
        return value
    }

    private func gaussianElimination(coefficients: [[Double]], constants: [Double]) -> [Double]? {
        let n = constants.count
        guard coefficients.count == n else { return nil }
        var augmentedMatrix = coefficients
        var resultVector = constants

        for pivot in 0..<n {
            var maxRow = pivot
            var maxValue = abs(augmentedMatrix[pivot][pivot])

            for row in (pivot + 1)..<n {
                let candidate = abs(augmentedMatrix[row][pivot])
                if candidate > maxValue {
                    maxValue = candidate
                    maxRow = row
                }
            }

            if maxValue < 1e-10 {
                return nil
            }

            if maxRow != pivot {
                augmentedMatrix.swapAt(pivot, maxRow)
                resultVector.swapAt(pivot, maxRow)
            }

            let pivotValue = augmentedMatrix[pivot][pivot]
            for column in pivot..<n {
                augmentedMatrix[pivot][column] /= pivotValue
            }
            resultVector[pivot] /= pivotValue

            for row in 0..<n where row != pivot {
                let factor = augmentedMatrix[row][pivot]
                if abs(factor) < 1e-12 { continue }
                for column in pivot..<n {
                    augmentedMatrix[row][column] -= factor * augmentedMatrix[pivot][column]
                }
                resultVector[row] -= factor * resultVector[pivot]
            }
        }

        return resultVector
    }

    private func formatSolution(_ value: Double) -> String {
        if value.isNaN { return "錯誤" }
        if value.isInfinite { return value > 0 ? "無限" : "-無限" }

        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 8
        formatter.minimumFractionDigits = 0
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    private enum EquationInputError: Error {
        case invalidNumber
    }
}

// --- 自訂輸入欄位 ---
private struct EquationInputField: View {
    @Binding var text: String
    var placeholder: String
    var width: CGFloat

    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.plain)
            .foregroundColor(.white)
            .padding(.vertical, 6)
            .frame(width: width)
            .background(Color(hex: "1E1E1E"))
            .cornerRadius(8)
            .multilineTextAlignment(.center)
#if os(iOS)
            .keyboardType(.numbersAndPunctuation)
#endif
    }
}

// MARK: - 拍照解題視圖

struct PhotoSolverView: View {
#if canImport(PhotosUI)
    @State private var pickerItem: PhotosPickerItem?
#endif
    @State private var previewImage: Image?
    @State private var recognizedText: String = ""
    @State private var solverResult: PhotoMathSolver.Result?
    @State private var isProcessing: Bool = false
    @State private var errorMessage: String?

    private let solver = PhotoMathSolver()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                inputSection
                resultSection
                Spacer(minLength: 0)
            }
            .padding(24)
        }
        .background(Color.black)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("拍照解題：台灣高中 / 高職數學")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
            Text("拍攝或選擇題目照片，系統會先進行文字辨識，再依常見的高中數學題型（如一次方程、聯立方程、二次方程）進行步驟式講解。")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "CCCCCC"))
        }
    }

    @ViewBuilder
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("題目照片")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

#if canImport(PhotosUI)
            PhotosPicker(selection: $pickerItem, matching: .images) {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("拍照或從相簿選擇")
                        .font(.system(size: 16, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .photosPickerStyle(.automatic)
            .onChange(of: pickerItem) { newValue in
                guard let item = newValue else { return }
                Task { await processSelectedItem(item) }
            }
#else
            Text("此平台目前不支援相機或相簿匯入功能。")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.red)
#endif

            if let previewImage = previewImage {
                previewImage
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "505050"), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                    .foregroundColor(Color(hex: "505050"))
                    .frame(height: 200)
                    .overlay(
                        Text("請拍攝題目或從相簿匯入照片")
                            .foregroundColor(Color(hex: "777777"))
                    )
            }

            if isProcessing {
                ProgressView("正在辨識題目並計算中...")
                    .progressViewStyle(.circular)
                    .tint(.orange)
                    .foregroundColor(.white)
            }

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.system(size: 15, weight: .medium))
            }
        }
    }

    @ViewBuilder
    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("辨識結果")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            if recognizedText.isEmpty {
                Text("尚未辨識到題目文字，請拍攝清晰的題目圖片。")
                    .foregroundColor(Color(hex: "777777"))
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(recognizedText)
                        .foregroundColor(.white)
                        .font(.system(size: 15, weight: .medium))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(hex: "1E1E1E"))
                        .cornerRadius(12)

                    if let solverResult = solverResult {
                        Divider().background(Color(hex: "505050"))

                        VStack(alignment: .leading, spacing: 12) {
                            Text("題型分析：\(solverResult.categoryDescription)")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)

                            ForEach(solverResult.steps.indices, id: \.self) { index in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("步驟 \(index + 1)")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Color.orange)
                                        .frame(width: 70, alignment: .leading)
                                    Text(solverResult.steps[index])
                                        .foregroundColor(.white)
                                        .font(.system(size: 15))
                                        .multilineTextAlignment(.leading)
                                }
                            }

                            Divider().background(Color(hex: "505050"))

                            Text("最終答案：\(solverResult.finalAnswer)")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(Color(hex: "5BD05B"))
                        }
                        .padding()
                        .background(Color(hex: "141414"))
                        .cornerRadius(12)
                    } else {
                        Text("暫時無法自動解析此題型，請確認拍攝內容或改用手動輸入。")
                            .foregroundColor(Color(hex: "FFB347"))
                            .font(.system(size: 15, weight: .medium))
                    }
                }
            }
        }
    }

#if canImport(PhotosUI)
    @MainActor
    private func processSelectedItem(_ item: PhotosPickerItem) async {
        resetStateForNewProcessing()
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                errorMessage = "無法讀取圖片資料，請重試。"
                return
            }

            updatePreviewImage(from: data)
            isProcessing = true

            let recognized = try await recognizeText(from: data)
            recognizedText = recognized.isEmpty ? "無辨識內容" : recognized

            let result = solver.solve(recognizedText: recognized)
            solverResult = result
        } catch {
            errorMessage = "辨識過程發生錯誤：\(error.localizedDescription)"
        }
        isProcessing = false
    }

    @MainActor
    private func resetStateForNewProcessing() {
        errorMessage = nil
        recognizedText = ""
        solverResult = nil
    }

    @MainActor
    private func updatePreviewImage(from data: Data) {
#if canImport(UIKit)
        if let uiImage = UIImage(data: data) {
            previewImage = Image(uiImage: uiImage)
        }
#elseif canImport(AppKit)
        if let nsImage = NSImage(data: data) {
            previewImage = Image(nsImage: nsImage)
        }
#endif
    }

    private func recognizeText(from data: Data) async throws -> String {
#if canImport(Vision)
        return try await Task.detached(priority: .userInitiated) {
            guard let cgImage = PhotoSolverView.makeCGImage(from: data) else {
                throw PhotoSolverError.invalidImage
            }

            let request = VNRecognizeTextRequest()
            request.recognitionLanguages = ["zh-Hant", "zh-Hant-TW", "en-US"]
            request.usesLanguageCorrection = true
            request.minimumTextHeight = 0.02
            request.recognitionLevel = .accurate

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                return ""
            }

            let lines = observations.compactMap { $0.topCandidates(1).first?.string }
            return lines.joined(separator: "\n")
        }.value
#else
        throw PhotoSolverError.visionNotAvailable
#endif
    }
#endif

    private static func makeCGImage(from data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    private enum PhotoSolverError: Error {
        case invalidImage
        case visionNotAvailable
    }
}

extension PhotoSolverView.PhotoSolverError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "無法解讀圖片資料。"
        case .visionNotAvailable:
            return "此裝置尚未支援影像文字辨識。"
        }
    }
}

// MARK: - 拍照題型解析器

struct PhotoMathSolver {
    struct Result {
        let normalizedProblem: String
        let categoryDescription: String
        let steps: [String]
        let finalAnswer: String
    }

    func solve(recognizedText: String) -> Result? {
        let trimmed = recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let normalized = normalize(text: trimmed)
        if let system = solveLinearSystem(from: normalized) {
            return system
        }
        if let quadratic = solveQuadraticEquation(from: normalized) {
            return quadratic
        }
        if let linear = solveSingleLinearEquation(from: normalized) {
            return linear
        }

        return Result(
            normalizedProblem: normalized,
            categoryDescription: "尚未支援的題型",
            steps: [
                "辨識文字：\(normalized)",
                "目前針對台灣高中 / 高職課綱已優化一次、聯立、二次方程等常見題型，若為其他題型請確認拍攝角度或改用手動輸入。"
            ],
            finalAnswer: "暫時無法自動計算，請手動計算或再次拍攝清晰題目。"
        )
    }

    // MARK: - Normalization Helpers

    private func normalize(text: String) -> String {
        var sanitized = text
        let replacements: [String: String] = [
            "＝": "=",
            "﹦": "=",
            "：": ":",
            "－": "-",
            "—": "-",
            "＋": "+",
            "，": ",",
            "。": ".",
            "（": "(",
            "）": ")",
            "√": "sqrt",
            "ｘ": "x",
            "Ｘ": "x",
            "ｙ": "y",
            "Ｙ": "y",
            "ｚ": "z",
            "Ｚ": "z",
            "sin": "sin",
            "cos": "cos"
        ]

        for (target, replacement) in replacements {
            sanitized = sanitized.replacingOccurrences(of: target, with: replacement)
        }

        sanitized = sanitized.replacingOccurrences(of: " ", with: "")
        sanitized = sanitized.replacingOccurrences(of: "\t", with: "")
        sanitized = sanitized.replacingOccurrences(of: "\r", with: "")
        sanitized = sanitized.replacingOccurrences(of: ",", with: "")
        sanitized = sanitized.replacingOccurrences(of: "x²", with: "x^2")
        sanitized = sanitized.replacingOccurrences(of: "y²", with: "y^2")
        sanitized = sanitized.replacingOccurrences(of: "z²", with: "z^2")

        // 將常見的誤辨識 x2 修正為 x^2
        sanitized = sanitized.replacingOccurrences(of: "x2", with: "x^2")
        sanitized = sanitized.replacingOccurrences(of: "y2", with: "y^2")
        sanitized = sanitized.replacingOccurrences(of: "z2", with: "z^2")

        return sanitized
    }

    // MARK: - 解聯立方程

    private func solveLinearSystem(from text: String) -> Result? {
        let lines = text
            .components(separatedBy: CharacterSet.newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard (2...3).contains(lines.count) else { return nil }

        let variables = lines.count == 2 ? ["x", "y"] : ["x", "y", "z"]
        var coefficients: [[Double]] = []
        var constants: [Double] = []

        for line in lines.prefix(variables.count) {
            guard let parsed = parseLinearEquation(line, variables: variables) else {
                return nil
            }
            coefficients.append(parsed.coefficients)
            constants.append(parsed.constant)
        }

        guard let answers = gaussianElimination(coefficients: coefficients, constants: constants) else {
            return nil
        }

        let formatter = numberFormatter()
        let formattedCoefficients = coefficients.map { row in
            row.map { formatter.string(from: NSNumber(value: $0)) ?? "\($0)" }
        }

        var steps: [String] = []
        steps.append("建立係數矩陣 A = \(formattedCoefficients) 與常數向量 b = \(constants.map { formatter.string(from: NSNumber(value: $0)) ?? "\($0)" })。")
        steps.append("使用高斯消去法消去未知數，將矩陣化為階梯形。")
        steps.append("回代求得各變數值。")

        let answerText = zip(variables, answers).map { variable, value in
            "\(variable) = \(formatter.string(from: NSNumber(value: value)) ?? String(value))"
        }.joined(separator: "，")

        return Result(
            normalizedProblem: lines.joined(separator: "\n"),
            categoryDescription: "聯立一次方程組（\(variables.count) 元）",
            steps: steps,
            finalAnswer: answerText
        )
    }

    private func parseLinearEquation(_ equation: String, variables: [String]) -> (coefficients: [Double], constant: Double)? {
        guard let equalIndex = equation.firstIndex(of: "=") else { return nil }
        let lhs = String(equation[..<equalIndex])
        let rhs = String(equation[equalIndex...].dropFirst())

        var coeffs = Array(repeating: 0.0, count: variables.count)
        var constantLeft = 0.0

        let normalizedLHS = lhs
            .replacingOccurrences(of: "-", with: "+-")
            .replacingOccurrences(of: "−", with: "+-")
            .replacingOccurrences(of: "+-", with: "+-")

        let tokens = normalizedLHS
            .split(separator: "+")
            .map { String($0) }
            .filter { !$0.isEmpty }

        for token in tokens {
            var matchedVariable = false
            for (index, variable) in variables.enumerated() {
                if token.contains(variable) {
                    matchedVariable = true
                    let coefficientString = token.replacingOccurrences(of: variable, with: "")
                    coeffs[index] += parseCoefficient(from: coefficientString)
                    break
                }
            }

            if !matchedVariable {
                constantLeft += Double(token) ?? 0.0
            }
        }

        let rhsValue = Double(rhs) ?? 0.0
        let constant = rhsValue - constantLeft
        return (coeffs, constant)
    }

    private func parseCoefficient(from text: String) -> Double {
        if text.isEmpty { return 1.0 }
        if text == "-" { return -1.0 }
        if text == "+" { return 1.0 }
        return Double(text) ?? 0.0
    }

    private func gaussianElimination(coefficients: [[Double]], constants: [Double]) -> [Double]? {
        let n = constants.count
        guard coefficients.count == n else { return nil }

        var matrix = coefficients
        var vector = constants

        for pivot in 0..<n {
            var maxRow = pivot
            var maxValue = abs(matrix[pivot][pivot])

            for row in (pivot + 1)..<n {
                let value = abs(matrix[row][pivot])
                if value > maxValue {
                    maxValue = value
                    maxRow = row
                }
            }

            if maxValue < 1e-10 {
                return nil
            }

            if maxRow != pivot {
                matrix.swapAt(pivot, maxRow)
                vector.swapAt(pivot, maxRow)
            }

            let pivotValue = matrix[pivot][pivot]
            for column in pivot..<n {
                matrix[pivot][column] /= pivotValue
            }
            vector[pivot] /= pivotValue

            for row in 0..<n where row != pivot {
                let factor = matrix[row][pivot]
                if abs(factor) < 1e-12 { continue }
                for column in pivot..<n {
                    matrix[row][column] -= factor * matrix[pivot][column]
                }
                vector[row] -= factor * vector[pivot]
            }
        }

        return vector
    }

    // MARK: - 解二次方程

    private func solveQuadraticEquation(from text: String) -> Result? {
        let delimiters = CharacterSet(charactersIn: "\n\r;；。")
        let candidates = text
            .components(separatedBy: delimiters)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.contains("x^2") && $0.contains("=") }

        for equation in candidates {
            guard let equalIndex = equation.firstIndex(of: "=") else { continue }
            let lhs = String(equation[..<equalIndex])
            let rhs = String(equation[equalIndex...].dropFirst())

            if let factorResult = solveFactorizedQuadratic(equation: equation) {
                return factorResult
            }

            let lhsCoefficients = parseQuadraticSide(lhs)
            let rhsCoefficients = parseQuadraticSide(rhs)

            let a = lhsCoefficients.a - rhsCoefficients.a
            let b = lhsCoefficients.b - rhsCoefficients.b
            let c = lhsCoefficients.c - rhsCoefficients.c

            if abs(a) < 1e-10 { continue }

            return buildQuadraticResult(equation: equation, a: a, b: b, c: c)
        }

        return nil
    }

    private func solveFactorizedQuadratic(equation: String) -> Result? {
        let cleaned = equation.replacingOccurrences(of: " ", with: "")
        guard cleaned.contains(")("), cleaned.hasSuffix("=0") else { return nil }
        let lhsRhs = cleaned.split(separator: "=")
        guard lhsRhs.count == 2, lhsRhs[1] == "0" else { return nil }

        let factors = lhsRhs[0].split(separator: ")(")
        guard factors.count == 2 else { return nil }

        let firstFactor = factors[0].replacingOccurrences(of: "(", with: "")
        let secondFactor = factors[1].replacingOccurrences(of: ")", with: "")

        guard let (a1, b1) = parseLinearFactor(firstFactor),
              let (a2, b2) = parseLinearFactor(secondFactor),
              abs(a1) > 0, abs(a2) > 0 else { return nil }

        let root1 = -b1 / a1
        let root2 = -b2 / a2

        let formatter = numberFormatter()
        let root1Text = formatter.string(from: NSNumber(value: root1)) ?? String(root1)
        let root2Text = formatter.string(from: NSNumber(value: root2)) ?? String(root2)

        let steps = [
            "題目為因式分解形式：\(equation)",
            "令每個一次因式為 0：\(factorDescription(factor: firstFactor)) = 0 與 \(factorDescription(factor: secondFactor)) = 0。",
            "分別解出兩個一次方程後可得解。"
        ]

        let finalAnswer = "x₁ = \(root1Text)，x₂ = \(root2Text)"
        return Result(
            normalizedProblem: equation,
            categoryDescription: "二次方程式（因式分解）",
            steps: steps,
            finalAnswer: finalAnswer
        )
    }

    private func parseLinearFactor(_ expression: String) -> (Double, Double)? {
        guard expression.contains("x") else { return nil }

        let normalized = expression
            .replacingOccurrences(of: "-", with: "+-")
            .replacingOccurrences(of: "−", with: "+-")
            .replacingOccurrences(of: "+-", with: "+-")

        let tokens = normalized
            .split(separator: "+")
            .map { String($0) }
            .filter { !$0.isEmpty }

        var a: Double = 0
        var b: Double = 0

        for token in tokens {
            if token.contains("x") {
                let coeff = token.replacingOccurrences(of: "x", with: "")
                a += parseCoefficient(from: coeff)
            } else {
                b += Double(token) ?? 0
            }
        }

        return (a, b)
    }

    private func factorDescription(factor: String) -> String {
        if factor.first == "(" && factor.last == ")" {
            return factor
        }
        return "(\(factor))"
    }

    private func parseQuadraticSide(_ expression: String) -> (a: Double, b: Double, c: Double) {
        let normalized = expression
            .replacingOccurrences(of: "-", with: "+-")
            .replacingOccurrences(of: "−", with: "+-")
            .replacingOccurrences(of: "+-", with: "+-")

        let tokens = normalized
            .split(separator: "+")
            .map { String($0) }
            .filter { !$0.isEmpty }

        var a: Double = 0
        var b: Double = 0
        var c: Double = 0

        for token in tokens {
            if token.contains("x^2") {
                let coeff = token.replacingOccurrences(of: "x^2", with: "")
                a += parseCoefficient(from: coeff)
            } else if token.contains("x") {
                let coeff = token.replacingOccurrences(of: "x", with: "")
                b += parseCoefficient(from: coeff)
            } else {
                c += Double(token) ?? 0
            }
        }

        return (a, b, c)
    }

    private func buildQuadraticResult(equation: String, a: Double, b: Double, c: Double) -> Result {
        let formatter = numberFormatter()
        let discriminant = b * b - 4 * a * c
        var steps: [String] = []
        steps.append("將題目整理為 ax² + bx + c = 0，其中 a = \(formatter.string(from: NSNumber(value: a)) ?? String(a))，b = \(formatter.string(from: NSNumber(value: b)) ?? String(b))，c = \(formatter.string(from: NSNumber(value: c)) ?? String(c))。")
        steps.append("判別式 Δ = b² − 4ac = \(formatter.string(from: NSNumber(value: discriminant)) ?? String(discriminant))")

        if discriminant > 0 {
            let sqrtDelta = sqrt(discriminant)
            let x1 = (-b + sqrtDelta) / (2 * a)
            let x2 = (-b - sqrtDelta) / (2 * a)
            steps.append("Δ > 0，故有兩實根。")
            steps.append("x = (−b ± √Δ) / 2a")
            let final = "x₁ = \(formatter.string(from: NSNumber(value: x1)) ?? String(x1))，x₂ = \(formatter.string(from: NSNumber(value: x2)) ?? String(x2))"
            return Result(
                normalizedProblem: equation,
                categoryDescription: "二次方程式",
                steps: steps,
                finalAnswer: final
            )
        } else if abs(discriminant) < 1e-10 {
            let root = -b / (2 * a)
            steps.append("Δ = 0，故有重根。")
            steps.append("x = −b / 2a")
            let final = "x = \(formatter.string(from: NSNumber(value: root)) ?? String(root))"
            return Result(
                normalizedProblem: equation,
                categoryDescription: "二次方程式",
                steps: steps,
                finalAnswer: final
            )
        } else {
            let sqrtDelta = sqrt(-discriminant)
            let real = -b / (2 * a)
            let imaginary = sqrtDelta / (2 * a)
            steps.append("Δ < 0，故有共軛複數解。")
            steps.append("x = (−b ± i√|Δ|) / 2a")
            let final = "x = \(formatter.string(from: NSNumber(value: real)) ?? String(real)) ± \(formatter.string(from: NSNumber(value: imaginary)) ?? String(imaginary))i"
            return Result(
                normalizedProblem: equation,
                categoryDescription: "二次方程式",
                steps: steps,
                finalAnswer: final
            )
        }
    }

    // MARK: - 解一次方程

    private func solveSingleLinearEquation(from text: String) -> Result? {
        guard let equalIndex = text.firstIndex(of: "=") else { return nil }
        let lhs = String(text[..<equalIndex])
        let rhs = String(text[equalIndex...].dropFirst())

        guard lhs.contains("x") else { return nil }

        var coefficient: Double = 0
        var constantLeft: Double = 0

        let normalizedLHS = lhs
            .replacingOccurrences(of: "-", with: "+-")
            .replacingOccurrences(of: "−", with: "+-")
            .replacingOccurrences(of: "+-", with: "+-")

        let tokens = normalizedLHS
            .split(separator: "+")
            .map { String($0) }
            .filter { !$0.isEmpty }

        for token in tokens {
            if token.contains("x") {
                let coefficientString = token.replacingOccurrences(of: "x", with: "")
                coefficient += parseCoefficient(from: coefficientString)
            } else {
                constantLeft += Double(token) ?? 0
            }
        }

        guard abs(coefficient) > 0 else { return nil }

        let rhsValue = Double(rhs) ?? 0
        let constantRight = rhsValue - constantLeft
        let answer = constantRight / coefficient

        let formatter = numberFormatter()
        var steps: [String] = []
        steps.append("將常數項移項後得：\(formatter.string(from: NSNumber(value: coefficient)) ?? String(coefficient))x = \(formatter.string(from: NSNumber(value: constantRight)) ?? String(constantRight))")
        steps.append("x = \(formatter.string(from: NSNumber(value: constantRight)) ?? String(constantRight)) ÷ \(formatter.string(from: NSNumber(value: coefficient)) ?? String(coefficient))")

        return Result(
            normalizedProblem: text,
            categoryDescription: "一次方程式",
            steps: steps,
            finalAnswer: "x = \(formatter.string(from: NSNumber(value: answer)) ?? String(answer))"
        )
    }

    private func numberFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 6
        formatter.minimumFractionDigits = 0
        formatter.numberStyle = .decimal
        return formatter
    }
}
