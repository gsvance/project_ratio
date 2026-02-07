// databases.rs
// Database type for reading, storing, and supplying all forms of DSP game data

use std::collections::{HashMap, HashSet};
use std::io::{self, Write};

use crate::facilities::{FacilityCategory, Facility};
use crate::products::Product;
use crate::rates::{Rate, Time};
use crate::recipes::Recipe;


/////////////////////////////////////////
// DataBase Type and Inner Constructor //
/////////////////////////////////////////

#[derive(Debug)]
pub struct DataBase<'a> {
	
	pub facilitycategories: HashSet<FacilityCategory>,
	pub facilities: HashMap<String, Facility>,
	
	pub products: HashSet<Product>,
	
	pub recipes: HashMap<String, Recipe>,
	
	pub rates: HashMap<String, Rate>,
	pub times: HashMap<String, Time>,
	
	lookuptable_facilities: HashMap<&'a FacilityCategory, HashSet<&'a Facility>>,
	lookuptable_recipes: HashMap<&'a Product, HashSet<&'a Recipe>>,
}

impl<'a> DataBase<'a> {
	pub fn new() -> Self {
		Self {
			facilitycategories: HashSet::new(),
			facilities: HashMap::new(),
			products: HashSet::new(),
			recipes: HashMap::new(),
			rates: HashMap::new(),
			times: HashMap::new(),
			lookuptable_facilities: HashMap::new(),
			lookuptable_recipes: HashMap::new(),
		}
	}
}


/////////////////////////////////
// Lookup Table Initialization //
/////////////////////////////////

impl<'a> DataBase<'a> {
	fn maketable_facilities(&'a mut self) {
		for facility in self.facilities.values() {
			let facilityset = self.lookuptable_facilities
			    .entry(facility.category()).or_insert_with(HashSet::new);
			facilityset.insert(facility);
		}
	}

	fn maketable_recipes(&mut self) {
		for recipe in self.recipes.values() {
			for quantity in recipe.outputs() {
				let recipeset = self.lookuptable_recipes
				    .entry(quantity.product()).or_insert_with(HashSet::new);
				recipeset.insert(recipe);
			}
		}
	}

	pub fn maketables(&mut self) {
		print!("Making lookup tables for DataBase...");
		io::stdout().flush().expect("should be able to flush stdout");
	
		self.maketable_facilities();
		self.maketable_recipes();
	
		println!(" done!");
	}
}


//////////////////////////////
// DataBase Query Functions //
//////////////////////////////

impl<'a> DataBase<'a> {
	pub fn findfacilities_category(&mut self, category: &FacilityCategory) -> &HashSet<&Facility> {
		self.lookuptable_facilities.entry(category).or_insert_with(HashSet::new)
	}

	pub fn findfacilities_categoryname(&mut self, categoryname: &str) -> &HashSet<&Facility> {
		let category = FacilityCategory::new(categoryname);
		self.findfacilities_category(&category)
	}

	pub fn findfacilities_recipe(&mut self, recipe: &Recipe) -> &HashSet<&Facility> {
		self.findfacilities_category(recipe.category())
	}

	pub fn findrecipes_output(&mut self, recipeoutput: &Product) -> &HashSet<&Recipe> {
		self.lookuptable_recipes.entry(recipeoutput).or_insert_with(HashSet::new)
	}

	pub fn findrecipes_outputname(&mut self, recipeoutputname: &str) -> &HashSet<&Recipe> {
		let product = Product::new(recipeoutputname);
		self.findrecipes_output(&product)
	}
}
