import BlockchainComponentLibrary
import BlockchainNamespace
import ComposableArchitecture
import Localization
import SwiftUI

public struct FeatureSuperAppIntroView: View {
    let store: StoreOf<FeatureSuperAppIntro>

    public init(store: StoreOf<FeatureSuperAppIntro>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store) { viewStore in
            PrimaryNavigationView {
                contentView
                    .primaryNavigation(trailing: {
                        Button {
                            viewStore.send(.onDismiss)
                        } label: {
                            Icon.close
                        }
                    })
            }
        }
    }

    private var contentView: some View {
        WithViewStore(self.store) { viewStore in
            VStack {
                ZStack {
                    carouselContentSection()
                    buttonsSection()
                        .padding(.bottom, Spacing.padding6)
                }
                .background(
                    ZStack {
                        Color.white.ignoresSafeArea()
                        Image("gradient", bundle: .featureSuperAppIntro)
                            .resizable()
                            .opacity(viewStore.gradientBackgroundOpacity)
                            .ignoresSafeArea(.all)
                    }
                )
            }
        }
    }
}

extension FeatureSuperAppIntro.State.Step {
    @ViewBuilder public func makeView() -> some View {
        switch self {
        case .walletJustGotBetter:
            carouselView(
                image: {
                    Image("icon_blockchain_blue", bundle: .featureSuperAppIntro)
                },
                title: LocalizationConstants.SuperAppIntro.CarouselPage1.title,
                text: LocalizationConstants.SuperAppIntro.CarouselPage1.subtitle
            )
            .tag(self)
        case .newWayToNavigate:
            carouselView(
                image: {
                    Image("image_superapp_intro_slide2", bundle: .featureSuperAppIntro)
                },
                title: LocalizationConstants.SuperAppIntro.CarouselPage2.title,
                text: LocalizationConstants.SuperAppIntro.CarouselPage2.subtitle
            )
            .tag(self)
        case .newHomeForDefi:
            carouselView(
                image: {
                    Image("image_superapp_intro_slide3", bundle: .featureSuperAppIntro)
                },
                title: LocalizationConstants.SuperAppIntro.CarouselPage3.title,
                text: LocalizationConstants.SuperAppIntro.CarouselPage3.subtitle,
                badge: LocalizationConstants.SuperAppIntro.CarouselPage3.badge,
                badgeTint: .semantic.defi
            )
            .tag(self)
        case .tradingAccount:
            carouselView(
                image: {
                    Image("image_superapp_intro_slide4", bundle: .featureSuperAppIntro)
                },
                title: LocalizationConstants.SuperAppIntro.CarouselPage4.title,
                text: LocalizationConstants.SuperAppIntro.CarouselPage4.subtitle,
                badge: LocalizationConstants.SuperAppIntro.CarouselPage4.badge,
                badgeTint: .semantic.primary
            )
            .tag(self)
        case .welcomeNewUserV1:
            carouselView(
                image: {
                    Image("icon_blockchain_white", bundle: .featureSuperAppIntro)
                },
                title: LocalizationConstants.SuperAppIntro.V1.NewUser.title,
                text: LocalizationConstants.SuperAppIntro.V1.NewUser.subtitle
            )
            .tag(self)
        case .welcomeExistingUserV1:
            carouselView(
                image: {
                    Image("superAppIntroV1ExistingUser", bundle: .featureSuperAppIntro)
                },
                title: LocalizationConstants.SuperAppIntro.V1.ExistingUser.title,
                text: LocalizationConstants.SuperAppIntro.V1.ExistingUser.subtitle
            )
            .tag(self)
        case .tradingAccountV1:
            carouselView(
                image: {
                    Image("superAppIntroV1Trading", bundle: .featureSuperAppIntro)
                },
                title: LocalizationConstants.SuperAppIntro.V1.TradingAccount.title,
                text: LocalizationConstants.SuperAppIntro.V1.TradingAccount.subtitle,
                badge: LocalizationConstants.SuperAppIntro.V1.TradingAccount.badge,
                badgeTint: .semantic.primary
            )
            .tag(self)
        case .defiWalletV1:
            carouselView(
                image: {
                    Image("superAppIntroV1Defi", bundle: .featureSuperAppIntro)
                },
                title: LocalizationConstants.SuperAppIntro.V1.DefiWallet.title,
                text: LocalizationConstants.SuperAppIntro.V1.DefiWallet.subtitle,
                badge: LocalizationConstants.SuperAppIntro.V1.DefiWallet.badge,
                badgeTint: .semantic.defi
            )
            .tag(self)
        }
    }

