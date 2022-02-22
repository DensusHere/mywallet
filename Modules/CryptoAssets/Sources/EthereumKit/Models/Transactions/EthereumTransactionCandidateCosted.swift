// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import PlatformKit
import WalletCore

public struct EthereumTransactionCandidateCosted {

    let transaction: EthereumSigningInput

    private init(transaction: EthereumSigningInput) {
        self.transaction = transaction
    }

    static func create(
        transaction: EthereumTransactionCandidate
    ) -> Result<EthereumTransactionCandidateCosted, EthereumKitValidationError> {
        guard transaction.gasPrice > 0 else {
            return .failure(.noGasPrice)
        }
        guard transaction.gasLimit > 0 else {
            return .failure(.noGasLimit)
        }
        let costed = EthereumTransactionCandidateCosted(
            transaction: signingInput(with: transaction)
        )
        return .success(costed)
    }

    private static func signingInput(
        with candidate: EthereumTransactionCandidate
    ) -> EthereumSigningInput {
        EthereumSigningInput.with { input in
            input.chainID = Data(hexString: candidate.chainID.hexString)!
            input.nonce = Data(hexString: candidate.nonce.hexString)!
            input.gasPrice = Data(hexString: candidate.gasPrice.hexString)!
            input.gasLimit = Data(hexString: candidate.gasLimit.hexString)!

            switch candidate.transferType {
            case .erc20Transfer(let contractAddress, let addressReference):
                input.toAddress = contractAddress.publicKey
                input.transaction = EthereumTransaction.with { transaction in
                    transaction.erc20Transfer = EthereumTransaction.ERC20Transfer.with { transfer in
                        transfer.to = candidate.to.publicKey
                        transfer.amount = Data(hexString: candidate.value.hexString)!
                        transfer.addressReference = addressReference?.publicKey ?? ""
                    }
                }
            case .transfer(let data):
                input.toAddress = candidate.to.publicKey
                input.transaction = EthereumTransaction.with { transaction in
                    transaction.transfer = EthereumTransaction.Transfer.with { transfer in
                        transfer.amount = Data(hexString: candidate.value.hexString)!
                        transfer.data = data ?? Data()
                    }
                }
            }
        }
    }
}
