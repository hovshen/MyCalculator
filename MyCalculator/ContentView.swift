import SwiftUI
import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif
import UniformTypeIdentifiers

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
    @State private var isImporterPresented: Bool = false
    @State private var previewImage: Image?
    @State private var solverResult: GeminiSolverClient.AnalysisResult?
    @State private var isProcessing: Bool = false
    @State private var errorMessage: String?

    private let solver = GeminiSolverClient()

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
            Text("上傳題目照片後，系統會交由 Gemini 2.5 Flash 模型解析題目並提供簡短詳解。請確保題目清晰且完整。")
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

            Button {
                isImporterPresented = true
            } label: {
                HStack {
                    Image(systemName: "tray.and.arrow.up.fill")
                    Text("從電腦上傳照片")
                        .font(.system(size: 16, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .fileImporter(isPresented: $isImporterPresented, allowedContentTypes: [.image]) { result in
                switch result {
                case .success(let url):
                    Task { await processSelectedURL(url) }
                case .failure(let error):
                    errorMessage = "開啟檔案時發生錯誤：\(error.localizedDescription)"
                }
            }

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
                        Text("請上傳題目照片以獲得解析")
                            .foregroundColor(Color(hex: "777777"))
                    )
            }

            if isProcessing {
                ProgressView("正在上傳並等待 Gemini 回覆...")
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
            Text("Gemini 詳解")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            if let solverResult = solverResult {
                VStack(alignment: .leading, spacing: 12) {
                    Text(solverResult.explanation)
                        .foregroundColor(.white)
                        .font(.system(size: 15, weight: .medium))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(hex: "1E1E1E"))
                        .cornerRadius(12)

                    if let suggestions = solverResult.suggestions {
                        Text(suggestions)
                            .foregroundColor(Color(hex: "FFB347"))
                            .font(.system(size: 14, weight: .regular))
                    }
                }
            } else {
                Text("尚未產生詳解，請上傳題目圖片並稍候。")
                    .foregroundColor(Color(hex: "777777"))
            }
        }
    }

    @MainActor
    private func processSelectedURL(_ url: URL) async {
        resetStateForNewProcessing()

        do {
            let data = try await loadData(from: url)
            updatePreviewImage(from: data)

            isProcessing = true
            let mimeType = PhotoSolverView.mimeType(for: url) ?? "image/jpeg"
            let result = try await solver.analyze(imageData: data, mimeType: mimeType)
            solverResult = result
        } catch {
            errorMessage = "解析過程發生錯誤：\(error.localizedDescription)"
        }

        isProcessing = false
    }

    private func loadData(from url: URL) async throws -> Data {
        try await Task.detached(priority: .userInitiated) {
            #if os(iOS)
            let needsAccess = url.startAccessingSecurityScopedResource()
            defer {
                if needsAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            #endif
            return try Data(contentsOf: url)
        }.value
    }

    @MainActor
    private func resetStateForNewProcessing() {
        errorMessage = nil
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

    private static func mimeType(for url: URL) -> String? {
        guard let type = UTType(filenameExtension: url.pathExtension) else { return nil }
        return type.preferredMIMEType
    }
}
