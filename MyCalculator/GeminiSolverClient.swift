import Foundation

struct GeminiSolverClient {
    struct AnalysisResult {
        let explanation: String
        let suggestions: String?
    }

    struct Configuration {
        private static let fallbackAPIKey = "AIzaSyBlcA7MPvTV7gnkdh1vKLGSXI_2e3z4xYo"

        let apiKey: String
        let endpoint: URL

        init(apiKey: String? = ProcessInfo.processInfo.environment["GEMINI_API_KEY"],
             endpoint: URL = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent")!) {
            if let apiKey, !apiKey.isEmpty {
                self.apiKey = apiKey
            } else {
                self.apiKey = Self.fallbackAPIKey
            }
            self.endpoint = endpoint
        }
    }

    enum ClientError: LocalizedError {
        case missingAPIKey
        case invalidResponse
        case apiError(message: String)

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "尚未設定 Gemini API Key，請於環境變數 GEMINI_API_KEY 中提供。"
            case .invalidResponse:
                return "Gemini 回傳了無法解析的內容。"
            case .apiError(let message):
                return "Gemini 服務回傳錯誤：\(message)"
            }
        }
    }

    private let configuration: Configuration
    private let urlSession: URLSession

    init(configuration: Configuration = Configuration(), urlSession: URLSession = .shared) {
        self.configuration = configuration
        self.urlSession = urlSession
    }

    func analyze(imageData: Data, mimeType: String) async throws -> AnalysisResult {
        guard !configuration.apiKey.isEmpty else {
            throw ClientError.missingAPIKey
        }

        var components = URLComponents(url: configuration.endpoint, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "key", value: configuration.apiKey)]

        guard let url = components?.url else {
            throw ClientError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try makeRequestBody(imageData: imageData, mimeType: mimeType)

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClientError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let apiError = try? JSONDecoder().decode(GeminiAPIError.self, from: data) {
                throw ClientError.apiError(message: apiError.error.message)
            }
            throw ClientError.apiError(message: "HTTP \(httpResponse.statusCode)")
        }

        let payload = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = payload.firstCandidateText else {
            throw ClientError.invalidResponse
        }

        let message = try decodeModelMessage(from: text)
        return AnalysisResult(explanation: message.explanation, suggestions: message.suggestions)
    }

    private func makeRequestBody(imageData: Data, mimeType: String) throws -> Data {
        let base64 = imageData.base64EncodedString()

        let prompt = """
        你是一位熟悉台灣高中與高職課綱的數學老師。請閱讀圖片中的題目內容，推導主要解題步驟並給出最後答案。
        以 JSON 回覆，格式如下：
        {
          "explanation": "使用繁體中文、條列重點的簡短詳解。",
          "suggestions": "若有額外提醒或下一步建議，可用繁體中文補充，沒有則省略此欄位。"
        }
        請務必只輸出 JSON，不要包含多餘文字或註解。
        """

        let request = GeminiRequest(contents: [
            .init(parts: [
                .init(text: prompt),
                .init(inlineData: .init(data: base64, mimeType: mimeType))
            ])
        ])

        let encoder = JSONEncoder()
        return try encoder.encode(request)
    }

    private func decodeModelMessage(from text: String) throws -> ModelMessage {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleaned: String
        if trimmed.hasPrefix("```") {
            let lines = trimmed.split(separator: "\n")
            if lines.count >= 2 {
                cleaned = lines.dropFirst().dropLast().joined(separator: "\n")
            } else {
                cleaned = trimmed
            }
        } else {
            cleaned = trimmed
        }

        guard let data = cleaned.data(using: .utf8) else {
            throw ClientError.invalidResponse
        }

        let decoder = JSONDecoder()
        if let modelMessage = try? decoder.decode(ModelMessage.self, from: data) {
            return modelMessage
        }

        if let extracted = Self.extractJSONObject(from: cleaned),
           let extractedData = extracted.data(using: .utf8),
           let fallback = try? decoder.decode(ModelMessage.self, from: extractedData) {
            return fallback
        }

        throw ClientError.invalidResponse
    }

    private static func extractJSONObject(from text: String) -> String? {
        guard let start = text.firstIndex(of: "{"), let end = text.lastIndex(of: "}") else {
            return nil
        }
        return String(text[start...end])
    }
}

private struct GeminiRequest: Encodable {
    struct Content: Encodable {
        struct Part: Encodable {
            struct InlineData: Encodable {
                let data: String
                let mimeType: String

                enum CodingKeys: String, CodingKey {
                    case data
                    case mimeType = "mime_type"
                }
            }

            let text: String?
            let inlineData: InlineData?

            init(text: String) {
                self.text = text
                self.inlineData = nil
            }

            init(inlineData: InlineData) {
                self.text = nil
                self.inlineData = inlineData
            }

            enum CodingKeys: String, CodingKey {
                case text
                case inlineData = "inline_data"
            }
        }

        let parts: [Part]
    }

    let contents: [Content]
}

private struct GeminiResponse: Decodable {
    struct Candidate: Decodable {
        struct Content: Decodable {
            struct Part: Decodable {
                let text: String?
            }

            let parts: [Part]?
        }

        let content: Content?
    }

    let candidates: [Candidate]?

    var firstCandidateText: String? {
        for candidate in candidates ?? [] {
            if let parts = candidate.content?.parts {
                let text = parts.compactMap { $0.text }.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty {
                    return text
                }
            }
        }
        return nil
    }
}

private struct GeminiAPIError: Decodable {
    struct ErrorBody: Decodable {
        let message: String
    }

    let error: ErrorBody
}

private struct ModelMessage: Decodable {
    let explanation: String
    let suggestions: String?
}
