//
//  LexerTests.swift
//  ParsingTests
//
//  Created by Nick Lockwood on 03/09/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import Parsing

class LexerTests: XCTestCase {

    // MARK: identifiers

    func testLetters() {
        let input = "abc dfe"
        let tokens: [TokenType] = [.identifier("abc"), .identifier("dfe")]
        XCTAssertEqual(tokenize(input).map { $0.type }, tokens)
    }

    func testLettersAndNumbers() {
        let input = "a1234b"
        let tokens: [TokenType] = [.identifier("a1234b")]
        XCTAssertEqual(tokenize(input).map { $0.type }, tokens)
    }

    func testInvalidIdentifier() {
        let input = "a123_4b"
        let tokens: [TokenType] = [
            .identifier("a123"),
            .error(.unrecognizedInput("_4b"))
        ]
        XCTAssertEqual(tokenize(input).map { $0.type }, tokens)
        let lineAndColumn = tokenize(input).last!.range.lowerBound.lineAndColumn(in: input)
        XCTAssert(lineAndColumn == (line: 1, column: 5))
    }

    // MARK: strings

    func testSimpleString() {
        let input = "\"abcd\""
        let tokens: [TokenType] = [.string("abcd")]
        XCTAssertEqual(tokenize(input).map { $0.type }, tokens)
    }

    func testUnicodeString() {
        let input = "\"😂\""
        let tokens: [TokenType] = [.string("😂")]
        XCTAssertEqual(tokenize(input).map { $0.type }, tokens)
    }

    func testEmptyString() {
        let input = "\"\""
        let tokens: [TokenType] = [.string("")]
        XCTAssertEqual(tokenize(input).map { $0.type }, tokens)
    }

    func testStringWithEscapedQuotes() {
        let input = "\"\\\"hello\\\"\""
        let tokens: [TokenType] = [.string("\"hello\"")]
        XCTAssertEqual(tokenize(input).map { $0.type }, tokens)
    }

    func testStringWithEscapedBackslash() {
        let input = "\"foo\\\\bar\""
        let tokens: [TokenType] = [.string("foo\\bar")]
        XCTAssertEqual(tokenize(input).map { $0.type }, tokens)
    }

    func testUnterminatedString() {
        let input = "\"hello"
        let tokens: [TokenType] = [.error(.unterminatedString)]
        XCTAssertEqual(tokenize(input).map { $0.type }, tokens)
        let lineAndColumn = tokenize(input).last!.range.lowerBound.lineAndColumn(in: input)
        XCTAssert(lineAndColumn == (line: 1, column: 1))
    }

    func testUnterminatedEscapedQuote() {
        let input = "\"hello\\\""
        let tokens: [TokenType] = [.error(.unterminatedString)]
        XCTAssertEqual(tokenize(input).map { $0.type }, tokens)
        let lineAndColumn = tokenize(input).last!.range.lowerBound.lineAndColumn(in: input)
        XCTAssert(lineAndColumn == (line: 1, column: 1))
    }

    // MARK: numbers

    func testZero() {
        let input = "0"
        let tokens: [TokenType] = [.number(0)]
        XCTAssertEqual(tokenize(input).map { $0.type }, tokens)
    }

    func testDigit() {
        let input = "5"
        let tokens: [TokenType] = [.number(5)]
        XCTAssertEqual(tokenize(input).map { $0.type }, tokens)
    }

    func testMultidigit() {
        let input = "50"
        let tokens: [TokenType] = [.number(50)]
        XCTAssertEqual(tokenize(input).map { $0.type }, tokens)
    }

    func testLeadingZero() {
        let input = "05"
        let tokens: [TokenType] = [.number(5)]
        XCTAssertEqual(tokenize(input).map { $0.type }, tokens)
    }

    func testDecimal() {
        let input = "0.5"
        let tokens: [TokenType] = [.number(0.5)]
        XCTAssertEqual(tokenize(input).map { $0.type }, tokens)
    }

    func testLeadingDecimalPoint() {
        let input = ".56"
        let tokens: [TokenType] = [.number(0.56)]
        XCTAssertEqual(tokenize(input).map { $0.type }, tokens)
    }

    func testTrailingDecimalPoint() {
        let input = "56."
        let tokens: [TokenType] = [.number(56)]
        XCTAssertEqual(tokenize(input).map { $0.type }, tokens)
    }

    func testTooManyDecimalPoints() {
        let input = "0.5.6"
        let tokens: [TokenType] = [.error(.malformedNumber)]
        XCTAssertEqual(tokenize(input).map { $0.type }, tokens)
        let lineAndColumn = tokenize(input).last!.range.lowerBound.lineAndColumn(in: input)
        XCTAssert(lineAndColumn == (line: 1, column: 1))
    }

    // MARK: operators

    func testOperators() {
        let input = "a = 4 + b"
        let tokens: [TokenType] = [
            .identifier("a"), .assign, .number(4), .plus, .identifier("b"),
        ]
        XCTAssertEqual(tokenize(input).map { $0.type }, tokens)
    }

    // MARK: statements

    func testDeclaration() {
        let input = """
        let foo = 5
        let bar = "hello"
        let baz = foo
        """
        let tokens: [TokenType] = [
            .let, .identifier("foo"), .assign, .number(5),
            .let, .identifier("bar"), .assign, .string("hello"),
            .let, .identifier("baz"), .assign, .identifier("foo"),
        ]
        XCTAssertEqual(tokenize(input).map { $0.type }, tokens)
    }

    func testPrintStatement() {
        let input = """
        print foo
        print 5
        print "hello" + "world"
        """
        let tokens: [TokenType] = [
            .print, .identifier("foo"),
            .print, .number(5),
            .print, .string("hello"), .plus, .string("world"),
        ]
        XCTAssertEqual(tokenize(input).map { $0.type }, tokens)
    }

    // MARK: line and column

    func testFirstLine() {
        let input = """
        print 1
        print 2
        """
        let lineAndColumn = tokenize(input)[1].range.lowerBound.lineAndColumn(in: input)
        XCTAssert(lineAndColumn == (line: 1, column: 7))
    }

    func testSecondLine() {
        let input = """
        print 1
        print 2
        """
        let lineAndColumn = tokenize(input).last!.range.lowerBound.lineAndColumn(in: input)
        XCTAssert(lineAndColumn == (line: 2, column: 7))
    }
}
