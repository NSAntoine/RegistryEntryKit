//
//  RegistryObject.swift
//  
//
//  Created by Serena on 15/03/2023.
// 

import Foundation

/// Represents an object that can be represented in the IORegistryEntry.
/// ...aka a CFPropertyList...
public enum RegistryObject: CustomStringConvertible {
    case string(String)
    case data(Data)
    case dictionary([AnyHashable: Any])
    case date(Date)
    case number(NSNumber)
    case array([Any])
    
    init?(item: Any) {
        if let item = item as? String {
            self = .string(item)
        } else if let item = item as? Data {
            self = .data(item)
        } else if let item = item as? [AnyHashable: Any] {
            self = .dictionary(item)
        } else if let arr = item as? [Any] {
            self = .array(arr)
        } else if let date = item as? Date {
            self = .date(date)
        } else if let number = item as? NSNumber {
            self = .number(number)
        } else {
            print("!!! RETURN NIL !!!")
            return nil
        }
    }
    
    public var description: String {
        switch self {
        case .string(let string):
            return string
        case .data(let data):
            return "Data (\(data.count) bytes)"
        case .dictionary(let dict):
            return "Dictionary:\n\(dict)"
        case .array(let arr):
            return "Array: \(arr as [Any])"
        case .date(let date):
            return "Date: \(date)"
        case .number(let number):
            return "Number: \(number)"
        }
    }
    
    internal var _underlyingValue: CFPropertyList {
        switch self {
        case .string(let string):
            return string as CFString
        case .data(let data):
            return data as CFData
        case .dictionary(let dictionary):
            return dictionary as CFDictionary
        case .array(let arr):
            return arr as CFArray
        case .date(let date):
            return date as CFDate
        case .number(let number):
            return number as CFNumber
        }
    }
}
