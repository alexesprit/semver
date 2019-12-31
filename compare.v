module semver

/*
 * Private functions.
 */

fn compare_eq(v1, v2 Version) bool {
	return
		v1.major == v2.major &&
		v1.minor == v2.minor &&
		v1.patch == v2.patch &&
		v1.prerelease == v2.prerelease
}

fn compare_gt(v1, v2 Version) bool {
	if v1.major < v2.major {
		return false
	}

	if v1.major > v2.major {
		return true
	}

	if v1.minor < v2.minor {
		return false
	}

	if v1.minor > v2.minor {
		return true
	}

	return v1.patch > v2.patch
}

fn compare_lt(v1, v2 Version) bool {
	if v1.major > v2.major {
		return false
	}

	if v1.major < v2.major {
		return true
	}

	if v1.minor > v2.minor {
		return false
	}

	if v1.minor < v2.minor {
		return true
	}

	return v1.patch < v2.patch
}

fn compare_ge(v1, v2 Version) bool {
	if compare_eq(v1, v2) {
		return true
	}

	return compare_gt(v1, v2)
}

fn compare_le(v1, v2 Version) bool {
	if compare_eq(v1, v2) {
		return true
	}

	return compare_lt(v1, v2)
}

// TODO: Compare prerelease.
// fn compare_prereleases(a, b string) bool {
// 	return true
// }

/*

module semver

/*
 * Private functions.
 */

fn compare_gt(v1, v2 Version) bool {
	return compare(v1, v2, gt)
}

fn compare_lt(v1, v2 Version) bool {
	return compare(v1, v2, lt)
}

fn compare_ge(v1, v2 Version) bool {
	if v1.eq(v2) {
		return true
	}

	return compare(v1, v2, gt)
}

fn compare_le(v1, v2 Version) bool {
	if v1.eq(v2) {
		return true
	}

	return compare(v1, v2, lt)
}

fn compare(v1, v2 Version, func fn (int, int) bool) bool {
	if !func(v1.major, v2.major) {
		return false
	}

	if func(v1.major, v2.major) {
		return true
	}

	if !func(v1.minor, v2.minor) {
		return false
	}

	if func(v1.minor, v2.minor) {
		return true
	}

	println(func(v1.patch, v2.patch))

	return func(v1.patch, v2.patch)
}

fn gt(a, b int) bool {
	return a > b
}

fn lt(a, b int) bool {
	return a < b
}

// TODO: Compare prerelease.
// fn compare_prereleases(a, b string) bool {
// 	return true
// }

*/
