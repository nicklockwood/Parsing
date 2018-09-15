//
//  Lexer.swift
//  Parsing
//
//  Created by Nick Lockwood on 03/09/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

import Foundation

// MARK: interface

public enum TokenType: Equatable {
    case assign // = operator
    case plus // + operator
    case identifier(String) // letter followed by one or more alphanumeric chars
    case number(Double) // any valid floating point number
    case string(String) // a string literal surrounded by ""
    case `let` // let keyword
    case print // print keyword
    case error(LexerError)
}

public struct Token: Equatable {
    let type: TokenType
    let range: Range<String.Index>
}

public extension String.Index {

    func lineAndColumn(in string: String) -> (line: Int, column: Int) {
        var line = 1, column = 1
        let linebreaks = CharacterSet.newlines
        let scalars = string.unicodeScalars
        var index = scalars.startIndex
        while index < self {
            if linebreaks.contains(scalars[index]) {
                line += 1
                column = 1
            } else {
                column += 1
            }
            index = scalars.index(after: index)
        }
        return (line: line, column: column)
    }
}

public enum LexerError: Error, Equatable {
    case unrecognizedInput(String)
    case unterminatedString
    case malformedNumber
}

public func tokenize(_ input: String) -> [Token] {
    var scalars = Substring(input).unicodeScalars
    var tokens: [Token] = []
    while let token = scalars.readToken() {
        tokens.append(token)
    }
    if !scalars.isEmpty {
        tokens.append(Token(
            type: .error(.unrecognizedInput(String(scalars))),
            range: scalars.startIndex ..< scalars.startIndex
        ))
    }
    return tokens
}

// MARK: implementation

private extension Substring.UnicodeScalarView {

    mutating func skipWhitespace() {
        let whitespace = CharacterSet.whitespacesAndNewlines
        while let scalar = self.first, whitespace.contains(scalar) {
            self.removeFirst()
        }
    }

    mutating func readOperator() -> TokenType? {
        let start = self
        switch self.popFirst() {
        case "=":
            return .assign
        case "+":
            return .plus
        default:
            self = start
            return nil
        }
    }

    mutating func readIdentifier() -> TokenType? {
        guard let head = self.first, CharacterSet.letters.contains(head) else {
            return nil
        }
        var name = String(self.removeFirst())
        while let c = self.first, CharacterSet.alphanumerics.contains(c) {
            name.append(Character(self.removeFirst()))
        }
        switch name {
        case "let":
            return .let
        case "print":
            return .print
        default:
            return .identifier(name)
        }
    }

    mutating func readNumber() -> TokenType? {
        var digits = ""
        while let c = self.first, CharacterSet.decimalDigits.contains(c) || c == "." {
            digits.append(Character(self.removeFirst()))
        }
        if digits.isEmpty {
            return nil
        } else if let double = Double(digits) {
            return .number(double)
        }
        return .error(.malformedNumber)
    }

    mutating func readString() -> TokenType? {
        guard first == "\"" else {
            return nil
        }
        self.removeFirst()
        var string = "", escaped = false
        while let scalar = self.popFirst() {
            switch scalar {
            case "\"" where !escaped:
                return .string(string)
            case "\\" where !escaped:
                escaped = true
            default:
                string.append(Character(scalar))
                escaped = false
            }
        }
        return .error(.unterminatedString)
    }

    mutating func readToken() -> Token? {
        self.skipWhitespace()
        let start = self.startIndex
        guard let type =
            self.readOperator() ??
            self.readIdentifier() ??
            self.readNumber() ??
            self.readString()
        else {
            return nil
        }
        let end = self.startIndex
        return Token(type: type, range: start ..< end)
    }
}
