# RegistryEntryKit

Minimal, basic wrapper around IORegistryEntry(...) functions from IOKit, to be used mostly in future projects :) 

## Obtaining Instances
The libary consists of a class, `RegistryEntry`, that represents an IOKit `IORegistryEntry`, There are a couple of ways to get a `RegistryEntry`, being:
## Registering one from an IOKit functions that returns a `io_registry_entry_t`
Example:
```swift
let registryId: io_registry_entry_t = IOSomeRandomFunction()
let registry = RegistryEntry(entry: registryId)
// use `registry`
```
### Registering one from a path
Example
```swift
let nvramRegistry = RegistryEntry(path: "IODeviceTree:/options")
// use `nvramRegistry`
```
### Using the given class properties
There are currently 2 class properties that represent Registry Entries:
- `root`: The root entry
- `nvram`: The NVRAM entry
Examples:
```swift
let rootEntry = RegistryEntry.root
// use `rootEntry`
```

## Using instances
After obtaining an instance, there are a couple of ways to use it, including:

### Getting the value of a specific key
Values of registry entry properties are returned as `RegistryObject` (see [RegistryObject.swift](https://github.com/SerenaKit/RegistryEntryKit/blob/main/Sources/RegistryEntryKit/RegistryObject.swift)), to get the value of a specific key, use `object(named:)`, or a subscript, ie:

```swift
// using object(named:)
let deviceBootArguments = RegistryEntry.nvram.object(named: "boot-args") 
// using the subscript
let deviceBootNonce = RegistryEntry.nvram["com.apple.System.boot-nonce"]
```

## Setting the value of a specific key
To set the value of a property, use the subscript to do, example:
```swift
try RegistryEntry.nvram["com.apple.System.boot-nonce"] = .string("0x11111111111")
```

(Note that this method may throw an error)

## Geting *all* property names and values
Use `allObjects()`, which returns a `[String: RegistryObject]`:
```swift
for (key, value) in try RegistryEntry.nvram.allObjects() {
  print(key, value)
}
```

## Looking up the subentries of the entry
Use `subentries()`

## Checking for the validity of an entry
Use the `isValid` property, Example:
```swift
print(RegistryEntry(path: "YourPath").isValid)
```
