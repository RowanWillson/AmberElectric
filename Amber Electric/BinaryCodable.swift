//
//  BinaryCodable.swift
//  OzRunways
//
//  Created by Rowan Willson on 7/9/19.
//  From https://github.com/mikeash/BinaryCoder
//

import Foundation
import CoreFoundation

/// A convenient shortcut for indicating something is both encodable and decodable.
typealias BinaryCodable = BinaryEncodable & BinaryDecodable


/// Implementations of BinaryCodable for built-in types.
extension Array: BinaryCodable where Element: Codable {
    func binaryEncode(to encoder: BinaryEncoder) throws {
        try encoder.encode(self.count)
        for element in self {
            try element.encode(to: encoder)
        }
    }
    
    init(fromBinary decoder: BinaryDecoder) throws {
        let count = try decoder.decode(Int.self)
        guard count < 1024*1024*50 else {  //less than 50MB
            throw BinaryDecoder.Error.prematureEndOfData
        }
        self.init()
        self.reserveCapacity(count)
        for _ in 0 ..< count {
            let decoded = try Element.self.init(from: decoder)
            self.append(decoded)
        }
    }
}


extension String: BinaryCodable {
    func binaryEncode(to encoder: BinaryEncoder) throws {
        try Array(self.utf8).binaryEncode(to: encoder)
    }
    
    init(fromBinary decoder: BinaryDecoder) throws {
        let utf8: [UInt8] = try Array(fromBinary: decoder)
        if let str = String(bytes: utf8, encoding: .utf8) {
            self = str
        } else {
            throw BinaryDecoder.Error.invalidUTF8(utf8)
        }
    }
}


extension Date: BinaryCodable {
    func binaryEncode(to encoder: BinaryEncoder) throws {
        try self.timeIntervalSinceReferenceDate.encode(to: encoder)
    }
    
    init(fromBinary decoder: BinaryDecoder) throws {
        if let timeSinceRefDate: TimeInterval = try? TimeInterval(from: decoder) {
            self = Date.init(timeIntervalSinceReferenceDate: timeSinceRefDate)
        } else {
            throw BinaryDecoder.Error.invalidTimeInterval
        }
    }
}

extension FixedWidthInteger where Self: BinaryEncodable {
    func binaryEncode(to encoder: BinaryEncoder) {
        encoder.appendBytes(of: self.bigEndian)
    }
}

extension FixedWidthInteger where Self: BinaryDecodable {
    init(fromBinary binaryDecoder: BinaryDecoder) throws {
        var v = Self.init()
        try binaryDecoder.read(into: &v)
        self.init(bigEndian: v)
    }
}


extension Int8: BinaryCodable {}
extension UInt8: BinaryCodable {}
extension Int16: BinaryCodable {}
extension UInt16: BinaryCodable {}
extension Int32: BinaryCodable {}
extension UInt32: BinaryCodable {}
extension Int64: BinaryCodable {}
extension UInt64: BinaryCodable {}

// Mark: Decoder

/// A protocol for types which can be decoded from binary.
protocol BinaryDecodable: Decodable {
    init(fromBinary decoder: BinaryDecoder) throws
}

/// Provide a default implementation which calls through to `Decodable`. This
/// allows `BinaryDecodable` to use the `Decodable` implementation generated by the
/// compiler.
extension BinaryDecodable {
    init(fromBinary decoder: BinaryDecoder) throws {
        try self.init(from: decoder)
    }
}

/// The actual binary decoder class.
class BinaryDecoder {
    fileprivate let data: [UInt8]
    fileprivate var cursor = 0
    
    init(data: [UInt8]) {
        self.data = data
    }
}

/// A convenience function for creating a decoder from some data and decoding it
/// into a value all in one shot.
extension BinaryDecoder {
    static func decode<T: BinaryDecodable>(_ type: T.Type, data: [UInt8]) throws -> T {
        return try BinaryDecoder(data: data).decode(T.self)
    }
}

/// The error type.
extension BinaryDecoder {
    /// All errors which `BinaryDecoder` itself can throw.
    enum Error: Swift.Error {
        /// The decoder hit the end of the data while the values it was decoding expected
        /// more.
        case prematureEndOfData
        
        /// Attempted to decode a type which is `Decodable`, but not `BinaryDecodable`. (We
        /// require `BinaryDecodable` because `BinaryDecoder` doesn't support full keyed
        /// coding functionality.)
        case typeNotConformingToBinaryDecodable(Decodable.Type)
        
        /// Attempted to decode a type which is not `Decodable`.
        case typeNotConformingToDecodable(Any.Type)
        
