import BlockchainUI
import FeatureKYCDomain
import SwiftUI
import FeatureCustodialOnboarding

struct SSNInputView: View {

    @Binding var SSN: String
    private var isValid: Bool
    @State private var isFirstResponder: Bool = false
    @State private var isHidingSSN: Bool = false

    init(SSN: Binding<String>, isValid: Bool) {
        _SSN = SSN
        self.isValid = isValid
    }

    var state: InputState {
        if isValid { return .success }
        if SSN.isEmpty { return .default }
        return .error
    }

    var body: some View {
        Input(
            text: isHidingSSN ? $SSN : binding,
            isFirstResponder: $isFirstResponder,
            placeholder: "123-45-6789",
            state: state,
            isSecure: isHidingSSN,
            trailing: {
                if isHidingSSN {
                    IconButton(icon: .`visibilityOn`, toggle: $isHidingSSN)
                } else {
                    IconButton(icon: .`visibilityOff`, toggle: $isHidingSSN)
                }
            }
        )
        .keyboardType(.numberPad)
    }

    var binding: Binding<String> {
        Binding<String>(
            get: {
                var temporary = ""
                for (i, character) in SSN.enumerated() {
                    temporary.append(character)
                    if i == 2 || i == 4 { temporary.append("-") }
                }
                return temporary
            },
            set: { newValue in
                let sanitized = newValue.replacingOccurrences(of: "-", with: "")
                guard sanitized.allSatisfy(\.isNumber) else { return }
                SSN = sanitized
            }
        )
    }
}

struct SSNCollectionView: View {

    @State private var SSN: String = ""
    @State private var error: UX.Error?
    @State private var isWhyPresented: Bool = false

    @StateObject var service = SubmitSSNService()

    var action: (String) -> Void

    var body: some View {
        if service.isTimeout {
            VerificationInProgressView()
                .transition(.move(edge: .trailing))
        } else {

            VStack {
                VStack(alignment: .leading, spacing: 24.pt) {
                    VStack(alignment: .leading, spacing: 8.pt) {
                        Text(LocalizationConstants.SSN.title)
                            .typography(.title3)
                            .foregroundColor(.semantic.title)
                        Text(LocalizationConstants.SSN.subtitle)
                            .typography(.body1)
                            .foregroundColor(.semantic.text)
                    }
                    VStack(alignment: .leading, spacing: 4.pt) {
                        SSNInputView(SSN: $SSN.didSet { _ in error = nil }, isValid: isValid)
                        if let error {
                            Text(error.message)
                                .typography(.caption1)
                                .foregroundColor(.semantic.error)
                        } else {
                            Button(
                                action: {
                                    withAnimation { isWhyPresented = true }
                                },
                                label: {
                                    Text(LocalizationConstants.SSN.why)
                                        .typography(.caption1)
                                        .foregroundColor(.semantic.primary)
                                }
                            )
                        }
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
                PrimaryButton(
                    title: LocalizationConstants.SSN.next,
                    isLoading: service.isLoading,
                    action: {
                        Task {
                            self.error = nil
                            do {
                                try await service.submit(SSN: SSN)
                                action(SSN)
                            } catch {
                                print(error)
                                self.error = UX.Error(error: error)
                            }
                        }
                    }
                )
                .disabled(!isValid)
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding()
            .background(Color.semantic.light.ignoresSafeArea())
            .bottomSheet(isPresented: $isWhyPresented.animation()) {
                WhySheet(isPresented: $isWhyPresented)
            }
            .bindings {
                subscribe($pattern, to: blockchain.api.nabu.gateway.onboarding.SSN.regex.validation)
            }
        }
    }

    struct WhySheet: View {

        @Environment(\.openURL) var openURL
        @Binding var isPresented: Bool

        @State private var url: URL?

        var body: some View {
            VStack(spacing: 16.pt) {
                Text(LocalizationConstants.SSN.whyTitle)
                    .typography(.title3)
                    .foregroundColor(.semantic.title)
                Text(LocalizationConstants.SSN.whyBody)
                    .typography(.body1)
                    .foregroundColor(.semantic.text)
                if let url {
                    SmallMinimalButton(
                        title: LocalizationConstants.SSN.learnMore,
                        action: { openURL(url) }
                    )
                    .padding(.vertical, 16.pt)
                }
                PrimaryButton(
                    title: LocalizationConstants.SSN.gotIt,
                    action: { withAnimation { isPresented = false } }
                )
            }
            .multilineTextAlignment(.center)
            .padding(16.pt)
            .bindings {
                subscribe($url, to: blockchain.ux.kyc.SSN.why.learn.more.url)
            }
        }
    }

    @State private var pattern: String = #"^\d{9}$"#

    var isValid: Bool {
        error == nil && NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: SSN)
    }
}

class SubmitSSNService: ObservableObject {

    @Dependency(\.KYCSSNRepository) private var repository: KYCSSNRepository
    @Dependency(\.scheduler) private var scheduler: AnySchedulerOf<DispatchQueue>

    @Published var isLoading: Bool = false
    @Published var isTimeout: Bool = false

    init() { }

    @MainActor func submit(SSN: String) async throws {
        isLoading = true
        defer { isLoading = false }
        try await repository.submitSSN(SSN).await()
        do {
            let SSN = try await repository.checkSSN()
                .poll(
                    max: 20,
                    until: { SSN in SSN.verification?.state.isFinal ?? false },
                    delay: .seconds(3),
                    scheduler: scheduler
                )
                .await()
            if let message = SSN.verification?.errorMessage {
                throw UX.Error(
                    title: LocalizationConstants.SSN.timedOutTitle,
                    message: message
                )
            }
        } catch PublisherTimeoutError.timeout {
            withAnimation { isTimeout = true }
        } catch let error as UX.Error where error == .timeout {
            withAnimation { isTimeout = true }
        }
    }
}

struct SSNCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        SSNCollectionView(
            service: withDependencies { dependencies in
                dependencies.KYCSSNRepository = KYCSSNRepository(
                    app: App.preview,
                    client: PreviewKYCSSNClient(
                        submit: .success(()),
                        check: { _ in
                            return .failure(
                                Nabu.Error(
                                    id: "abcdef",
                                    code: .unknownUser,
                                    type: .forbidden
                                )
                            )
                        }
                    )
                )
                dependencies.scheduler = .immediate
            } operation: {
                SubmitSSNService()
            },
            action: { ssn in print(ssn) }
        )
    }
}

public struct SchedulerDependencyKey: DependencyKey {
    public static var liveValue: AnySchedulerOf<DispatchQueue> = DispatchQueue.main.eraseToAnyScheduler()
    public static let previewValue: AnySchedulerOf<DispatchQueue> = DispatchQueue.main.eraseToAnyScheduler()
    public static let testValue: AnySchedulerOf<DispatchQueue> = DispatchQueue.test.eraseToAnyScheduler()
}

extension DependencyValues {

    public var scheduler: AnySchedulerOf<DispatchQueue> {
        get { self[SchedulerDependencyKey.self] }
        set { self[SchedulerDependencyKey.self] = newValue }
    }
}
