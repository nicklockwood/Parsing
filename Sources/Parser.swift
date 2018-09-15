//
//  Parser.swift
//  Parsing
//
//  Created by Nick Lockwood on 03/09/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

import Foundation

// MARK: interface

public enum StatementType: Equatable {
    case declaration(name: String, value: Expression)
    case print(Expression)
}

public struct Statement: Equatable {
    let type: StatementType
    let range: Range<String.Index>
}

public indirect enum ExpressionType: Equatable {
    case number(Double)
    case string(String)
    case variable(String)
    case addition(lhs: Expression, rhs: Expression)
}

public struct Expression: Equatable {
    let type: ExpressionType
    let range: Range<String.Index>
}

public enum ParserError: Error, Equatable {
    case unexpectedToken(Token)
    case missingAssign(at: String.Index)
    case missingExpression(at: String.Index)
    case missingIdentifier(at: String.Index)
}

public func parse(_ input: String) throws -> [Statement] {
    var tokens = ArraySlice(tokenize(input))
    var statements: [Statement] = []
    while let statement = try tokens.readStatement() {
        statements.append(statement)
    }
    if let token = tokens.first {
        throw ParserError.unexpectedToken(token)
    }
    return statements
}

// MARK: implementation

private extension ArraySlice where Element == Token {

    mutating func readOperand() -> Expression? {
        let start = self
        let type: ExpressionType
        switch self.popFirst()?.type {
        case .identifier(let variable)?:
            type = .variable(variable)
        case .number(let double)?:
            type = .number(double)
        case .string(let string)?:
            type = .string(string)
        default:
            self = start
            return nil
        }
        return Expression(type: type, range: start.first!.range)
    }

    mutating func readExpression() throws -> Expression? {
        guard let lhs = readOperand() else {
            return nil
        }
        guard let `operator` = self.first, `operator`.type == .plus else {
            return lhs
        }
        self.removeFirst()
        guard let rhs = try readExpression() else {
            throw ParserError.missingExpression(at: `operator`.range.upperBound)
        }
        return Expression(
            type: .addition(lhs: lhs, rhs: rhs),
            range: lhs.range.lowerBound ..< rhs.range.upperBound
        )
    }

    mutating func readDeclaration() throws -> Statement? {
        guard let keyword = self.first, keyword.type == .let else {
            return nil
        }
        self.removeFirst()
        guard let identifier = self.first, case .identifier(let name) = identifier.type else {
            throw ParserError.missingIdentifier(at: keyword.range.upperBound)
        }
        self.removeFirst()
        guard let assign = self.first, assign.type == .assign else {
            throw ParserError.missingAssign(at: identifier.range.upperBound)
        }
        self.removeFirst()
        guard let value = try self.readExpression() else {
            throw ParserError.missingExpression(at: assign.range.upperBound)
        }
        return Statement(
            type: .declaration(name: name, value: value),
            range: keyword.range.lowerBound ..< value.range.upperBound
        )
    }

    mutating func readPrintStatement() throws -> Statement? {
        guard let keyword = self.first, keyword.type == .print else {
            return nil
        }
        self.removeFirst()
        guard let value = try self.readExpression() else {
            throw ParserError.missingExpression(at: keyword.range.upperBound)
        }
        return Statement(
            type: .print(value),
            range: keyword.range.lowerBound ..< value.range.upperBound
        )
    }

    mutating func readStatement() throws -> Statement? {
        return try self.readDeclaration() ?? self.readPrintStatement()
    }
}
