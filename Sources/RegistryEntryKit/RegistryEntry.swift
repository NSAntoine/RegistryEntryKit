//
//  RegistryEntry.swift
//
//
//  Created by Serena on 15/03/2023.
//

import Foundation

#if canImport(IOKit)
import IOKit
#else
#error("Cant import IOKit, if you are building with an IOKit-less SDK, please include it :)")
#endif

/// Describes an IOKit Registry Entry, holding properties as CF types.
public class RegistryEntry: CustomStringConvertible, Hashable {
    public static func == (lhs: RegistryEntry, rhs: RegistryEntry) -> Bool {
        return lhs.entry == rhs.entry
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(entry)
    }
    
    /// The entry identifier used by IOKit in `IORegistryEntry(...)` functions.
    public let entry: io_registry_entry_t
    
    /// The path of this entry, represented as an optional `String`
    public let path: String?
    
    /// Whether or not the instance should call `IOObjectRelease` on the entry
    /// upon destroying the instance. This is `true` by default
    public var releaseEntryUponDeinitilization: Bool = true
    
    /// The registry entry of the device NVRAM.
    public static var nvram: RegistryEntry {
        RegistryEntry(path: "IODeviceTree:/options")
    }
    
    /// The Root Registry Entry.
    public static var root: RegistryEntry {
        RegistryEntry(entry: IORegistryGetRootEntry(_suitableMainPort()))
    }
    
    private static func _suitableMainPort() -> mach_port_t {
        if #available(macOS 12, *) {
            return kIOMainPortDefault
        }
        
        return kIOMasterPortDefault // deprecated in macOS 12
    }
    
    /// Initializes a new RegistryEntry instance from an IOKit IORegistryEntry identifier.
    /// NOTE: This initializer does not check for whether or not the entry is valid, if you need to do so
    /// use the `isValid` property.
    public init(entry: io_registry_entry_t, path: String? = nil) {
        self.entry = entry
        if entry == IO_OBJECT_NULL {
            print("WARNING: entry given is NOT valid, if you used init(path:), please double check the path!")
        }
        
        self.path = path
    }
    
    /// Initializes a new Registry Entry object with the given path,
    /// ie, `IODeviceTree:/Options`.
    convenience public init(path: String) {
        self.init(entry: IORegistryEntryFromPath(Self._suitableMainPort(), path), path: path)
    }
    
    /// Returns all objects in the entry
    /// Key: The name of the object as a String
    /// Value: A ``RegistryObject`` case
    public func allObjects() throws -> [String: RegistryObject?] {
        let dict = UnsafeMutablePointer<Unmanaged<CFMutableDictionary>?>.allocate(capacity: 1)
        defer {
            dict.deallocate()
        }
        
        let status = IORegistryEntryCreateCFProperties(entry, dict, kCFAllocatorDefault, 0)
        guard status == KERN_SUCCESS else {
            throw Errors.failedToAcquireAllItems(reason: "IORegistryEntryCreateCFProperties returned error: \(String(cString: mach_error_string(status)))")
        }
        
        guard let swiftDict = dict.pointee?.takeUnretainedValue() as? [String: Any] else {
            throw Errors.failedToAcquireAllItems(reason: "Unable to get dictionary of all items")
        }
        
        var finalDict: [String: RegistryObject?] = [:]
        
        for (key, value) in swiftDict {
            finalDict[key] = RegistryObject(item: value)
        }
        
        return finalDict
    }
    
    /// Looksup the a property with a given name in the RegistryEntry and returns a ``RegistryObject``  of it
    public func object(named: String) -> RegistryObject? {
        guard let prop = IORegistryEntryCreateCFProperty(entry, named as CFString, kCFAllocatorDefault, 0)?.takeUnretainedValue() else {
            return nil
        }
        
        return RegistryObject(item: prop)
    }
    
    /// Equivalent to ``object(named:)``.
    public func property(named: String) -> RegistryObject? {
        return object(named: named)
    }
    
    public func set(_ newValue: RegistryObject?, forProperty propertyName: String) throws {
        let kernReturn = IORegistryEntrySetCFProperty(entry, propertyName as CFString, newValue?._underlyingValue)
        guard kernReturn == KERN_SUCCESS else {
            throw Errors.failedToSetNewValueForProperty(newValue: newValue,
                                                        propertyName: propertyName,
                                                        machError: kernReturn)
        }
    }
    
    public subscript(_ propertyName: String) -> RegistryObject? {
        get {
            return object(named: propertyName)
        }
        
        set {
            do {
                try set(newValue, forProperty: propertyName)
            } catch {
                print("We've got a problem, pablo")
                print("!!!!! ERROR: \(error) !!!!!")
            }
        }
    }
    
    /// All the possible subentries for the current entry.
    public func subentries() -> [RegistryEntry] {
        // all possible planes
        let planes = [kIOServicePlane,
                      kIOPowerPlane, kIODeviceTreePlane,
                      kIOAudioPlane, kIOFireWirePlane,
                      kIOUSBPlane]
        return planes.compactMap { plane in
            var iter: io_iterator_t = 0
            guard IORegistryEntryGetChildIterator(entry, plane, &iter) == KERN_SUCCESS else {
                return nil
            }
            
            while case let item = IOIteratorNext(iter), item != 0 {
                IOObjectRelease(iter)
                return RegistryEntry(entry: entry,
                                     path: IORegistryEntryCopyPath(entry, plane)?.takeUnretainedValue() as? String)
            }
            
            return nil
        }
    }
    
    /// Indicates whether or not the entry is valid.
    var isValid: Bool {
        return entry != IO_OBJECT_NULL
    }
    
    deinit {
        if releaseEntryUponDeinitilization {
            IOObjectRelease(entry)
        }
    }
    
    private enum Errors: Error, LocalizedError, CustomStringConvertible {
        case failedToAcquireAllItems(reason: String)
        case failedToSetNewValueForProperty(newValue: RegistryObject?, propertyName: String, machError: kern_return_t)
        
        var description: String {
            switch self {
            case .failedToAcquireAllItems(let reason):
                return "Failed to acquire all Registry Entry Items: \(reason)"
            case .failedToSetNewValueForProperty(let newValue, let propertyName, let machError):
                return "Failed to set \(newValue?.description ?? "nil") for property \(propertyName): \(String(cString: mach_error_string(machError)))"
            }
        }
        
        var errorDescription: String? {
            description
        }
    }
}

extension RegistryEntry {
    public var description: String {
        return "Registry: \(entry), Path: \(path ?? "Unknown")"
    }
}
