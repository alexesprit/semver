module semver

/*
 * Private functions.
 */

const (
	ComparatorSep = ' '
	ComparatorSetSep = ' || '
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
	sets := r.comparator_sets
	for set in sets {
		mut set_result := true
		comparators := set.comparators

		for comp in comparators {
			set_result = set_result && comp.satisfies(ver)
		}

		final_result = final_result || set_result
	}

	return final_result
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

fn (c Comparator) satisfies(v Version) bool {
	match c.op {
		.gt {
			return v.gt(c.ver)
		}
		.lt {
			return v.lt(c.ver)
		}
		.ge {
			return v.ge(c.ver)
		}
		.le {
			return v.le(c.ver)
		}
		.eq {
			return v.eq(c.ver)
		}
		else {}
	}

	return false
}

fn can_expand(input string) bool {
	return
		input.starts_with('~') ||
		input.starts_with('^')
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

	// hyphen_idx := input.index(HyphenRangeSep)
	// if (hyphen_idx > 0) {
	// 	return expand_hyphen(input)
	// }

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

	return make_comparator_set(min_ver, max_ver)
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

	return make_comparator_set(min_ver, max_ver)
}

fn make_comparator_set(min, max Version) ComparatorSet {
	comparators := [
		Comparator { min, Operator.ge },
		Comparator { max, Operator.lt }
	]

	return ComparatorSet { comparators }
}
