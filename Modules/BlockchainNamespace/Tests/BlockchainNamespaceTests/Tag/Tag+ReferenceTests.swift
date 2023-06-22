@testable import BlockchainNamespace
import XCTest

final class TagReferenceTests: XCTestCase {

    let app = App()
    let id = "0d98d78bdba916ee6b556c2a39abd55f1adda467d319f8d492ea3df9c662671d"

    func test_reference_to_user() throws {

        let ref = try blockchain.user.name.first[]
            .ref(to: [blockchain.user.id: id])
            .validated()

        XCTAssertFalse(ref.hasError)
        XCTAssertEqual(ref.indices[blockchain.user.id], id)
        XCTAssertEqual(ref.string, "blockchain.user.name.first")
        XCTAssertEqual(ref.id(ignoring: [blockchain.user.id[]]), "blockchain.user.name.first")
        XCTAssertEqual(ref.id(ignoring: []), "blockchain.user[\(id)].name.first")
    }

    func test_reference_with_invalid_indices() throws {
        let ref = blockchain.user.name.first[].reference
        XCTAssertThrowsError(try ref.validated())
    }

    func test_reference_to_user_with_additional_context() throws {

        let ref = blockchain.user.name.first[]
            .ref(
                to: [
                    blockchain.user.id: id,
                    blockchain.app.configuration.apple.pay.is.enabled: true
                ]
            )

        XCTAssertEqual(ref.indices, [blockchain.user.id[]: id])

        XCTAssertEqual(
            ref.context,
            Tag.Context(
                [
                    blockchain.user.id[]: id,
                    blockchain.app.configuration.apple.pay.is.enabled[]: true
                ]
            )
        )
    }

    func test_init_id() throws {
        do {
            let ref = try Tag.Reference(id: "blockchain.user.name.first", in: app.language)
            XCTAssertEqual(ref.string, "blockchain.user.name.first")
        }
        do {
            let ref = try Tag.Reference(id: "blockchain.user[\(id)].name.first", in: app.language)
            XCTAssertEqual(ref.string, "blockchain.user.name.first")
            XCTAssertEqual(ref.context[blockchain.user.id], id)
        }
        do {
            let ref = try Tag.Reference(id: "blockchain.user[id].name.first", in: app.language)
            XCTAssertEqual(ref.string, "blockchain.user.name.first")
            XCTAssertEqual(ref.context[blockchain.user.id], "id")
        }
        do {
            let ref = try Tag.Reference(id: "blockchain.user[blockchain.user.id].name.first", in: app.language)
            XCTAssertEqual(ref.string, "blockchain.user.name.first")
            XCTAssertEqual(ref.context[blockchain.user.id], "blockchain.user.id")
        }
        do {
            let ref = try Tag.Reference(id: "blockchain.user[x].name[y].first", in: app.language)
            XCTAssertEqual(ref.string, "blockchain.user.name.first")
            XCTAssertEqual(ref.context[blockchain.user], "x")
            XCTAssertEqual(ref.context[blockchain.user.name], "y")
            XCTAssertEqual(ref.indices[blockchain.user.id], "x")
            XCTAssertNil(ref.indices[blockchain.user.name])
        }
    }

    func test_init_id_missing_indices() throws {
        do {
            let ref = try Tag.Reference(id: "blockchain.user.name.first", in: app.language)
            XCTAssertEqual(ref.string, "blockchain.user.name.first")
            try ref.validated()
        } catch let error as Tag.Indexing.Error {
            XCTAssertEqual(error.description, "Missing index blockchain.user.id in blockchain.user.name.first")
        }
    }

    func test_ref_fetch_indices_from_state() throws {

        app.state.set(blockchain.user.id, to: id)

        let ref = try blockchain.user.name.first[]
            .ref(in: app)
            .validated()

        XCTAssertEqual(ref.indices[blockchain.user.id], id)
    }

    func test_switch_case_matching() throws {

        enum Users: String {
            case dorothy
            case scarecrow
            case tinWoodman
            case cowardlyLion
        }

        app.signIn(userId: Users.dorothy.rawValue)

        let tags: [Tag.Reference] = [
            /* 0 */ blockchain.user["dorothy"].is.verified.key(),
            /* 1 */ blockchain.user.is.verified[].ref(to: [blockchain.user.id: "dorothy"]),
            /* 2 */ blockchain.user[Users.dorothy].is.verified.key(),
            /* 3 */ blockchain.user.is.verified[].ref(to: [blockchain.user.id: Users.dorothy]),
            /* 4 */ blockchain.user.is.verified[].ref(in: app)
        ]

        for (i, tag) in try tags.map({ try $0.validated() }).enumerated() {
            switch tag {
            case blockchain.user[Users.dorothy].is.verified: break
            default: XCTFail("\(i) \(tag) doesn't match enum-y")
            }
            
            switch tag {
            case blockchain.user["dorothy"].is.verified: break
            default: XCTFail("\(i) \(tag) doesn't match stringy")
            }
            
            switch tag {
            case blockchain.user.is.verified: break
            default: XCTFail("\(i) \(tag) doesn't match")
            }
        }
    }
}
