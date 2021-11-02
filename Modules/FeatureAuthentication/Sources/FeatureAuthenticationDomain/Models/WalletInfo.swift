// Copyright © Blockchain Luxembourg S.A. All rights reserved.

public enum WalletInfoError: Error {
    case failToDecodeBase64Component
    case failToDecodeToWalletInfo(Error)
}

public struct WalletInfo: Decodable, Equatable {

    // MARK: - Type

    private enum CodingKeys: String, CodingKey {
        case wallet
        case guid
        case email
        case emailCode = "email_code"
        case isMobileSetup = "is_mobile_setup"
        case hasCloudBackup = "has_cloud_backup"
        case nabu
        case unified
        case upgradeable
        case mergeable
        case userType = "user_type"
    }

    public struct NabuInfo: Decodable, Equatable {
        public let userId: String
        public let recoveryToken: String

        private enum NabuInfoCodingKeys: String, CodingKey {
            case userId = "user_id"
            case recoveryToken = "recovery_token"
        }

        public init(
            userId: String,
            recoveryToken: String
        ) {
            self.userId = userId
            self.recoveryToken = recoveryToken
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: NabuInfoCodingKeys.self)
            userId = try container.decode(String.self, forKey: .userId)
            recoveryToken = try container.decode(String.self, forKey: .recoveryToken)
        }
    }

    // MARK: - Properties

    public static let empty = WalletInfo(
        guid: "",
        email: nil,
        emailCode: nil,
        isMobileSetup: nil,
        hasCloudBackup: nil,
        nabuInfo: nil,
        unified: nil,
        upgradeable: nil,
        mergeable: nil,
        userType: nil
    )

    public let guid: String
    public let email: String?
    public let emailCode: String?
    public let isMobileSetup: Bool?
    public let hasCloudBackup: Bool?
    public let nabuInfo: NabuInfo?
    public let unified: Bool?
    public let upgradeable: Bool?
    public let mergeable: Bool?
    public let userType: String?

    // MARK: - Setup

    public init(
        guid: String,
        email: String? = nil,
        emailCode: String? = nil,
        isMobileSetup: Bool? = nil,
        hasCloudBackup: Bool? = nil,
        nabuInfo: NabuInfo? = nil,
        unified: Bool? = nil,
        upgradeable: Bool? = nil,
        mergeable: Bool? = nil,
        userType: String? = nil
    ) {
        self.guid = guid
        self.email = email
        self.emailCode = emailCode
        self.isMobileSetup = isMobileSetup
        self.hasCloudBackup = hasCloudBackup
        self.nabuInfo = nabuInfo
        self.unified = unified
        self.upgradeable = upgradeable
        self.mergeable = mergeable
        self.userType = userType
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder
            .container(keyedBy: CodingKeys.self)
        let wallet = try container
            .nestedContainer(keyedBy: CodingKeys.self, forKey: .wallet)
        guid = try wallet.decode(String.self, forKey: .guid)
        email = try wallet.decode(String.self, forKey: .email)
        emailCode = try wallet.decode(String.self, forKey: .emailCode)
        isMobileSetup = try wallet
            .decodeIfPresent(Bool.self, forKey: .isMobileSetup)
        hasCloudBackup = try wallet
            .decodeIfPresent(Bool.self, forKey: .hasCloudBackup)
        nabuInfo = try wallet
            .decodeIfPresent(NabuInfo.self, forKey: .nabu)
        unified = try container.decodeIfPresent(Bool.self, forKey: .unified)
        upgradeable = try container.decodeIfPresent(Bool.self, forKey: .upgradeable)
        mergeable = try container.decodeIfPresent(Bool.self, forKey: .mergeable)
        userType = try container.decodeIfPresent(String.self, forKey: .userType)
    }
}
