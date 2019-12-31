/*
 * Documentation: https://docs.npmjs.com/misc/semver
 */

module semver

/*
 * Structures.
 */

// Structure representing version in semver format.
pub struct Version {
pub:
	major int
	minor int
	patch int
	prerelease string = ''
	metadata string = ''
}

// Enum representing type of version increment.
pub enum Increment {
	major minor patch
}

/*
 * Constructor.
 */

// from returns Version structure parsed from input string.
pub fn from(input string) ?Version {
	if (input.len == 0) {
		return error('Empty input')
	}

	raw_version := parse(input) or {
		return error('Invalid version format')
	}
	version := validate(raw_version) or {
		return error('Invalid version format')
	}
	return version
}

/*
 * Transformation.
 */

// increment returns Version structure with incremented values.
pub fn (ver Version) increment(typ Increment) Version {
	mut major := ver.major
	mut minor := ver.minor
	mut patch := ver.patch

	match typ {
		.major {
			major++
			minor = 0
			patch = 0
		}
		.minor {
			minor++
			patch = 0
		}
		.patch {
			patch++
		}
		else {}
	}

	return Version { major, minor, patch, ver.prerelease, ver.metadata }
}

/*
 * Comparison.
 */

pub fn (ver Version) satisfies(input string) bool {
	range := parse_range(input) or {
		return false
	}

	return range.satisfies(ver)
}

pub fn (v1 Version) eq(v2 Version) bool {
	return
		v1.major == v2.major &&
		v1.minor == v2.minor &&
		v1.patch == v2.patch &&
		v1.prerelease == v2.prerelease
}

pub fn (v1 Version) gt(v2 Version) bool {
	return compare_gt(v1, v2)
}

pub fn (v1 Version) lt(v2 Version) bool {
	return compare_lt(v1, v2)
}

pub fn (v1 Version) ge(v2 Version) bool {
	return compare_ge(v1, v2)
}

pub fn (v1 Version) le(v2 Version) bool {
	return compare_le(v1, v2)
}
