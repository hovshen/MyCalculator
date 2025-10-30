import SwiftUI

// 定義可用的模式
enum CalculatorMode: String, CaseIterable, Identifiable {
    case standard = "科學計算機"
    case twoVar = "二元一次聯立方程式"
    case threeVar = "三元一次聯立方程式"
    
    var id: String { self.rawValue }
}

struct ContentView: View {
    @State private var selectedMode: CalculatorMode = .standard

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
            switch selectedMode {
            case .standard:
                CalculatorView()
                    .frame(minWidth: 700, minHeight: 450)
            case .twoVar:
                EquationSolverView(mode: .twoVar)
                    .frame(minWidth: 400, minHeight: 450)
            case .threeVar:
                EquationSolverView(mode: .threeVar)
                    .frame(minWidth: 450, minHeight: 500)
            }
            
            Spacer()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}


// --- 方程式求解器的佔位視圖 (保持不變) ---
struct EquationSolverView: View {
    var mode: CalculatorMode
    
    var body: some View {
        VStack {
            Text(mode.rawValue)
                .font(.largeTitle)
                .foregroundColor(.white)
            
            Text("即將推出！")
                .font(.title2)
                .foregroundColor(.gray)
                .padding()
            
            Text("範例輸入框 (未來實作):")
                .foregroundColor(.white.opacity(0.5))
            
            HStack {
                TextField("a", text: .constant(""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 50)
                Text("x +").foregroundColor(.white)
                TextField("b", text: .constant(""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 50)
                Text("y =").foregroundColor(.white)
                TextField("c", text: .constant(""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 50)
            }
            .padding()
        }
        // *** 新增 *** 讓這個佔位視圖填滿空間
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
