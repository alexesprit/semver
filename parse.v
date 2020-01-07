module semver

/*
 * Private structs and functions.
 */

struct RawVersion {
	raw_ints []string
	prerelease string
	metadata string
}

const (
	Major = 0
	Minor = 1
	Patch = 2

	Versions = [Major, Minor, Patch]
)

// TODO: Rewrite using regexps?
// /(\d+)\.(\d+)\.(\d+)(?:\-([0-9A-Za-z-.]+))?(?:\+([0-9A-Za-z-]+))?/

fn parse(input string) RawVersion {
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

	return RawVersion {
		raw_ints,
		prerelease,
		metadata
	}
}

fn (ver RawVersion) is_valid() bool {
	if ver.raw_ints.len != 3 {
		return false
	}

	return
		is_valid_number(ver.raw_ints[Major]) &&
		is_valid_number(ver.raw_ints[Minor]) &&
		is_valid_number(ver.raw_ints[Patch]) &&
		is_valid_string(ver.prerelease) &&
		is_valid_string(ver.metadata)
}

fn (ver RawVersion) is_missing(typ int) bool {
	return typ >= ver.raw_ints.len - 1
}

fn (raw_ver RawVersion) coerce() ?Version {
	ver := raw_ver.complete()

	if !is_valid_number(ver.raw_ints[Major]) {
		return error('Invalid major version: $ver.raw_ints[Major]')
	}

	return ver.to_version()
}

fn (raw_ver RawVersion) complete() RawVersion {
	mut raw_ints := raw_ver.raw_ints
	for raw_ints.len < 3 {
		raw_ints << '0'
	}

	return RawVersion { raw_ints, raw_ver.prerelease, raw_ver.metadata }
}

fn (raw_ver RawVersion) validate() ?Version {
	if !raw_ver.is_valid() {
		return none
	}

	return raw_ver.to_version()
}

fn (raw_ver RawVersion) to_version() Version {
	return Version {
		raw_ver.raw_ints[Major].int(),
		raw_ver.raw_ints[Minor].int(),
		raw_ver.raw_ints[Patch].int(),
		raw_ver.prerelease,
		raw_ver.metadata
	}
}
