// factories.rs
// Data types for a DSP factory and the groups of producers that make it up

use std::collections::HashMap;
use std::fmt;

use num::rational::Rational64;
use num::traits::Zero;

use crate::facilities::Facility;
use crate::products::{Product, ProductQuantity};
use crate::rationalutilities::prettystring;
use crate::rates::Rate;
use crate::recipes::Recipe;


///////////////////////////////////////
// RecipeCrafter Type Implementation //
///////////////////////////////////////

// When playing DSP, the number of facilities built obviously must be an Int
// However, we live in theory land where everything is perfectly "at ratio"
// To translate this fantasy number back into the DSP world, use ceil(howmany)
#[derive(Debug, PartialEq, Eq)]
pub struct RecipeCrafter<'a> {
	recipe: Recipe,
	facility: Facility,
	howmany: Rational64,  // Int in DSP terms
	
	// TODO: proliferation info for recipe inputs
	// ::Proliferator
	// ::ProliferationMode
	
	rates: HashMap<&'a Product, Rate>,
}	

impl<'a> RecipeCrafter<'a> {
	pub fn new(recipe: Recipe, facility: Facility, howmany: Rational64) -> Self {
		if howmany <= Rational64::zero() {
			panic!("recipe producer should not have howmany <= 0");
		}
		Self {
			recipe,
			facility,
			howmany,
			rates: HashMap::new(),
		}
	}

	// This constructor takes a production rate and computes the value of howmany
	pub fn with_goal(recipe: Recipe, facility: Facility, goal: &ProductQuantity<Rate>) -> Self {
	
		let (p, rate) = (goal.product(), goal.quantity());
		let howmany = Rational64::new(1, 1);  // Temp value of 1
		let mut rc = Self::new(recipe, facility, howmany);
	
		match rc.rates().get(p) {
			Some(&r) if r > Rate::zero() => {
				let rateratio = rate / r;
				rc.howmany *= rateratio;
			},
			_ => panic!("given recipe does not produce goal product"),
		}
	
		// TODO: consider proliferation of the recipe crafter
	
		rc.computerates();
		rc
	}

	pub fn recipe(&self) -> &Recipe {
		&self.recipe
	}

	pub fn facility(&self) -> &Facility {
		&self.facility
	}
	
	pub fn howmany(&self) -> Rational64 {
		self.howmany
	}

	// Note: this function needs to be careful about not overwriting Dict entries
	// For example, X-Ray Cracking has Hydrogen inputs *and* outputs to account for
	// Use get!() here so the output rate will not be overwritten by the input rate
	fn computerates(&mut self) {
		self.rates.clear();
	
		for output in self.recipe().outputs() {
			let reciperate = output.quantity() / self.recipe().period();
			let totalrate = reciperate * self.facility().speed() * self.howmany();
			let accum = self.rates
			    .entry(output.product()).or_insert(Rate::zero());
			*accum += totalrate;
		}
	
		for input in self.recipe().inputs() {
			let reciperate = input.quantity() / self.recipe().period();
			let totalrate = reciperate * self.facility().speed() * self.howmany();
			let accum = self.rates
			    .entry(input.product()).or_insert(Rate::zero());
			*accum -= totalrate;
		}
	
		// TODO: proliferation would affect all these recipe rates
		// *and* it would consume proliferator product at a certain rate
	}

	pub fn rates(&mut self) -> &HashMap<&Product, Rate> {
		if self.rates.is_empty() {
			self.computerates();
		}
		&self.rates
	}
}

impl<'a> fmt::Display for RecipeCrafter<'a> {
	fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
		write!(
			f,
			"Group of {} {} crafting {}",
			prettystring(self.howmany()),
			self.facility().name(),
			self.recipe().name()
		)
	}
}


/////////////////////////////////
// Factory Type Implementation //
/////////////////////////////////

#[derive(Debug)]
pub struct Factory<'a> {
	goal: ProductQuantity<Rate>,
	crafters: Vec<RecipeCrafter<'a>>,
	
	// TODO: output proflieration info for primary product
	// ::Proliferator
	
	rates: HashMap<&'a Product, Rate>,
	ignoredrates: HashMap<&'a Product, bool>,  // If true, ignore negative rates
}	

impl<'a> Factory<'a> {
	pub fn new(goal: ProductQuantity<Rate>) -> Self {
		Self {
			goal,
			crafters: Vec::new(),
			rates: HashMap::new(),
			ignoredrates: HashMap::new(),
		}
	}

	pub fn goal(&self) -> &ProductQuantity<Rate> {
		&self.goal
	}

	pub fn crafters(&self) -> &Vec<RecipeCrafter> {
		&self.crafters
	}

	fn computerates(&mut self) {
		self.rates.clear();
	
		self.rates.insert(
			self.goal().product(),
			-self.goal().quantity()
		);

		for crafter in self.crafters() {
			for (product, &rate) in crafter.rates() {
				let accum = self.rates
				    .entry(product).or_insert(Rate::zero());
				*accum += rate;
			}
		}
	}

	pub fn rates(&mut self) -> &HashMap<&Product, Rate> {
		if self.rates.is_empty() {
			self.computerates();
		}
		&self.rates
	}

