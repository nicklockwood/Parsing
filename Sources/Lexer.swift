//
//  Lexer.swift
//  Parsing
//
//  Created by Nick Lockwood on 03/09/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

import Foundation

// MARK: interface

public enum Token: Equatable {
    case assign // = operator
    case plus // + operator
    case identifier(String) // letter followed by one or more alphanumeric chars
    case number(Double) // any valid floating point number
    case string(String) // a string literal surrounded by ""
    case `let` // let keyword
    case print // print keyword
}

public enum LexerError: Error, Equatable {
    case unrecognizedInput(String)
}

public func tokenize(_ input: String) throws -> [Token] {
    var scalars = Substring(input).unicodeScalars
    var tokens: [Token] = []
    while let token = scalars.readToken() {
        tokens.append(token)
    }
    if !scalars.isEmpty {
        throw LexerError.unrecognizedInput(String(scalars))
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

    mutating func readOperator() -> Token? {
        let start = self
        switch self.popFirst() {
        case "=":
            return Token.assign
        case "+":
            return Token.plus
        default:
            self = start
            return nil
        }
    }

    mutating func readIdentifier() -> Token? {
        guard let head = self.first, CharacterSet.letters.contains(head) else {
            return nil
        }
        var name = String(self.removeFirst())
        while let c = self.first, CharacterSet.alphanumerics.contains(c) {
            name.append(Character(self.removeFirst()))
        }
        switch name {
        case "let":
            return Token.let
        case "print":
            return Token.print
        default:
            return Token.identifier(name)
        }
    }

    mutating func readNumber() -> Token? {
        let start = self
        var digits = ""
        while let c = self.first, CharacterSet.decimalDigits.contains(c) || c == "." {
            digits.append(Character(self.removeFirst()))
        }
        if let double = Double(digits) {
            return Token.number(double)
        }
        self = start
        return nil
    }

    mutating func readString() -> Token? {
        guard first == "\"" else {
            return nil
        }
        let start = self
        self.removeFirst()
        var string = "", escaped = false
        while let scalar = self.popFirst() {
            switch scalar {
            case "\"" where !escaped:
                return Token.string(string)
            case "\\" where !escaped:
                escaped = true
            default:
                string.append(Character(scalar))
                escaped = false
            }
        }
        self = start
        return nil
    }

    mutating func readToken() -> Token? {
        self.skipWhitespace()
        return
            self.readOperator() ??
            self.readIdentifier() ??
            self.readNumber() ??
            self.readString()
    }
}
