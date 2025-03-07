# Swift Scope and Module Import Solution

## Problem: "Cannot find type in scope" Errors

When working with Swift projects, you might encounter errors like:

```
Cannot find type 'UserRole' in scope
Cannot find type 'CollaborationInvite' in scope
```

These errors often occur when trying to use types defined in one file from another file within the same module.

## Root Cause

According to the [official Swift documentation on Access Control](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/accesscontrol/), the fundamental issue is that **Swift doesn't support importing types from the same module using import statements**. In a single-module app (which is what most iOS apps are), you can't use import statements to import files from the same module.

The Swift documentation states:

> A module is a single unit of code distribution — a framework or application that's built and shipped as a single unit and that can be imported by another module with Swift's `import` keyword.
>
> Each build target (such as an app bundle or framework) in Xcode is treated as a separate module in Swift.

And regarding source files:

> A source file is a single Swift source code file within a module (in effect, a single file within an app or framework). Although it's common to define individual types in separate source files, a single source file can contain definitions for multiple types, functions, and so on.

Common mistakes that lead to these errors:

1. Using `import` statements to reference types within the same module
2. Having duplicate definitions of the same type in multiple files
3. Using namespace-style approaches that don't align with Swift's module system
4. Trying to use relative imports like `import Models.UserTypes` within the same module

## Solution: Proper Swift Module Structure

### Step 1: Consolidate Type Definitions

Keep only one definition of each type in your project:

```swift
// UserTypes.swift - The single source of truth for user-related types
import Foundation

public enum UserRole: String, Codable, CaseIterable {
    case owner = "Owner"
    case editor = "Editor"
    case viewer = "Viewer"
}

public struct User: Identifiable, Codable, Equatable {
    // Properties and methods...
}

public struct CollaborationInvite: Identifiable, Codable {
    // Properties and methods...
    
    public enum InviteStatus: String, Codable {
        case pending = "Pending"
        case accepted = "Accepted"
        case declined = "Declined"
        case expired = "Expired"
    }
}
```

### Step 2: Use Appropriate Access Modifiers

According to the Swift documentation:

> All entities in your code (with a few specific exceptions) have a default access level of internal if you don't specify an explicit access level yourself. As a result, in many cases you don't need to specify an explicit access level in your code.

The available access levels in Swift are:

- `open`: Least restrictive; entities can be accessed and subclassed by code in the same module and by code in other modules that import the defining module.
- `public`: Entities can be accessed by code in the same module and by code in other modules that import the defining module, but they can only be subclassed within the defining module.
- `internal` (default): Entities can be accessed from any source file within their defining module, but not from outside the module.
- `fileprivate`: Restricts the use of an entity to its own defining source file.
- `private`: Restricts the use of an entity to the enclosing declaration and extensions of that declaration in the same file.

For a single-module app, `internal` is sufficient for most types. Use `public` if you plan to extract these types into a separate module later.

### Step 3: Remove Problematic Import Statements

Remove any import statements trying to import types from the same module:

```swift
// WRONG - Don't do this in a single-module app
import MyApp.Models.UserTypes

// RIGHT - No import needed for types in the same module
// Just use the types directly
let user = User(id: "123", name: "John")
```

### Step 4: Handle Backward Compatibility

If you're refactoring existing code, you might need to maintain backward compatibility. Create placeholder files that point to the new location:

```swift
// UserModels.swift (old file, now just a placeholder)
import Foundation

// This file is kept for backward compatibility
// The actual types are now defined in UserTypes.swift
```

### Step 5: For Multi-Module Projects

If you genuinely need to share code between multiple modules (e.g., between an app and its extension), create a proper Swift Package:

1. Create a new Swift Package (e.g., "MyAppModels")
2. Move shared types to this package
3. Add the package as a dependency to all targets that need it
4. Use proper import statements: `import MyAppModels`

## Common Pitfalls to Avoid

1. **Duplicate Type Definitions**: Having the same type defined in multiple files causes conflicts.

2. **Namespace-Style Imports**: Swift doesn't support Java-style namespaces like `import com.myapp.models`.

3. **Circular Dependencies**: Be careful not to create circular dependencies between files.

4. **Mixing Access Levels**: Be consistent with access levels across your codebase.

## Real-World Example: VinylVault App

In the VinylVault app, we encountered "Cannot find type in scope" errors because:

1. We had duplicate definitions of `User`, `UserRole`, and `CollaborationInvite` in both `UserModels.swift` and `UserTypes.swift`
2. We were trying to import these types using statements like `import VinylVault.Models.UserModels`

### Our Solution:

1. Consolidated all user type definitions in `UserTypes.swift` with `public` access modifiers
2. Simplified `UserModels.swift` to be just a backward compatibility file
3. Removed all import statements trying to import these types from other files
4. Made sure all files that needed these types could access them directly

This approach aligns with Swift's module system and resolved all the compilation errors.

## Swift Module System: Key Concepts

- A **module** is a distributable unit of code (app, framework, or package)
- Each Xcode target (application, framework, etc.) is its own module
- Types defined in a module are automatically available throughout that module without imports
- Use `import` only to access types from other modules
- Swift Package Manager creates separate modules for each package

## References

- [Swift Language Guide: Access Control](https://docs.swift.org/swift-book/LanguageGuide/AccessControl.html)
- [Swift Package Manager Documentation](https://www.swift.org/package-manager/)
- [Swift Evolution: SE-0033 Import as Member](https://github.com/apple/swift-evolution/blob/master/proposals/0033-import-objc-constants.md)
