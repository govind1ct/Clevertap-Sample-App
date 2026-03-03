import Foundation
import UIKit

#if canImport(PayUCheckoutProKit) && canImport(PayUCheckoutProBaseKit) && canImport(PayUParamsKit)
import PayUCheckoutProKit
import PayUCheckoutProBaseKit
import PayUParamsKit
#endif

enum PayUCheckoutOutcome {
    case success(Any?)
    case failure(String)
    case cancelled
}

enum PayUServiceError: LocalizedError {
    case missingConfiguration(String)
    case invalidConfiguration(String)
    case invalidHashResponse
    case sdkNotAvailable
    case launchFailed
    case networkFailure(String)

    var errorDescription: String? {
        switch self {
        case .missingConfiguration(let key):
            return "PayU is not configured. Missing \(key)."
        case .invalidConfiguration(let message):
            return "Invalid PayU configuration: \(message)"
        case .invalidHashResponse:
            return "Could not fetch hash from server for PayU."
        case .sdkNotAvailable:
            return "PayU CheckoutPro SDK is not linked. Add package https://github.com/payu-intrepos/PayUCheckoutPro-iOS."
        case .launchFailed:
            return "Unable to open PayU CheckoutPro screen."
        case .networkFailure(let message):
            return "Hash API failed: \(message)"
        }
    }
}

final class PayUService: NSObject {
    static let shared = PayUService()

    private override init() {}

    private struct HashRequestBody: Codable {
        let hashName: String
        let hashString: String
        let postSalt: String
        let transactionId: String
    }

    private struct HashResponseBody: Decodable {
        let hash: String
    }

    private struct Configuration {
        let merchantKey: String
        let hashEndpoint: URL
        let environment: String
        let successURL: String
        let failureURL: String
        let userCredentialPrefix: String?
        let merchantDisplayName: String?
    }

    private var completion: ((PayUCheckoutOutcome) -> Void)?

    func startCheckout(
        amount: Double,
        productInfo: String,
        firstName: String,
        email: String,
        phone: String,
        userIdentifier: String,
        completion: @escaping (PayUCheckoutOutcome) -> Void
    ) async throws -> String {
        let config = try loadConfiguration()

        #if canImport(PayUCheckoutProKit) && canImport(PayUCheckoutProBaseKit) && canImport(PayUParamsKit)
        guard let presenter = topMostViewController() else {
            throw PayUServiceError.launchFailed
        }

        let transactionId = makeTransactionId()
        let formattedAmount = String(format: "%.2f", amount)
        let env: Environment = config.environment.lowercased() == "production" ? .production : .test

        let paymentParam = PayUPaymentParam(
            key: config.merchantKey,
            transactionId: transactionId,
            amount: formattedAmount,
            productInfo: productInfo,
            firstName: firstName,
            email: email,
            phone: phone,
            surl: config.successURL,
            furl: config.failureURL,
            environment: env
        )

        if let prefix = config.userCredentialPrefix, !prefix.isEmpty {
            paymentParam.userCredential = "\(prefix):\(userIdentifier)"
        }

        let checkoutConfig = PayUCheckoutProConfig()
        checkoutConfig.merchantName = config.merchantDisplayName

        self.completion = completion
        PayUCheckoutPro.open(on: presenter, paymentParam: paymentParam, config: checkoutConfig, delegate: self)
        return transactionId
        #else
        throw PayUServiceError.sdkNotAvailable
        #endif
    }

