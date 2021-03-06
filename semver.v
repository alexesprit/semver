module semver

// Structure representing version in semver format.
pub struct Version {
pub:
	major      int
	minor      int
	patch      int
	prerelease string
	metadata   string
}

// Enum representing type of version increment.
pub enum Increment {
	major
	minor
	patch
}

// from returns Version structure parsed from input string.
pub fn from(input string) ?Version {
	if input.len == 0 {
		return error('Empty input')
	}
	raw_version := parse(input)
	version := raw_version.validate() or {
		return error('Invalid version format')
	}
	return version
}

// build returns Version structure with given major, minor and patch versions.
pub fn build(major int, minor int, patch int) Version {
	// TODO Check if versions are greater than zero.
	return Version{major, minor, patch, '', ''}
}

// increment returns Version structure with incremented values.
pub fn (ver Version) increment(typ Increment) Version {
	return increment_version(ver, typ)
}

// satisfies checks if the current version satisfies a given input range.
pub fn (ver Version) satisfies(input string) bool {
	return version_satisfies(ver, input)
}

// eq checks if the version equals a given input version.
pub fn (v1 Version) eq(v2 Version) bool {
	return compare_eq(v1, v2)
}

// eq checks if the version is greater than a given input version.
pub fn (v1 Version) gt(v2 Version) bool {
	return compare_gt(v1, v2)
}

// eq checks if the version is less than a given input version.
pub fn (v1 Version) lt(v2 Version) bool {
	return compare_lt(v1, v2)
}

// eq checks if the version is greater or equal than a given input version.
pub fn (v1 Version) ge(v2 Version) bool {
	return compare_ge(v1, v2)
}

// eq checks if the version is less or equal than a given input version.
pub fn (v1 Version) le(v2 Version) bool {
	return compare_le(v1, v2)
}

// coerce coerces a given string to a semver if it's possible.
pub fn coerce(input string) ?Version {
	ver := coerce_version(input) or {
		return error('Invalid version: $input')
	}
	return ver
}

// is_valid checks if a given string is a valid semver.
pub fn is_valid(input string) bool {
	return is_version_valid(input)
}
