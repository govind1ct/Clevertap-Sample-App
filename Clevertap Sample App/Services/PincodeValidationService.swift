import Foundation

struct PincodeValidationResult {
    let pincode: String
    let district: String
    let state: String
    let postOfficeName: String
}

enum PincodeValidationError: LocalizedError {
    case invalidFormat
    case invalidPincode
    case serviceUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Please enter a valid 6-digit pincode."
        case .invalidPincode:
            return "This pincode could not be verified for delivery."
        case .serviceUnavailable:
            return "Unable to verify pincode right now. Please try again."
        }
    }
}

final class PincodeValidationService {
    static let shared = PincodeValidationService()
    private init() {}

    private struct IndiaPostResponse: Decodable {
        let status: String
        let message: String
        let postOffice: [PostOffice]?

        enum CodingKeys: String, CodingKey {
            case status = "Status"
            case message = "Message"
            case postOffice = "PostOffice"
        }
    }

    private struct PostOffice: Decodable {
        let name: String
        let district: String
        let state: String
        let pincode: String

        enum CodingKeys: String, CodingKey {
            case name = "Name"
            case district = "District"
            case state = "State"
            case pincode = "Pincode"
        }
    }

    func validatePincode(_ rawPincode: String) async throws -> PincodeValidationResult {
        let pincode = rawPincode.filter(\.isNumber)
        guard pincode.count == 6 else {
            throw PincodeValidationError.invalidFormat
        }

        guard let url = URL(string: "https://api.postalpincode.in/pincode/\(pincode)") else {
            throw PincodeValidationError.serviceUnavailable
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw PincodeValidationError.serviceUnavailable
            }

            let decoded = try JSONDecoder().decode([IndiaPostResponse].self, from: data)
            guard let first = decoded.first else {
                throw PincodeValidationError.serviceUnavailable
            }

            guard first.status.caseInsensitiveCompare("Success") == .orderedSame,
                  let postOffice = first.postOffice?.first else {
                throw PincodeValidationError.invalidPincode
            }

            return PincodeValidationResult(
                pincode: pincode,
                district: postOffice.district,
                state: postOffice.state,
                postOfficeName: postOffice.name
            )
        } catch let error as PincodeValidationError {
            throw error
        } catch {
            throw PincodeValidationError.serviceUnavailable
        }
    }
}
