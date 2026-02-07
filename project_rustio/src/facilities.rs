// facilities.rs
// Types for representing production buildings and building classes from DSP

use std::fmt;

use num::rational::Rational64;

use crate::rationalutilities::prettystring;


//////////////////////////////////////////
// FacilityCategory Type Implementation //
//////////////////////////////////////////

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct FacilityCategory {
	name: String,
}

impl FacilityCategory {
	pub fn new(name: &str) -> Self {
		let cleanedname = name.trim();
		if cleanedname.is_empty() {
			panic!("facility category name empty or all whitespace");
		}
		Self { name: cleanedname.to_owned() }
	}

	pub fn name(&self) -> &str {
		&self.name
	}
}

impl fmt::Display for FacilityCategory {
	fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
		write!(f, "{}", self.name())
	}
}


//////////////////////////////////
// Facility Type Implementation //
//////////////////////////////////

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct Facility {
	category: FacilityCategory,
	adjective: String,
	speed: Rational64,
}

impl Facility {
	pub fn new(
		category: FacilityCategory,
		adjective: String,
		speed: Rational64
	) -> Self {
		Self { category, adjective, speed }
	}

	pub fn with_categoryname(
		categoryname: &str,
		adjective: String,
		speed: Rational64
	) -> Self {
		let category = FacilityCategory::new(categoryname);
		Self { category, adjective, speed }
	}

	pub fn category(&self) -> &FacilityCategory {
		&self.category
	}

	pub fn categoryname(&self) -> &str {
		&self.category.name()
	}
	
	pub fn speed(&self) -> Rational64 {
		self.speed
	}

    pub fn name(&self) -> String {
		if self.adjective.is_empty() {
			format!("{}", self.category())
		} else {
			format!("{} {}", &self.adjective, self.category())
		}
	}
}

impl fmt::Display for Facility {
	fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
		write!(f, "{} ({}x)", self.name(), prettystring(self.speed()))
	}
}
