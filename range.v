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
			set_result = set_result && comp.satisfy(ver)
		}

		final_result = final_result || set_result
	}

	return final_result
}

fn parse_range(input string) ?Range {
	raw_comparator_sets := input.split(ComparatorSetSep)
	mut comparator_sets := []ComparatorSet

	for raw_comp_set in raw_comparator_sets {
		s := parse_comparator_set(raw_comp_set) or {
			// FIXME
			return error('FIXME')
		}

		comparator_sets << s
	}

	return Range { comparator_sets }
}

fn parse_comparator_set(input string) ?ComparatorSet {
	raw_comparators := input.split(ComparatorSep)
	mut comparators := []Comparator

	for raw_comp in raw_comparators {
		c := parse_comparator(raw_comp) or {
			// FIXME
			return error('FIXME')
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

	version := from(raw_version) or {
		return error('Invalid comparator')
	}

	return Comparator { version, op }
}

pub fn (c Comparator) satisfy(v Version) bool {
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
