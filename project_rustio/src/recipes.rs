// recipes.rs
// A type representing DSP recipes including inputs, outputs, and time periods

use std::fmt;

use crate::facilities::FacilityCategory;
use crate::products::ProductQuantity;
use crate::rates::Time;


#[derive(Clone, PartialEq, Eq, Hash)]
pub struct Recipe {
	name: String,
	outputs: Vec<ProductQuantity<i64>>,
	inputs: Vec<ProductQuantity<i64>>,
	period: Time,
	madein: FacilityCategory,
}

impl Recipe {
	pub fn with_name(
		name: &str,
		outputs: Vec<ProductQuantity<i64>>,
		inputs: Vec<ProductQuantity<i64>>,
		period: Time,
		madein: FacilityCategory,
	) -> Self {
		let cleanedname = name.trim();
		if cleanedname.is_empty() {
			panic!("recipe name empty or all whitespace");
		}
		
		// At some point, I may want to allow empty input or output lists...
		// ...but for the time being, these checks exist to preserve my sanity
		if outputs.is_empty() {
			panic!("recipe output collection is empty");
		}
		if inputs.is_empty() {
			panic!("recipe input collection is empty");
		}
		
		// Let's enforce the invariant of making sure the tuples are sorted
		// The actual order doesn't deeply matter, thus the use of hash()
		// What we care about here is that the ordering will be *consistent*
		// This invariant is important for equality comparisons between recipes
		// Vectors passed into this constructor could have elements in any order
		// That order should not affect whether recipe instances compare equal
		let mut outputs = outputs;
		outputs.sort();
		let mut inputs = inputs;
		inputs.sort();
		
		Self { name: cleanedname.to_owned(), outputs, inputs, period, madein }
	}

	pub fn without_name(
		outputs: Vec<ProductQuantity<i64>>,
		inputs: Vec<ProductQuantity<i64>>,
		period: Time,
		madein: FacilityCategory,
	) -> Self {
		// Recipes with no special name are always named after their sole output
		let autoname = match (outputs.len(), outputs.first()) {
			(1, Some(output)) => output.name(),
			_ => panic!("autoname failure for recipe without name"),
		};
		
		Recipe::with_name(autoname, outputs, inputs, period, madein)
	}

	pub fn new(
		name: Option<&str>,
		outputs: Vec<ProductQuantity<i64>>,
		inputs: Vec<ProductQuantity<i64>>,
		period: Time,
		madein: FacilityCategory,
	) -> Self {
		match name {
			Some(name) => Self::with_name(name, outputs, inputs, period, madein),
			None => Self::without_name(outputs, inputs, period, madein),
		}
	}

	pub fn name(&self) -> &str {
		&self.name
	}

	pub fn outputs(&self) -> &Vec<ProductQuantity<i64>> {
		&self.outputs
	}

	pub fn inputs(&self) -> &Vec<ProductQuantity<i64>> {
		&self.inputs
	}

	pub fn period(&self) -> Time {
		self.period
	}

	pub fn category(&self) -> &FacilityCategory {
		&self.madein
	}
}

// Single line recipe printing
impl fmt::Debug for Recipe {
	fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
		let outputs: Vec<_> = self.outputs.iter()
			.map(|output| output.to_string()).collect();
		let inputs: Vec<_> = self.inputs.iter()
			.map(|input| input.to_string()).collect();
		write!(
			f,
			"{}: [{}] <<< {} ({}) <<< [{}]",
			self.name(),
			outputs.join(", "),
			self.period(),
			self.category(),
			inputs.join(", ")
		)
	}
}

// Multi-line recipe printing
impl fmt::Display for Recipe {
	fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
		let recipeindent = " ".repeat(2);
		let mut io = String::new();

		io.push_str(self.name());
		io.push_str(":\n");

		io.push_str(&recipeindent);
		io.push_str("[");
		let outputs: Vec<String> = self.outputs().iter()
		    .map(|output| output.to_string()).collect();
		io.push_str(&outputs.join(", "));
		io.push_str("]\n");
	
		io.push_str(&recipeindent);
		io.push_str(&recipeindent);
		io.push_str("^\n");
		io.push_str(&recipeindent);
		io.push_str(&recipeindent);
		io.push_str("^ ");

		io.push_str(&self.period().to_string());
		io.push_str(" (");
		io.push_str(&self.category().to_string());
		io.push_str(")");

		io.push_str("\n");
		io.push_str(&recipeindent);
		io.push_str(&recipeindent);
		io.push_str("^\n");
	
		io.push_str(&recipeindent);
		io.push_str("[");
		let inputs: Vec<String> = self.inputs().iter()
		    .map(|input| input.to_string()).collect();
		io.push_str(&inputs.join(", "));
		io.push_str("]");

		write!(f, "{}", io)
	}
}
