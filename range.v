module semver

/*
 * Private functions.
 */

const (
	ComparatorSep = ' '
	ComparatorSetSep = ' || '
	HyphenRangeSep = ' - '
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
		if can_expand(raw_comp_set) {
			s := expand_comparator_set(raw_comp_set) or {
				return error('Invalid comparator set: $raw_comp_set')
			}
			comparator_sets << s
		} else {
			s := parse_comparator_set(raw_comp_set) or {
				return error('Invalid comparator set: $raw_comp_set')
			}
			comparator_sets << s
		}
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
	} else {
		raw_version = input
	}

	version := coerce_version(raw_version) or {
		return none
	}
	return Comparator { version, op }
}

fn can_expand(input string) bool {
	return
		input[0] == `~` || input[0] == `^` || input.contains(HyphenRangeSep)
}

fn expand_comparator_set(input string) ?ComparatorSet {
	match input[0] {
		`~` {
			return expand_tilda(input[1..])
		}
		`^` {
			return expand_caret(input[1..])
		}
		else {}
	}

	if (input.contains(HyphenRangeSep)) {
		return expand_hyphen(input)
	}

	return none
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
	max_ver := coerce_version(raw_versions[1]) or {
		return none
	}

	println(1)

	return make_comparator_set_ge_le(min_ver, max_ver)
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
