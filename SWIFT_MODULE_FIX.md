# Swift Module Import Fix

## Current Problem

We're still encountering compilation errors:

```
Cannot find type 'UserRole' in scope
Cannot find type 'CollaborationInvite' in scope
```

Our previous approaches haven't worked:
1. Using `@_exported import` statements
2. Creating a separate UserModels.swift file with public access modifiers
3. Attempting to import with relative paths

## Root Cause Analysis

The fundamental issue is that Swift doesn't support importing types from the same module using import statements. In a single-module app (which is what most iOS apps are), you can't import files from the same module.

## New Approach: Swift Module Structure

### Option 1: Move User Types to Global Scope

1. **Simplify the structure**: Instead of trying to import types, we should ensure they're available globally.

2. **Implementation steps**:
   - Keep only one copy of the User, UserRole, and CollaborationInvite types
   - Place them in a file that's included in the main target
   - Remove all import statements trying to import these types
   - Ensure the types are accessible (public or internal)

### Option 2: Create a Proper Swift Package

1. **Create a separate module**: If we want proper imports, we need to create a separate Swift Package.

2. **Implementation steps**:
   - Create a new Swift Package called "VinylVaultModels"
   - Move the User, UserRole, and CollaborationInvite types to this package
   - Add the package as a dependency to the main app
   - Import the package properly in files that need these types

## Recommended Solution: Option 1

For simplicity and quick resolution, Option 1 is recommended:

1. Keep only one definition of User, UserRole, and CollaborationInvite in UserModels.swift
2. Delete the duplicate definitions in User.swift
3. Remove all import statements trying to import these types
4. Make sure the types have the right access level (internal is sufficient for a single-module app)

## Implementation Plan

1. **Consolidate model definitions**:
   - Keep UserModels.swift as the single source of truth
   - Remove User.swift or make it import from UserModels.swift

2. **Fix access levels**:
   - Change `public` to `internal` (or remove access modifiers) in UserModels.swift
   - In Swift, `internal` is the default access level and allows access within the same module

3. **Remove problematic imports**:
   - Remove all import statements trying to import User, UserRole, or CollaborationInvite
   - These types will be available throughout the app without imports

4. **Update project settings**:
   - Ensure UserModels.swift is included in the main target
   - Check the "Target Membership" in Xcode file inspector

This approach aligns with how Swift modules work and should resolve the compilation errors.
