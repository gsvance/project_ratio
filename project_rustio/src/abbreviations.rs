// abbreviations.rs
// This file defines "abbreviations" and tells Julia how to interpret them

use std::collections::{HashMap, HashSet};

use regex::Regex;


/////////////////////////////////
// Abbreviation Implementation //
/////////////////////////////////

// Abbreviation Standard:
// Construct an abbreviation of a string by deleting all characters that are not
// uppercase letters. To get around conflicts when two strings would produce the
// same sequence of uppercase letters, I may optionally choose to NOT delete one
// or more lowercase letters in the string. The remaining letters must always
// appear in the same order as in the original string. An empty string is not a
// valid abbreviation. The optional inclusion of arbitrarily chosen lowercase
// letters means that I cannot write a function to *generate* abbreviations,
// but that's okay. The code doesn't need to produce abbreviations, it just
// needs to be able to unambiguously interpret the ones I invent so that the
// recipes file can be a little less verbose.

#[derive(Debug)]
pub struct Abbreviation<'a> {
	st: &'a str,
	re: Regex,
}

impl<'a> Abbreviation<'a> {
	pub fn new(st: &'a str) -> Self {
		if st.is_empty() {
			panic!("empty abbreviation string");
		}
		if !st.chars().all(char::is_alphabetic) {
			panic!("non-alphabetic abbreviation string: {:?}", st);
		}

		let noncapitals = r"[^A-Z]*";  // Zero or more deletable characters in a row
		let mut re = String::new();
		re.push_str("^");
		re.push_str(noncapitals);
		for ch in st.chars() {
			re.push(ch);
			re.push_str(noncapitals);
		}
		re.push_str("$");

		Self { st, re: Regex::new(&re).unwrap() }
	}

	pub fn abbreviates(&self, longstring: &str) -> bool {
		self.re.is_match(longstring)
	}

	pub fn st(&'a self) -> &'a str {
		self.st
	}
}


/////////////////////////////////////////
// AbbreviationResolver Implementation //
/////////////////////////////////////////

pub struct AbbreviationResolver<'a> {
	stringcollection: &'a HashSet<&'a str>,
	lookuptable: HashMap<&'a str, &'a str>,
}

impl<'a> AbbreviationResolver<'a> {
	pub fn new(stringcollection: &'a HashSet<&'a str>) -> Self {
		let lookuptable = HashMap::new();
		Self { stringcollection, lookuptable }
	}

    fn resolveabbreviation(&'a self, abbrev: &Abbreviation) -> &'a str {
		let mut possiblematches = Vec::new();
		for &longstring in self.stringcollection {
			if abbrev.abbreviates(longstring) {
				possiblematches.push(longstring);
			}
		}
	
		match possiblematches.len() {
			0 => {
				panic!("found no strings matching abbreviation: {:?}", abbrev.st());
			},
			1 => {
				possiblematches.first().unwrap()
			},
			_ => {
				panic!(
					"too many strings match abbreviation: {:?} => {:?}",
					abbrev.st(),
					possiblematches
				);
			},
		}
	}

	pub fn call(&'a mut self, abbrev_str: &str) -> &'a str {
		self.lookuptable
		    .entry(abbrev_str)
			.or_insert_with_key(|&key| {
				let abbrev = Abbreviation::new(abbrev_str);
				self.resolveabbreviation(&abbrev)
			})
	}
}
