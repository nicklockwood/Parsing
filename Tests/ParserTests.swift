//
//  ParserTests.swift
//  ParsingTests
//
//  Created by Nick Lockwood on 03/09/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import Parsing

class ParserTests: XCTestCase {

    // MARK: declarations

    func testDeclareWithNumber() {
        let input = "let foo = 5"
        let program = [
            Statement(
                type: .declaration(
                    name: "foo",
                    value: Expression(type: .number(5), range: input.range(of: "5")!)
                ),
                range: input.startIndex ..< input.endIndex
            )
        ]
        XCTAssertEqual(try parse(input), program)
    }

    func testDeclareWithString() {
        let input = "let foo = \"foo\""
        let program = [
            Statement(
                type: .declaration(
                    name: "foo",
                    value: Expression(type: .string("foo"), range: input.range(of: "\"foo\"")!)
                ),
                range: input.startIndex ..< input.endIndex
            )
        ]
        XCTAssertEqual(try parse(input), program)
    }

    func testDeclareWithVariable() {
        let input = "let foo = bar"
        let program = [
            Statement(
                type: .declaration(
                    name: "foo",
                    value: Expression(type: .variable("bar"), range: input.range(of: "bar")!)
                ),
                range: input.startIndex ..< input.endIndex
            )
        ]
        XCTAssertEqual(try parse(input), program)
    }

    func testDeclareWithAddition() {
        let input = "let foo = 1 + 2"
        let program = [
            Statement(
                type: .declaration(
                    name: "foo",
                    value: Expression(
                        type: .addition(
                            lhs: Expression(type: .number(1), range: input.range(of: "1")!),
                            rhs: Expression(type: .number(2), range: input.range(of: "2")!)
                        ),
                        range: input.range(of: "1 + 2")!
                    )
                ),
                range: input.startIndex ..< input.endIndex
            )
        ]
        XCTAssertEqual(try parse(input), program)
    }

    func testMissingDeclareValue() {
        let input = "let foo ="
        let expected = ParserError.missingExpression(at: input.endIndex)
        XCTAssertThrowsError(try parse(input)) { error in
            XCTAssertEqual(error as? ParserError, expected)
        }
    }

    func testMissingDeclareVariable() {
        let input = "let = bar"
        let expected = ParserError.missingIdentifier(at: input.index(of: " ")!)
        XCTAssertThrowsError(try parse(input)) { error in
            XCTAssertEqual(error as? ParserError, expected)
        }
    }

    func testMissingAssignOperator() {
        let input = "let foo"
        let expected = ParserError.missingAssign(at: input.endIndex)
        XCTAssertThrowsError(try parse(input)) { error in
            XCTAssertEqual(error as? ParserError, expected)
        }
    }

    // MARK: print statements

    func testPrintNumber() {
        let input = "print 5.5"
        let program = [
            Statement(
                type: .print(Expression(
                    type: .number(5.5),
                    range: input.range(of: "5.5")!
                )),
                range: input.startIndex ..< input.endIndex
            )
        ]
        XCTAssertEqual(try parse(input), program)
    }

    func testMissingPrintValue() {
        let input = "print"
        let expected = ParserError.missingExpression(at: input.endIndex)
        XCTAssertThrowsError(try parse(input)) { error in
            XCTAssertEqual(error as? ParserError, expected)
        }
    }

    func testMissingOperand() {
        let input = "print 5 +"
        let expected = ParserError.missingExpression(at: input.endIndex)
        XCTAssertThrowsError(try parse(input)) { error in
            XCTAssertEqual(error as? ParserError, expected)
        }
    }

    func testUnknownStatement() {
        let input = "let foo = 5\nprintf foo"
        let expected = ParserError.unexpectedToken(
            Token(type: .identifier("printf"), range: input.range(of: "printf")!)
        )
        XCTAssertThrowsError(try parse(input)) { error in
            XCTAssertEqual(error as? ParserError, expected)
        }
    }
}
