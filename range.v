module semver

/*
 * Private functions.
 */

const (
	ComparatorSep = ' '
	ComparatorSetSep = ' || '
	HyphenRangeSep = ' - '
	XRangeSymbols = 'Xx*'
)

enum Operator { gt lt ge le eq }

struct Comparator {
	ver Version
	op Operator
}

struct ComparatorSet {
	comparators []Comparator
}

struct Range {
	comparator_sets []ComparatorSet
}

fn (r Range) satisfies(ver Version) bool {
	mut final_result := false

	for set in r.comparator_sets {
		final_result = final_result || set.satisfies(ver)
	}

	return final_result
}

fn (set ComparatorSet) satisfies(ver Version) bool {
	for comp in set.comparators {
		if !comp.satisfies(ver) {
			return false
		}
	}

	return true
}

fn (c Comparator) satisfies(ver Version) bool {
	return match c.op {
		.gt {
			ver.gt(c.ver)
		}
		.lt {
			ver.lt(c.ver)
		}
		.ge {
			ver.ge(c.ver)
		}
		.le {
			ver.le(c.ver)
		}
		.eq {
			ver.eq(c.ver)
		}
		else {
			false
		}
	}
}

fn parse_range(input string) ?Range {
	raw_comparator_sets := input.split(ComparatorSetSep)
	mut comparator_sets := []ComparatorSet

	for raw_comp_set in raw_comparator_sets {
		s := if can_expand(raw_comp_set) {
			expand_comparator_set(raw_comp_set)
		} else {
			parse_comparator_set(raw_comp_set)
		} or {
			return error('Invalid comparator set: $raw_comp_set')
		}

		comparator_sets << s
	}

	return Range { comparator_sets }
}

fn parse_comparator_set(input string) ?ComparatorSet {
	raw_comparators := input.split(ComparatorSep)
	if raw_comparators.len > 2 {
		return error('Invalid format of comparator set')
	}

	mut comparators := []Comparator
	for raw_comp in raw_comparators {
		c := parse_comparator(raw_comp) or {
			return error('Invalid comparator: $raw_comp')
		}

		comparators << c
	}

	return ComparatorSet { comparators }
}

fn parse_comparator(input string) ?Comparator {
	mut op := Operator.eq
	mut raw_version := ''

	if input.starts_with('>=') {
		op = .ge
		raw_version = input[2..]
	} else if input.starts_with('<=') {
		op = .le
		raw_version = input[2..]
	} else if input.starts_with('>') {
		op = .gt
		raw_version = input[1..]
	} else if input.starts_with('<') {
		op = .lt
		raw_version = input[1..]
	} else if input.starts_with('=') {
		raw_version = input[1..]
	} else {
		raw_version = input
	}

	version := coerce_version(raw_version) or {
		return none
	}
	return Comparator { version, op }
}

fn parse_xrange(input string) ?Version {
	mut raw_ver := parse(input).complete()

	for typ in Versions {
		if raw_ver.raw_ints[typ].index_any(XRangeSymbols) == -1 {
			continue
		}

		match typ {
			Major {
				raw_ver.raw_ints[Major] = '0'
				raw_ver.raw_ints[Minor] = '0'
				raw_ver.raw_ints[Patch] = '0'
			}
			Minor {
				raw_ver.raw_ints[Minor] = '0'
				raw_ver.raw_ints[Patch] = '0'
			}
			Patch {
				raw_ver.raw_ints[Patch] = '0'
			}
			else {}
		}
	}

	if !raw_ver.is_valid() {
		return none
	}

	return raw_ver.to_version()
}

fn can_expand(input string) bool {
	return
		input[0] == `~` || input[0] == `^` ||
		input.contains(HyphenRangeSep) || input.index_any(XRangeSymbols) > -1
}

fn expand_comparator_set(input string) ?ComparatorSet {
	set := match input[0] {
		`~` {
			expand_tilda(input[1..])
		}
		`^` {
			expand_caret(input[1..])
		}
		else {
			if input.contains(HyphenRangeSep) {
				expand_hyphen(input)
			} else {
				expand_xrange(input)
			}
		}
	} or {
		return error('Invalid comparator set: $input')
	}

	return set
}

fn expand_tilda(raw_version string) ?ComparatorSet {
	min_ver := coerce_version(raw_version) or {
		return none
	}
	mut max_ver := min_ver

	if min_ver.minor == 0 && min_ver.patch == 0 {
		max_ver = min_ver.increment(.major)
	} else {
		max_ver = min_ver.increment(.minor)
	}

	return make_comparator_set_ge_lt(min_ver, max_ver)
}

fn expand_caret(raw_version string) ?ComparatorSet {
	min_ver := coerce_version(raw_version) or {
		return none
	}

	mut max_ver := min_ver

	if min_ver.major == 0 {
		max_ver = min_ver.increment(.minor)
	} else {
		max_ver = min_ver.increment(.major)
	}

	return make_comparator_set_ge_lt(min_ver, max_ver)
}

fn expand_hyphen(raw_range string) ?ComparatorSet {
	raw_versions := raw_range.split(HyphenRangeSep)
	if raw_versions.len != 2 {
		return none
	}

	min_ver := coerce_version(raw_versions[0]) or {
		return none
	}

	raw_max_ver := parse(raw_versions[1])
	if raw_max_ver.is_missing(Major) {
		return none
	}

	mut max_ver := raw_max_ver.coerce() or {
		return none
	}

	if raw_max_ver.is_missing(Minor) {
		max_ver = max_ver.increment(.minor)
		return make_comparator_set_ge_lt(min_ver, max_ver)
	}

	return make_comparator_set_ge_le(min_ver, max_ver)
}

fn expand_xrange(raw_range string) ?ComparatorSet {
	min_ver := parse_xrange(raw_range) or {
		return none
	}

	if min_ver.major == 0 {
		comparators := [
			Comparator { min_ver, Operator.ge },
		]

		return ComparatorSet { comparators }
	}

	mut max_ver := min_ver

	if min_ver.minor == 0 {
		max_ver = min_ver.increment(.major)
	} else {
		max_ver = min_ver.increment(.minor)
	}

	return make_comparator_set_ge_lt(min_ver, max_ver)
}

fn make_comparator_set_ge_lt(min, max Version) ComparatorSet {
	comparators := [
		Comparator { min, Operator.ge },
		Comparator { max, Operator.lt }
	]

	return ComparatorSet { comparators }
}

fn make_comparator_set_ge_le(min, max Version) ComparatorSet {
	comparators := [
		Comparator { min, Operator.ge },
		Comparator { max, Operator.le }
	]

	return ComparatorSet { comparators }
}