	pub fn isignored(&mut self, p: &Product) -> bool {
		match self.rates().get(p) {
			None => panic!("product must exist to check if ignored"),
			_ => *self.ignoredrates.entry(p).or_insert(false),
		}
	}

	// Negative rates are those which still need production added via crafters
	// Ignored products have no recipe or they were shot down by the user
	pub fn negativerates(&self) -> Vec<(&Product, Rate)> {
		self.rates()
		    .iter()
			.filter(|(product, &productrate)| {
				!self.isignored(product) && productrate < Rate::zero()
			})
			.map(|(&product, &productrate)| {
				(product, productrate)
			})
			.collect()
	}

	// Sometimes we need to know which crafters are producing a given product
	pub fn findcrafters(&self, p: &Product) -> Vec<&RecipeCrafter> {
		self.crafters()
		    .iter()
		    .filter(|crafter| {
			    crafter.rates().contains_key(p) && *(crafter.rates().get(p).unwrap()) > Rate::zero()
		    })
		    .collect()
	}
}

impl<'a> fmt::Display for Factory<'a> {
	fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
		let indent = " ".repeat(2);
		let mut io = String::new();

		io.push_str("Factory:\n");
		io.push_str(&indent);
		io.push_str("Goal: ");
		io.push_str(&self.goal().to_string());

		io.push_str("\n");
		io.push_str(&indent);
		io.push_str("Crafters (");
		io.push_str(&self.crafters().len().to_string());
		io.push_str("):");

		for crafter in self.crafters() {
			io.push_str("\n");
			io.push_str(&indent);
			io.push_str(&indent);
			io.push_str(&crafter.to_string())
		}

		if self.crafters().is_empty() {
			io.push_str("\n");
			io.push_str(&indent);
			io.push_str(&indent);
			io.push_str("(none)");
		}

		let inputs: Vec<(&Product, Rate)> = self
			.rates()
			.iter()
			.filter(|(product, &rate)| rate < Rate::zero())
			.map(|(&product, &rate)| (product, rate))
			.collect();

		io.push_str("\n");
		io.push_str(&indent);
		io.push_str("Inputs Required (");
		io.push_str(&inputs.len().to_string());
		io.push_str("):");

		for (product, productrate) in inputs.iter() {
			io.push_str("\n");
			io.push_str(&indent);
			io.push_str(&indent);
			let quantity = ProductQuantity::new(
				-(*productrate),
				*product.clone()
			);
			io.push_str(&quantity.to_string());
		}

		if inputs.is_empty() {
			io.push_str("\n");
			io.push_str(&indent);
			io.push_str(&indent);
			io.push_str("(none)");
		}

		let byproducts: Vec<(&Product, Rate)> = self
			.rates()
			.iter()
			.filter(|(product, &rate)| rate > Rate::zero())
			.map(|(product, rate)| (product.clone(), rate.clone()))
			.collect();

		io.push_str("\n");
		io.push_str(&indent);
		io.push_str("Byproducts (");
		io.push_str(&byproducts.len().to_string());
		io.push_str("):");

		for (product, productrate) in byproducts.iter() {
			io.push_str("\n");
			io.push_str(&indent);
			io.push_str(&indent);
			let quantity = ProductQuantity::new(
				*productrate,
				*product.clone()
			);
			io.push_str(&quantity.to_string());
		}

		if byproducts.is_empty() {
			io.push_str("\n");
			io.push_str(&indent);
			io.push_str(&indent);
			io.push_str("(none)");
		}

		write!(f, "{}", io)
	}
}


////////////////////////////////////
// Factory Manipulation Functions //
////////////////////////////////////

impl<'a> Factory<'a> {
	pub fn setignored(&mut self, p: &Product) {
		match self.rates().get_key_value(p) {
			None => panic!("product must exist to be set as ignored"),
			Some((&p, _)) => {
				self.ignoredrates.insert(p, true);
			},
		}
	}

	pub fn setallignored(&mut self) {
		for product in self.rates().keys() {
			self.ignoredrates.insert(product.clone(), true);
		}
	}

	pub fn connectcrafter(&mut self, rc: RecipeCrafter) {
		if self.crafters().contains(&rc) {
			panic!("cannot connect same crafter to a factory twice");
		}
		self.crafters.push(rc);
		self.computerates();
	}

	pub fn upgradecrafter(
		&mut self,
		mut rc: RecipeCrafter,
		productionincrease: ProductQuantity<Rate>
	) {
		
		let target = productionincrease.product();
		let delta_rate = productionincrease.quantity();
		
		if !self.crafters().contains(&rc) {
			panic!("crafter must be factory-connected to upgrade");
		}

		let rc_rates_target = rc.rates().get(target);
		if rc_rates_target.is_none() || *rc_rates_target.unwrap() <= Rate::zero() {
			panic!("upgrading crafter does not produce target product");
		}

		let rc_rates_target = rc_rates_target.unwrap();
		if *rc_rates_target + delta_rate <= Rate::zero() {
			panic!("final upgraded crafter rate must be positive");
		}
		
		let upgraderatio = (*rc_rates_target + delta_rate) / *rc_rates_target;
		
		rc.howmany *= upgraderatio;
		
		// TODO: consider how the proliferation of the crafter is to be upgraded
		
		rc.computerates();
		self.computerates();
	}
}
