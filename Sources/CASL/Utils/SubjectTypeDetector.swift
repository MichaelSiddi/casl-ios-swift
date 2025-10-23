// SubjectTypeDetector.swift
// Subject type detection using protocols and Mirror API

import Foundation

/// Default subject type detector using protocol + Mirror hybrid approach
///
/// Detection strategy:
/// 1. Check if subject conforms to SubjectTypeProvider → use static subjectType
/// 2. Fall back to Mirror API to extract type name
/// 3. Cache results for performance
///
/// - Parameter subject: The subject instance to detect type from
/// - Returns: Subject type string for permission matching
public func defaultSubjectTypeDetector(_ subject: Any) -> String {
    // Strategy 1: Check SubjectTypeProvider protocol
    if let provider = subject as? SubjectTypeProvider {
        return type(of: provider).subjectType
    }

    // Strategy 2: Use Mirror to extract type name
    let mirror = Mirror(reflecting: subject)

    // Get the type name from the mirror's subject type
    let typeName = String(describing: mirror.subjectType)

    // Clean up the type name (remove module prefix if present)
    let cleanedName = typeName.components(separatedBy: ".").last ?? typeName

    return cleanedName
}

// MARK: - Type Name Cache (Optional Performance Optimization)

/// Cache for subject type names to avoid repeated Mirror operations
///
/// Note: This is an optional optimization. The Mirror API is fast enough
/// (~10-50ns) that caching may not be necessary for most use cases.
private actor SubjectTypeCache {
    private var cache: [ObjectIdentifier: String] = [:]

    func get(for type: Any.Type) -> String? {
        cache[ObjectIdentifier(type)]
    }

    func set(_ typeName: String, for type: Any.Type) {
        cache[ObjectIdentifier(type)] = typeName
    }
}

// Global cache instance
private let typeCache = SubjectTypeCache()

/// Cached subject type detector (uses internal cache for performance)
///
/// Use this instead of defaultSubjectTypeDetector if you're checking
/// the same types repeatedly and need maximum performance.
public func cachedSubjectTypeDetector(_ subject: Any) async -> String {
    let subjectType = type(of: subject)

    // Check cache first
    if let cached = await typeCache.get(for: subjectType) {
        return cached
    }

    // Detect and cache
    let typeName = defaultSubjectTypeDetector(subject)
    await typeCache.set(typeName, for: subjectType)

    return typeName
}