        /// Attempted to decode an `Int` which can't be represented. This happens in 32-bit
        /// code when the stored `Int` doesn't fit into 32 bits.
        case intOutOfRange(Int64)
        
        /// Attempted to decode a `UInt` which can't be represented. This happens in 32-bit
        /// code when the stored `UInt` doesn't fit into 32 bits.
        case uintOutOfRange(UInt64)
        
        /// Attempted to decode a `Bool` where the byte representing it was not a `1` or a
        /// `0`.
        case boolOutOfRange(UInt8)
        
        /// Attempted to decode a `String` but the encoded `String` data was not valid
        /// UTF-8.
        case invalidUTF8([UInt8])
        
        /// Attempted to decode a `Date` but the encoded `Date` data was not valid timestamp
        case invalidTimeInterval
    }
}

/// Methods for decoding various types.
extension BinaryDecoder {
    func decode(_ type: Bool.Type) throws -> Bool {
        switch try decode(UInt8.self) {
        case 0: return false
        case 1: return true
        case let x: throw Error.boolOutOfRange(x)
        }
    }
    
    func decode(_ type: Float.Type) throws -> Float {
        var swapped = CFSwappedFloat32()
        try read(into: &swapped)
        return CFConvertFloatSwappedToHost(swapped)
    }
    
    func decode(_ type: Double.Type) throws -> Double {
        var swapped = CFSwappedFloat64()
        try read(into: &swapped)
        return CFConvertDoubleSwappedToHost(swapped)
    }
    
    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        switch type {
        case is Int.Type:
            let v = try decode(Int64.self)
            if let v = Int(exactly: v) {
                return v as! T
            } else {
                throw Error.intOutOfRange(v)
            }
        case is UInt.Type:
            let v = try decode(UInt64.self)
            if let v = UInt(exactly: v) {
                return v as! T
            } else {
                throw Error.uintOutOfRange(v)
            }
            
        case is Float.Type:
            return try decode(Float.self) as! T
        case is Double.Type:
            return try decode(Double.self) as! T
            
        case is Bool.Type:
            return try decode(Bool.self) as! T
            
        case let binaryT as BinaryDecodable.Type:
            return try binaryT.init(fromBinary: self) as! T
            
        default:
            throw Error.typeNotConformingToBinaryDecodable(type)
        }
    }
    
    /// Read the appropriate number of raw bytes directly into the given value. No byte
    /// swapping or other postprocessing is done.
    func read<T>(into: inout T) throws {
        try read(MemoryLayout<T>.size, into: &into)
    }
}

/// Internal methods for decoding raw data.
private extension BinaryDecoder {
    /// Read the given number of bytes into the given pointer, advancing the cursor
    /// appropriately.
    func read(_ byteCount: Int, into: UnsafeMutableRawPointer) throws {
        if cursor + byteCount > data.count {
            throw Error.prematureEndOfData
        }
        
        data.withUnsafeBytes({
            let from = $0.baseAddress! + cursor
            memcpy(into, from, byteCount)
        })
        
        cursor += byteCount
    }
}

extension BinaryDecoder: Decoder {
    var codingPath: [CodingKey] { return [] }
    
    var userInfo: [CodingUserInfoKey : Any] { return [:] }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        return KeyedDecodingContainer(KeyedContainer<Key>(decoder: self))
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        return UnkeyedContainer(decoder: self)
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return UnkeyedContainer(decoder: self)
    }
    
    private struct KeyedContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
        var decoder: BinaryDecoder
        
        var codingPath: [CodingKey] { return [] }
        
        var allKeys: [Key] { return [] }
        
        func contains(_ key: Key) -> Bool {
            return true
        }
        
        func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
            return try decoder.decode(T.self)
        }
        
        func decodeNil(forKey key: Key) throws -> Bool {
            return true
        }
        
        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            return try decoder.container(keyedBy: type)
        }
        
        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
            return try decoder.unkeyedContainer()
        }
        
        func superDecoder() throws -> Decoder {
            return decoder
        }
        
        func superDecoder(forKey key: Key) throws -> Decoder {
            return decoder
        }
    }
    
    private struct UnkeyedContainer: UnkeyedDecodingContainer, SingleValueDecodingContainer {
        var decoder: BinaryDecoder
        
        var codingPath: [CodingKey] { return [] }
        
        var count: Int? { return nil }
        
        var currentIndex: Int { return 0 }
        
        var isAtEnd: Bool { return false }
        
        func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            return try decoder.decode(type)
        }
        
        func decodeNil() -> Bool {
            return true
        }
        
        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            return try decoder.container(keyedBy: type)
        }
        
        func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
            return self
        }
        
        func superDecoder() throws -> Decoder {
            return decoder
        }
    }
}

