import semver

struct TestVersion {
	raw string
	major int
	minor int
	patch int
	prerelease string
	metadata string
}

struct TestRange {
	raw_version string
	range_satisfied string
	range_unsatisfied string
}

const (
	versions_to_test = [
		TestVersion {
			'1.2.4',
			1, 2, 4, '', ''
		},
		TestVersion {
			'1.2.4-prerelease-1',
			1, 2, 4, 'prerelease-1', ''
		},
		TestVersion {
			'1.2.4+20191231',
			1, 2, 4, '', '20191231'
		},
		TestVersion {
			'1.2.4-prerelease-1+20191231',
			1, 2, 4, 'prerelease-1', '20191231'
		},
		TestVersion {
			'1.2.4+20191231-prerelease-1',
			1, 2, 4, '', '20191231-prerelease-1'
		}
	]

	ranges_to_test = [
		TestRange {
			'1.1.0',
			'>=1.0.0',
			'<1.1.0',
		},
		TestRange {
			'1.1.0',
			'>=1.0.0 <=1.1.0',
			'>=1.0.0 <1.1.0',
		},
		TestRange {
			'2.3.1',
			'>=1.0.0 <=1.1.0 || >2.0.0 <2.3.4',
			'>=1.0.0 <1.1.0',
		},
		TestRange {
			'2.3.1',
			'>=1.0.0 <=1.1.0 || >2.0.0 <2.3.4',
			'>=1.0.0 <1.1.0 || >4.0.0 <5.0.0',
		}
	]

	invalid_versions_to_test = [
		'a.b.c', '1.2', '1.2.3.4', '1.2.3-alpha@', '1.2.3+meta%'
	]
)

fn test_from() {
	for item in versions_to_test {
		ver := semver.from(item.raw) or {
			assert false
			return
		}

		assert ver.major == item.major
		assert ver.minor == item.minor
		assert ver.patch == item.patch
		assert ver.metadata == item.metadata
		assert ver.prerelease == item.prerelease
	}

	for ver in invalid_versions_to_test {
		semver.from(ver) or {
			assert true
			continue
		}

		assert false
	}
}

fn test_increment() {
	version1 := semver.Version { major: 1, minor: 2, patch: 3 }

	version1_inc := version1.increment(.major)
	assert version1_inc.major == 2
	assert version1_inc.minor == 0
	assert version1_inc.patch == 0

	version2_inc := version1.increment(.minor)
	assert version2_inc.major == 1
	assert version2_inc.minor == 3
	assert version2_inc.patch == 0

	version3_inc := version1.increment(.patch)
	assert version3_inc.major == 1
	assert version3_inc.minor == 2
	assert version3_inc.patch == 4
}

fn test_compare() {
	first := semver.Version { major: 1, minor: 0, patch: 0 }
	patch := semver.Version { major: 1, minor: 0, patch: 1 }
	minor := semver.Version { major: 1, minor: 2, patch: 3 }
	major := semver.Version { major: 2, minor: 0, patch: 0 }

	assert first.le(first)
	assert first.ge(first)
	assert !first.lt(first)
	assert !first.gt(first)

	assert patch.ge(first)
	assert first.le(patch)
	assert !first.ge(patch)
	assert !patch.le(first)

	assert patch.gt(first)
	assert first.lt(patch)
	assert !first.gt(patch)
	assert !patch.lt(first)

	assert minor.gt(patch)
	assert patch.lt(minor)
	assert !patch.gt(minor)
	assert !minor.lt(patch)

	assert major.gt(minor)
	assert minor.lt(major)
	assert !minor.gt(major)
	assert !major.lt(minor)
}

fn test_satisfies() {
	for item in ranges_to_test {
		ver := semver.from(item.raw_version) or {
			assert false
			return
		}

		assert ver.satisfies(item.range_satisfied)
		assert !ver.satisfies(item.range_unsatisfied)
	}
}