    #if canImport(PayUCheckoutProKit) && canImport(PayUCheckoutProBaseKit) && canImport(PayUParamsKit)
    private func topMostViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return nil }
        guard let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return nil }
        return topViewController(from: root)
    }

    private func topViewController(from root: UIViewController) -> UIViewController {
        if let presented = root.presentedViewController {
            return topViewController(from: presented)
        }
        if let nav = root as? UINavigationController, let visible = nav.visibleViewController {
            return topViewController(from: visible)
        }
        if let tab = root as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(from: selected)
        }
        return root
    }
    #endif

    private func loadConfiguration() throws -> Configuration {
        let info = Bundle.main.infoDictionary ?? [:]

        guard let merchantKey = info["PAYU_MERCHANT_KEY"] as? String, !merchantKey.isEmpty else {
            throw PayUServiceError.missingConfiguration("PAYU_MERCHANT_KEY")
        }
        guard let hashEndpointString = info["PAYU_HASH_ENDPOINT"] as? String,
              let hashEndpoint = URL(string: hashEndpointString) else {
            throw PayUServiceError.missingConfiguration("PAYU_HASH_ENDPOINT")
        }
        let environment = (info["PAYU_ENVIRONMENT"] as? String) ?? "test"

        guard let successURL = info["PAYU_SUCCESS_URL"] as? String, !successURL.isEmpty else {
            throw PayUServiceError.missingConfiguration("PAYU_SUCCESS_URL")
        }
        guard let failureURL = info["PAYU_FAILURE_URL"] as? String, !failureURL.isEmpty else {
            throw PayUServiceError.missingConfiguration("PAYU_FAILURE_URL")
        }

        return Configuration(
            merchantKey: merchantKey,
            hashEndpoint: hashEndpoint,
            environment: environment,
            successURL: successURL,
            failureURL: failureURL,
            userCredentialPrefix: info["PAYU_USER_CREDENTIAL_PREFIX"] as? String,
            merchantDisplayName: info["PAYU_MERCHANT_DISPLAY_NAME"] as? String
        )
    }

    private func makeTransactionId() -> String {
        let epoch = Int(Date().timeIntervalSince1970)
        let suffix = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(8)
        return "CT\(epoch)\(suffix)"
    }
}

#if canImport(PayUCheckoutProKit) && canImport(PayUCheckoutProBaseKit) && canImport(PayUParamsKit)
extension PayUService: PayUCheckoutProDelegate {
    func onPaymentSuccess(response: Any?) {
        completion?(.success(response))
        completion = nil
    }

    func onPaymentFailure(response: Any?) {
        completion?(.failure("Payment failed or was declined."))
        completion = nil
    }

    func onPaymentCancel(isTxnInitiated: Bool) {
        completion?(.cancelled)
        completion = nil
    }

    func onError(_ error: Error?) {
        completion?(.failure(error?.localizedDescription ?? "Unknown PayU error"))
        completion = nil
    }

    func generateHash(for param: DictOfString, onCompletion: @escaping PayUHashGenerationCompletion) {
        let hashString = param[HashConstant.hashString] ?? ""
        let hashName = param[HashConstant.hashName] ?? ""
        let postSalt = param[HashConstant.postSalt] ?? ""
        let transactionId = param["txnid"] ?? ""

        guard !hashString.isEmpty, !hashName.isEmpty else {
            onCompletion([:])
            return
        }

        Task {
            do {
                let config = try loadConfiguration()
                let hash = try await fetchHash(
                    from: config.hashEndpoint,
                    payload: HashRequestBody(
                        hashName: hashName,
                        hashString: hashString,
                        postSalt: postSalt,
                        transactionId: transactionId
                    )
                )
                onCompletion([hashName: hash])
            } catch {
                onCompletion([:])
            }
        }
    }

    private func fetchHash(from endpoint: URL, payload: HashRequestBody) async throws -> String {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw PayUServiceError.networkFailure("Non-2xx response from hash API.")
            }

            let decoded = try JSONDecoder().decode(HashResponseBody.self, from: data)
            guard !decoded.hash.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw PayUServiceError.invalidHashResponse
            }
            return decoded.hash
        } catch let error as PayUServiceError {
            throw error
        } catch {
            throw PayUServiceError.networkFailure(error.localizedDescription)
        }
    }
}
#endif
