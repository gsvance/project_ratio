// recipereaders.rs
// Code for parsing recipes from the recipe data file into Julia types

use std::collections::HashSet;
use std::fs;
use std::path::PathBuf;

use lazy_static::lazy_static;
use regex::Regex;

use crate::abbreviations::AbbreviationResolver;
use crate::databases::DataBase;
use crate::facilities::FacilityCategory;
use crate::products::{Product, ProductQuantity};
use crate::rates::Time;
use crate::rationalutilities::readrational;
use crate::recipes::Recipe;


//////////////////////////////////////////////
// Recipe Block Specification for Data File //
//////////////////////////////////////////////

// Any whitespace at the start or end of a line is stripped before parsing
// Recipe blocks are separated by one or more blank lines in the data file
// Any line beginning with a '#' is ignored (and not considered to be blank)

// A BNF-style description of the recipe block grammar:
//            recipe_block := outputs arrow_line inputs optional_nametag_line
//                 outputs := ingredient_line | ingredient_line outputs
//              arrow_line := "^" time_period "s" "(" facility_category ")"
//                  inputs := ingredient_line | ingredient_line inputs
//   optional_nametag_line := "" | "<>" recipe_name
//         ingredient_line := number product_name

lazy_static! {
	static ref COMMENTLINEREGEX: Regex = Regex::new(r"^\#.*$").unwrap();
	static ref ARROWLINEREGEX: Regex = Regex::new(r"^\^ *([0-9.]+) *s *\((.+)\)$").unwrap();
	static ref NAMETAGLINEREGEX: Regex = Regex::new(r"^<> *(.+)$").unwrap();
	static ref INGREDIENTLINEREGEX: Regex = Regex::new(r"^([0-9]+) +(.+)$").unwrap();
}

//////////////////////////////////////////////////
// Functions for Parsing the Entire Recipe File //
//////////////////////////////////////////////////

// This operates something like split(listoflines, isempty, keepempty = false)
// However, Base.split() only accepts sequences <: AbstractString as its input
// There really could exist a somewhat more general version of that function
// Why won't split just accept an arbitrary iterable and predicate function?
// And I can't seem to trick Julia into doing it by wrapping a Vector{String}
// It runs into all kinds of problems with AbstractChar and the SubString type
// This array-splitting problem also seems to be weirdly, totally un-Google-able
// Am I the only person who has ever wanted to split up an array like this???
fn splitonblanklines(listoflines: &Vec<String>) -> Vec<&[String]> {
	let mut listofblocks = Vec::new();
	let mut currentblockstart = None;
	
	for (i, line) in listoflines.iter().enumerate() {
		if line.is_empty() {
			if let Some(start) = currentblockstart {
				let block = &listoflines[start..i];
				listofblocks.push(block);
			}
			currentblockstart = None;
		} else if currentblockstart.is_none() {
			currentblockstart = Some(i);
		}
	}
	
	if let Some(start) = currentblockstart {
		let block = &listoflines[start..];
		listofblocks.push(block);
	}
	
	listofblocks
}

pub fn readrecipefile(datafilename: PathBuf, db: &DataBase) -> Vec<Vec<String>> {

	let mut filelines: Vec<String> = fs::read_to_string(datafilename)
	    .expect("should be able to open data file")
		.lines()
		.map(|line| line.trim())
		.filter(|&line| !COMMENTLINEREGEX.is_match(line))
		.map(|line| line.to_owned())
		.collect();
	
	let allproducts: HashSet<&str> = db.products
	    .iter().map(Product::name).collect();
	let mut productresolver = AbbreviationResolver::new(
		&allproducts
    );
	
	let allcategories: HashSet<&str> = db.facilitycategories
	    .iter().map(FacilityCategory::name).collect();
	let mut categoryresolver = AbbreviationResolver::new(
		&allcategories
	);
	
	for (i, line) in filelines.iter_mut().enumerate() {
		
		let m = INGREDIENTLINEREGEX.captures(line);
		if let Some(m) = m {
			let (_, [numberstring, productname]) = m.extract();
			if !allproducts.contains(productname) {
				let fullproductname = productresolver.call(productname);
				*line = format!("{} {}", numberstring, fullproductname);
			}
			continue;
		}

		let m = ARROWLINEREGEX.captures(line);
		if let Some(m) = m {
			let (_, [secondsstring, categoryname]) = m.extract();
			if !allcategories.contains(categoryname) {
				let fullcategoryname = categoryresolver.call(categoryname);
				*line = format!("^ {} s ({})", secondsstring, fullcategoryname);
			}
			continue;
		}
	}
	
	let recipeblocks = splitonblanklines(&filelines);
	recipeblocks.into_iter().map(Vec::from).collect()
}


///////////////////////////////////////////
// Functions for Parsing a Single Recipe //
///////////////////////////////////////////

fn parseingredient(recipeblock: &Vec<String>, i: usize) -> Option<ProductQuantity<i64>> {
	let line = match recipeblock.get(i) {
		Some(line) => line,
		None => return None,
	};

	match INGREDIENTLINEREGEX.captures(line) {
		Some(m) => {
			let (_, [numberstring, productname]) = m.extract();
			let quantity = numberstring.parse().unwrap();
			Some(ProductQuantity::with_productname(quantity, productname))
		},
		None => None,
	}
}

fn parsearrowline(recipeblock: &Vec<String>, i: usize) -> (Time, FacilityCategory) {
	let line = match recipeblock.get(i) {
		Some(line) => line,
		None => panic!("arrow line index out of bounds"),
	};

	match ARROWLINEREGEX.captures(line) {
		Some(m) => {
			let (_, [secondsstring, categoryname]) = m.extract();
			let t = Time::new(readrational(secondsstring));
			let fc = FacilityCategory::new(categoryname);
			(t, fc)
		},
		None => panic!("unable to parse arrow line: {:?}", line),
	}
}

fn parsenametagline(recipeblock: &Vec<String>, i: usize) -> Option<&str> {
	let line = match recipeblock.get(i) {
		Some(line) => line,
		None => return None,
	};

	if i + 1 != recipeblock.len() {
		panic!("started to parse nametag line before end of recipe");
	}

	match NAMETAGLINEREGEX.captures(line) {
		Some(m) => {
			let (_, [recipename]) = m.extract();
			Some(recipename)
		},
		None => panic!("unable to parse nametag line: {:?}", line),
	}
}

pub fn readrecipe(recipeblock: &Vec<String>) -> Recipe {
	let mut i = 0;
	
	let mut r_outputs = Vec::new();
	let mut ingredient = parseingredient(recipeblock, i);
	while let Some(quantity) = ingredient {
		r_outputs.push(quantity);
		i += 1;
		ingredient = parseingredient(recipeblock, i);
	}
	
	let (r_period, r_madein) = parsearrowline(recipeblock, i);
	i += 1;
	
	let mut r_inputs = Vec::new();
	let mut ingredient = parseingredient(recipeblock, i);
	while let Some(quantity) = ingredient {
		r_inputs.push(quantity);
		i += 1;
		ingredient = parseingredient(recipeblock, i);
	}
	
	let r_name = parsenametagline(recipeblock, i);
	
	Recipe::new(r_name.as_deref(), r_outputs, r_inputs, r_period, r_madein)
}
