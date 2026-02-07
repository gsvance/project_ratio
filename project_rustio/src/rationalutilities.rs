// rationalutilities.rs
// Utilities for picky methods of input and output involving rationals

use lazy_static::lazy_static;
use num::{FromPrimitive, rational::Rational64};
use regex::Regex;


///////////////////////////////
// Rational Output Utilities //
///////////////////////////////

const PRETTYDIGITS: i32 = 2;

pub fn prettystring(r: Rational64) -> String {
	match r.is_integer() {
		true => format!("{}", r.numer()),
		false => {
			let r = *r.numer() as f64 / *r.denom() as f64;
			let digits = 10_f64.powi(PRETTYDIGITS);
			let rounded = (r * digits).round() / digits;
			format!("{}", rounded)
		},
	}
}


//////////////////////////////
// Rational Input Utilities //
//////////////////////////////

lazy_static! {
	static ref RATIONALREGEX: Regex = Regex::new(
	    r"^ *([-+]?) *([0-9]+) */{1,2} *([0-9]+) *$"
    ).unwrap();
}

// This implementation with all the trial-and-error branching is a bit hacky
// It ought to work okay -- a better implementation would involve more regexes
// TODO: implement a better version of this function with all the picky details
fn tryreadrational(s: &str) -> Option<Rational64> {
	
	let m = RATIONALREGEX.captures(s);
	if let Some(m) = m {
		let numer = m.get(2).unwrap().as_str().parse().unwrap();
		let denom = m.get(3).unwrap().as_str().parse().unwrap();
		let r = Rational64::new(numer, denom);
		match m.get(1).unwrap().as_str() {
			"-" => return Some(-r),
			_ => return Some(r),
		}
	}
	
	let i: Option<i64> = s.parse().ok();
	if let Some(i) = i {
		return Some(Rational64::new(i, 1));
	}
	
	let f: Option<f64> = s.parse().ok();
	if let Some(f) = f {
		return Some(Rational64::from_f64(f).unwrap());
	}
	
	None
}

pub fn readrational(s: &str) -> Rational64 {
	let r = tryreadrational(s);
	if let None = r {
		panic!("string {:?} could not be read as a rational", s);
	}
	r.unwrap()
}
