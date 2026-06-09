import Foundation
import Supabase

final class SupabaseManager {

    static let shared = SupabaseManager()

    let client: SupabaseClient
    let defaultDecoder: JSONDecoder

    private init() {
        let dbDecoder = JSONDecoder()
        dbDecoder.keyDecodingStrategy = .convertFromSnakeCase
        dbDecoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)

            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: string) {
                return date
            }
            isoFormatter.formatOptions = [.withInternetDateTime]
            if let date = isoFormatter.date(from: string) {
                return date
            }

            let formatters = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ",
                "yyyy-MM-dd'T'HH:mm:ss.SSS",
                "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
                "yyyy-MM-dd'T'HH:mm:ss",
                "yyyy-MM-dd"
            ]

            let dateFormatter = DateFormatter()
            dateFormatter.calendar = Calendar(identifier: .iso8601)
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

            for format in formatters {
                dateFormatter.dateFormat = format
                if let date = dateFormatter.date(from: string) {
                    return date
                }
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date format: \(string)"
            )
        }

        let dbEncoder = JSONEncoder()
        dbEncoder.keyEncodingStrategy = .convertToSnakeCase
        dbEncoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let string = formatter.string(from: date)
            try container.encode(string)
        }

        defaultDecoder = dbDecoder

        client = SupabaseClient(
            supabaseURL: AppConfiguration.supabaseURL,
            supabaseKey: AppConfiguration.supabaseKey,
            options: SupabaseClientOptions(
                db: SupabaseClientOptions.DatabaseOptions(
                    encoder: dbEncoder,
                    decoder: dbDecoder
                )
            )
        )
    }
}