private extension FixedWidthInteger {
    static func from(binaryDecoder: BinaryDecoder) throws -> Self {
        var v = Self.init()
        try binaryDecoder.read(into: &v)
        return self.init(bigEndian: v)
    }
}

//Mark: Encoder

/// A protocol for types which can be encoded to binary.
protocol BinaryEncodable: Encodable {
    func binaryEncode(to encoder: BinaryEncoder) throws
}

/// Provide a default implementation which calls through to `Encodable`. This
/// allows `BinaryEncodable` to use the `Encodable` implementation generated by the
/// compiler.
extension BinaryEncodable {
    func binaryEncode(to encoder: BinaryEncoder) throws {
        try self.encode(to: encoder)
    }
}

/// The actual binary encoder class.
class BinaryEncoder {
    fileprivate var data: [UInt8] = []
    
    init() {}
}

/// A convenience function for creating an encoder, encoding a value, and
/// extracting the resulting data.
extension BinaryEncoder {
    static func encode(_ value: BinaryEncodable) throws -> [UInt8] {
        let encoder = BinaryEncoder()
        try value.binaryEncode(to: encoder)
        return encoder.data
    }
}

/// The error type.
extension BinaryEncoder {
    /// All errors which `BinaryEncoder` itself can throw.
    enum Error: Swift.Error {
        /// Attempted to encode a type which is `Encodable`, but not `BinaryEncodable`. (We
        /// require `BinaryEncodable` because `BinaryEncoder` doesn't support full keyed
        /// coding functionality.)
        case typeNotConformingToBinaryEncodable(Encodable.Type)
        
        /// Attempted to encode a type which is not `Encodable`.
        case typeNotConformingToEncodable(Any.Type)
    }
}

/// Methods for encoding various types.
extension BinaryEncoder {
    func encode(_ value: Bool) throws {
        try encode(value ? 1 as UInt8 : 0 as UInt8)
    }
    
    func encode(_ value: Float) {
        appendBytes(of: CFConvertFloatHostToSwapped(value))
    }
    
    func encode(_ value: Double) {
        appendBytes(of: CFConvertDoubleHostToSwapped(value))
    }
    
    func encode(_ encodable: Encodable) throws {
        switch encodable {
        case let v as Int:
            try encode(Int64(v))
        case let v as UInt:
            try encode(UInt64(v))
            
        case let v as Float:
            encode(v)
        case let v as Double:
            encode(v)
            
        case let v as Bool:
            try encode(v)
            
        case let binary as BinaryEncodable:
            try binary.binaryEncode(to: self)
            
        default:
            throw Error.typeNotConformingToBinaryEncodable(type(of: encodable))
        }
    }
    
    /// Append the raw bytes of the parameter to the encoder's data. No byte-swapping
    /// or other encoding is done.
    func appendBytes<T>(of: T) {
        var target = of
        withUnsafeBytes(of: &target) {
            data.append(contentsOf: $0)
        }
    }
}

extension BinaryEncoder: Encoder {
    var codingPath: [CodingKey] { return [] }
    
    var userInfo: [CodingUserInfoKey : Any] { return [:] }
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        return KeyedEncodingContainer(KeyedContainer<Key>(encoder: self))
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        return UnkeyedContainer(encoder: self)
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        return UnkeyedContainer(encoder: self)
    }
    
    private struct KeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
        var encoder: BinaryEncoder
        
        var codingPath: [CodingKey] { return [] }
        
        func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
            try encoder.encode(value)
        }
        
        func encodeNil(forKey key: Key) throws {}
        
        func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            return encoder.container(keyedBy: keyType)
        }
        
        func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            return encoder.unkeyedContainer()
        }
        
        func superEncoder() -> Encoder {
            return encoder
        }
        
        func superEncoder(forKey key: Key) -> Encoder {
            return encoder
        }
    }
    
    private struct UnkeyedContainer: UnkeyedEncodingContainer, SingleValueEncodingContainer {
        var encoder: BinaryEncoder
        
        var codingPath: [CodingKey] { return [] }
        
        var count: Int { return 0 }
        
        func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            return encoder.container(keyedBy: keyType)
        }
        
        func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            return self
        }
        
        func superEncoder() -> Encoder {
            return encoder
        }
        
        func encodeNil() throws {}
        
        func encode<T>(_ value: T) throws where T : Encodable {
            try encoder.encode(value)
        }
    }
}

