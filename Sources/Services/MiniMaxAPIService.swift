import Foundation

class MiniMaxAPIService {

    private let endpoint = "https://www.minimaxi.com/v1/api/openplatform/coding_plan/remains"
    private let keychainService = "com.minimax.tokenmonitor"
    private let keychainAccount = "api_key"

    enum APIError: LocalizedError {
        case invalidURL
        case networkError(Error)
        case decodingError(Error)
        case serverError(String)

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "无效的 URL"
            case .networkError(let error):
                return "网络错误: \(error.localizedDescription)"
            case .decodingError(let error):
                return "数据解析错误: \(error.localizedDescription)"
            case .serverError(let msg):
                return "服务器错误: \(msg)"
            }
        }
    }

    func fetchUsage(apiKey: String, completion: @escaping (Result<UsageResponse, APIError>) -> Void) {
        guard let url = URL(string: endpoint) else {
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }

            guard let data = data else {
                completion(.failure(.networkError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "无数据返回"]))))
                return
            }

            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(UsageResponse.self, from: data)

                if response.baseResp.statusCode != 0 {
                    completion(.failure(.serverError(response.baseResp.statusMsg)))
                    return
                }

                completion(.success(response))
            } catch {
                completion(.failure(.decodingError(error)))
            }
        }.resume()
    }

    func saveAPIKey(_ key: String) -> Bool {
        let data = key.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    func getAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }

        return key
    }

    func deleteAPIKey() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
