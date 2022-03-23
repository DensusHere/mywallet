// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComposableArchitecture
import ComposableNavigation
@testable import FeatureCryptoDomainData
@testable import FeatureCryptoDomainDomain
@testable import FeatureCryptoDomainMock
@testable import FeatureCryptoDomainUI
import NetworkKit
import OrderedCollections
import TestKit
import ToolKit
import XCTest

final class SearchCryptoDomainReducerTests: XCTestCase {

    private var mockMainQueue: ImmediateSchedulerOf<DispatchQueue>!
    private var testStore: TestStore<
        SearchCryptoDomainState,
        SearchCryptoDomainState,
        SearchCryptoDomainAction,
        SearchCryptoDomainAction,
        SearchCryptoDomainEnvironment
    >!
    private var searchClient: SearchDomainClientAPI!
    private var orderClient: OrderDomainClientAPI!

    override func setUpWithError() throws {
        try super.setUpWithError()
        (searchClient, _) = SearchDomainClient.test()
        (orderClient, _) = OrderDomainClient.test()
        mockMainQueue = DispatchQueue.immediate
        testStore = TestStore(
            initialState: .init(),
            reducer: searchCryptoDomainReducer,
            environment: SearchCryptoDomainEnvironment(
                mainQueue: mockMainQueue.eraseToAnyScheduler(),
                externalAppOpener: ToLogAppOpener(),
                searchDomainRepository: SearchDomainRepository(
                    apiClient: searchClient
                ),
                orderDomainRepository: OrderDomainRepository(
                    apiClient: orderClient
                ),
                userInfoProvider: {
                    .just(
                        OrderDomainUserInfo(
                            nabuUserId: "mockUserId",
                            nabuUserName: "Firstname",
                            resolutionRecords: []
                        )
                    )
                }
            )
        )
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        mockMainQueue = nil
        testStore = nil
    }

    func test_on_appear_should_search_domains_by_firstname() throws {
        let expectedResults = try testStore
            .environment
            .searchDomainRepository
            .searchResults(searchKey: "Firstname", freeOnly: true)
            .wait()
        testStore.send(.onAppear)
        testStore.receive(.searchDomainsWithUsername)
        testStore.receive(.searchDomains(key: "Firstname", freeOnly: true)) { state in
            state.isSearchResultsLoading = true
        }
        testStore.receive(.didReceiveDomainsResult(.success(expectedResults))) { state in
            state.isSearchResultsLoading = false
            state.searchResults = expectedResults
        }
    }

    func test_empty_search_text_should_search_domains_by_username() throws {
        let expectedResults = try testStore
            .environment
            .searchDomainRepository
            .searchResults(searchKey: "Firstname", freeOnly: true)
            .wait()
        testStore.send(.set(\.$searchText, "")) { state in
            state.isSearchTextValid = true
            state.searchText = ""
        }
        testStore.receive(.searchDomains(key: "", freeOnly: false))
        testStore.receive(.searchDomainsWithUsername)
        testStore.receive(.searchDomains(key: "Firstname", freeOnly: true)) { state in
            state.isSearchResultsLoading = true
        }
        testStore.receive(.didReceiveDomainsResult(.success(expectedResults))) { state in
            state.isSearchResultsLoading = false
            state.searchResults = expectedResults
        }
    }

    func test_valid_search_text_should_search_domains() throws {
        let expectedResults = try testStore
            .environment
            .searchDomainRepository
            .searchResults(searchKey: "Searchkey", freeOnly: false)
            .wait()
        testStore.send(.set(\.$searchText, "Searchkey")) { state in
            state.isSearchTextValid = true
            state.searchText = "Searchkey"
        }
        testStore.receive(.searchDomains(key: "Searchkey", freeOnly: false)) { state in
            state.isSearchResultsLoading = true
        }
        testStore.receive(.didReceiveDomainsResult(.success(expectedResults))) { state in
            state.isSearchResultsLoading = false
            state.searchResults = expectedResults
        }
    }

    func test_invalid_search_text_should_not_search_domains() {
        testStore.send(.set(\.$searchText, "in.valid")) { state in
            state.isSearchTextValid = false
            state.searchText = "in.valid"
        }
    }

    func test_select_free_domain_should_go_to_checkout() {
        let testDomain = SearchDomainResult(
            domainName: "free.blockchain",
            domainType: .free,
            domainAvailability: .availableForFree
        )
        testStore.send(.selectFreeDomain(testDomain)) { state in
            state.selectedDomains = OrderedSet([testDomain])
        }
        testStore.receive(.navigate(to: .checkout)) { state in
            state.route = RouteIntent(route: .checkout, action: .navigateTo)
            state.checkoutState = .init(
                selectedDomains: OrderedSet([testDomain])
            )
        }
    }

    func test_select_premium_domain_should_open_bottom_sheet() throws {
        let expectedResult = try testStore
            .environment
            .orderDomainRepository
            .createDomainOrder(
                isFree: false,
                domainName: "premium",
                resolutionRecords: nil,
                nabuUserId: nil
            )
            .wait()
        let testDomain = SearchDomainResult(
            domainName: "premium.blockchain",
            domainType: .premium,
            domainAvailability: .availableForPremiumSale(price: "50")
        )
        testStore.send(.selectPremiumDomain(testDomain)) { state in
            state.selectedPremiumDomain = testDomain
        }
        testStore.receive(.set(\.$isPremiumDomainBottomSheetShown, true)) { state in
            state.isPremiumDomainBottomSheetShown = true
        }
        testStore.receive(.didSelectPremiumDomain(.success(expectedResult))) { state in
            state.selectedPremiumDomainRedirectUrl = expectedResult.redirectUrl ?? ""
        }
    }

    func test_remove_at_checkout_should_update_state() {
        let testDomain = SearchDomainResult(
            domainName: "free.blockchain",
            domainType: .free,
            domainAvailability: .availableForFree
        )
        testStore.send(.selectFreeDomain(testDomain)) { state in
            state.selectedDomains = OrderedSet([testDomain])
        }
        testStore.receive(.navigate(to: .checkout)) { state in
            state.route = RouteIntent(route: .checkout, action: .navigateTo)
            state.checkoutState = .init(
                selectedDomains: OrderedSet([testDomain])
            )
        }
        testStore.send(.checkoutAction(.removeDomain(testDomain))) { state in
            state.checkoutState?.selectedDomains = OrderedSet([])
            state.selectedDomains = OrderedSet([])
        }
        testStore.receive(.checkoutAction(.set(\.$isRemoveBottomSheetShown, false)))
        testStore.receive(.dismiss()) { state in
            state.route = nil
        }
    }
}
