import BlockchainNamespace
import XCTest

func XCTAssertAnyEqual<V>(
    _ expression1: @autoclosure () throws -> [V],
    _ expression2: @autoclosure () throws -> [V],
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) rethrows {
    let (a, b) = try (expression1(), expression2())
    XCTAssertTrue(isEqual(a, b), "\(a) does not equal \(b): \(message())", file: file, line: line)
}

func XCTAssertAnyEqual<K: Hashable, V>(
    _ expression1: @autoclosure () throws -> [K: V],
    _ expression2: @autoclosure () throws -> [K: V],
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) rethrows {
    let (a, b) = try (expression1(), expression2())
    XCTAssertTrue(isEqual(a, b), "\(a) does not equal \(b): \(message())", file: file, line: line)
}
