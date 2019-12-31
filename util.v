module semver

/*
 * Private const and functions.
 */

const (
	Major = 0
	Minor = 1
	Patch = 2
	Prerelease = 3
	Metadata = 4
)

// TODO: Rewrite using regexps?
// /(\d+)\.(\d+)\.(\d+)(?:\-([0-9A-Za-z-.]+))?(?:\+([0-9A-Za-z-]+))?/

fn parse(input string) ?[]string {
	mut raw_version := input
	mut prerelease := ''
	mut metadata := ''

	plus_idx := raw_version.last_index('+') or { -1 }
	if plus_idx > 0 {
		metadata = raw_version[(plus_idx + 1)..]
		raw_version = raw_version[0..plus_idx]
	}

	hyphen_idx := raw_version.index('-') or { -1 }
	if hyphen_idx > 0 {
		prerelease = raw_version[(hyphen_idx + 1)..]
		raw_version = raw_version[0..hyphen_idx]
	}

	raw_ints := raw_version.split('.')
	if raw_ints.len != 3 {
		return none
	}

	return [raw_ints[0], raw_ints[1], raw_ints[2], prerelease, metadata]
}

fn validate(raw_data []string) ?Version {
	is_valid_version :=
		is_valid_number(raw_data[Major]) &&
		is_valid_number(raw_data[Minor]) &&
		is_valid_number(raw_data[Patch]) &&
		is_valid_string(raw_data[Prerelease]) &&
		is_valid_string(raw_data[Metadata])

	if !is_valid_version {
		return none
	}

	return Version {
		raw_data[Major].int(),
		raw_data[Minor].int(),
		raw_data[Patch].int(),
		raw_data[Prerelease],
		raw_data[Metadata]
	}
}

fn is_valid_string(input string) bool {
	for c in input {
		if !(c.is_letter() || c.is_digit() || c == `.` || c == `-`) {
			return false
		}
	}

	return true
}

fn is_valid_number(input string) bool {
	for c in input {
		if !c.is_digit() {
			return false
		}
	}

	return true
}
