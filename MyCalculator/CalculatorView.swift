import SwiftUI

struct CalculatorView: View {
    
    @StateObject private var viewModel = CalculatorViewModel()
    
    private let buttonSpacing: CGFloat = 12
    private let numberOfColumns = 10

    var body: some View {
        VStack(spacing: 0) {
            
            // --- 顯示區域 (Display Area) ---
            VStack {
                Spacer() // 推向底部
                
                Text(viewModel.fullExpressionText)
                    .font(.system(size: 24))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                
                Text(viewModel.displayText)
                    .font(.system(size: 80, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, maxHeight: .infinity) // *** 修正 *** 讓顯示區域填滿所有可用空間

            // --- 按鈕區域 (Button Grid) ---
            GeometryReader { geometry in
                
                // 計算單個按鈕的寬度
                let totalSpacing = buttonSpacing * CGFloat(numberOfColumns - 1)
                let buttonSize = (geometry.size.width - totalSpacing) / CGFloat(numberOfColumns)
                
                // 計算按鈕網格的總高度
                let totalButtonHeight = (buttonSize * 5) + (buttonSpacing * 4)

                VStack(spacing: buttonSpacing) {
                    
                    // 遍歷 ViewModel 中的 2D 佈局
                    ForEach(viewModel.buttonLayout.indices, id: \.self) { rowIndex in
                        
                        if rowIndex == viewModel.buttonLayout.count - 1 {
                            createLastRow(buttons: viewModel.buttonLayout[rowIndex], buttonSize: buttonSize)
                        } else {
                            createButtonRow(buttons: viewModel.buttonLayout[rowIndex], buttonSize: buttonSize)
                        }
                    }
                }
                .frame(width: geometry.size.width, height: totalButtonHeight) // 固定 VStack 的大小
                
            }
            // *** 修正 *** 強制 GeometryReader 保持 10x5 (2:1) 的長寬比
            .aspectRatio(CGFloat(numberOfColumns) / CGFloat(5), contentMode: .fit)
            .padding()
        }
        .background(Color.black)
    }
    
    // 輔助函式：建立一個標準的橫排
    private func createButtonRow(buttons: [CalculatorButton], buttonSize: CGFloat) -> some View {
        HStack(spacing: buttonSpacing) {
            ForEach(buttons) { button in
                
                // 動態處理 AC / C 按鈕
                if case .control("AC") = button {
                    let title = viewModel.getControlButtonTitle()
                    let actionButton = viewModel.getControlButtonAction()
                    
                    CalculatorButtonView(
                        title: title,
                        backgroundColor: viewModel.getBackgroundColor(for: actionButton),
                        foregroundColor: viewModel.getForegroundColor(for: actionButton),
                        span: button.span
                    ) {
                        viewModel.buttonTapped(actionButton)
                    }
                    .frame(width: buttonSize, height: buttonSize)
                } else {
                    // 建立所有其他標準按鈕
                    CalculatorButtonView(
                        title: button.title,
                        backgroundColor: viewModel.getBackgroundColor(for: button),
                        foregroundColor: viewModel.getForegroundColor(for: button),
                        span: button.span
                    ) {
                        viewModel.buttonTapped(button)
                    }
                    .frame(width: buttonSize, height: buttonSize)
                }
            }
        }
    }
    
    // 輔助函式：建立最後一排 (處理 "0" 的跨欄)
    private func createLastRow(buttons: [CalculatorButton], buttonSize: CGFloat) -> some View {
        HStack(spacing: buttonSpacing) {
            ForEach(buttons) { button in
                
                let buttonWidth = (buttonSize * CGFloat(button.span)) + (buttonSpacing * CGFloat(button.span - 1))
                
                if button.title != "" {
                    CalculatorButtonView(
                        title: button.title,
                        backgroundColor: viewModel.getBackgroundColor(for: button),
                        foregroundColor: viewModel.getForegroundColor(for: button),
                        span: button.span
                    ) {
                        viewModel.buttonTapped(button)
                    }
                    .frame(width: buttonWidth, height: buttonSize)
                } else {
                    // 空白佔位格
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: buttonWidth, height: buttonSize)
                }
            }
        }
    }
}

// --- 可重複使用的按鈕視圖 (這就是你問的 struct) ---
struct CalculatorButtonView: View {
    var title: String
    var backgroundColor: Color
    var foregroundColor: Color
    var span: Int
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            GeometryReader { geo in
                Text(title)
                    .font(.system(size: geo.size.height * 0.45, weight: .medium))
                    .lineLimit(1) // *** 新增 *** 確保單行
                    .minimumScaleFactor(0.5) // *** 新增 *** 允許文字縮小 (修正 "Ra...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(backgroundColor)
        .foregroundColor(foregroundColor)
        .clipShape(span == 2 ? AnyShape(Capsule()) : AnyShape(Circle()))
        .contentShape(span == 2 ? AnyShape(Capsule()) : AnyShape(Circle()))
        .buttonStyle(.plain)
    }
}

// 讓 AnyShape 可以被使用 (保持不變)
struct AnyShape: Shape {
    private let _path: (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        _path = { rect in
            shape.path(in: rect)
        }
    }

    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}
