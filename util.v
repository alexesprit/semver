module semver

/*
 * Private functions.
 */

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