    @ViewBuilder private func carouselView(
        @ViewBuilder image: () -> Image,
        title: String,
        text: String,
        badge: String? = nil,
        badgeTint: Color? = nil
    ) -> some View {
        VStack {
            // Image
            VStack {
                Spacer()
                image()
                    .padding()
            }
            .frame(height: 300)

            // Labels
            VStack(
                alignment: .center,
                spacing: Spacing.padding3
            ) {
                Text(title)
                    .lineLimit(2)
                    .typography(.title3)
                    .multilineTextAlignment(.center)
                Text(text)
                    .multilineTextAlignment(.center)
                    .frame(width: 80.vw)
                    .typography(.paragraph1)

                if let badge {
                    TagView(
                        text: badge,
                        variant: .default,
                        size: .small,
                        foregroundColor: badgeTint
                    )
                }
                Spacer()
            }
            .frame(height: 300)
        }
    }
}

extension FeatureSuperAppIntroView {

    @ViewBuilder private func carouselContentSection() -> some View {
        WithViewStore(store) { viewStore in
            TabView(
                selection: viewStore.binding(
                    get: { $0.currentStep },
                    send: { .didChangeStep($0) }
                )
            ) {
                ForEach(viewStore.steps) { step in
                    step.makeView()
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        }
    }

    @ViewBuilder private func buttonsSection() -> some View {
        WithViewStore(store) { viewStore in
            if viewStore.currentStep == viewStore.steps.last {
                VStack(spacing: .zero) {
                    Spacer()
                    if viewStore.flow == .legacy {
                        PrimaryButton(
                            title: LocalizationConstants.SuperAppIntro.getStartedButton,
                            action: {
                                viewStore.send(.onDismiss)
                            }
                        )
                    } else {
                        PrimaryWhiteButton(
                            title: LocalizationConstants.SuperAppIntro.V1.Button.title,
                            action: {
                                viewStore.send(.onDismiss)
                            }
                        )
                        .cornerRadius(Spacing.padding4)
                        .shadow(
                            color: Color.black.opacity(0.15),
                            radius: 8,
                            y: 3
                        )
                    }
                }
                .padding(.horizontal, Spacing.padding3)
                .opacity(viewStore.gradientBackgroundOpacity)
            } else {
                EmptyView()
            }
        }
    }
}

struct FeatureSuperAppIntroView_Previews: PreviewProvider {
    static var previews: some View {
        FeatureSuperAppIntroView(
            store: Store(
                initialState: .init(flow: .newUser),
                reducer: FeatureSuperAppIntro(onDismiss: {})
            )
        )
    }
}

extension AppMode {
    public var displayName: String {
        switch self {
        case .pkw:
            return LocalizationConstants.AppMode.privateKeyWallet
        case .trading:
            return LocalizationConstants.AppMode.tradingAccount
        case .universal:
            return ""
        }
    }
}

extension FeatureSuperAppIntro.State.Flow {
    fileprivate var buttonTitle: String {
        switch self {
        case .legacy:
            return LocalizationConstants.SuperAppIntro.getStartedButton
        default:
            return LocalizationConstants.SuperAppIntro.V1.Button.title
        }
    }
}
