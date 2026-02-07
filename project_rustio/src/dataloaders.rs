// dataloaders.rs
// Functions for loading DSP data types from (mainly TOML) files into Julia

use std::fs;
use std::io::{self, Write};
use std::path::PathBuf;

use lazy_static::lazy_static;
use num::FromPrimitive;
use num::rational::Rational64;
use toml;

use crate::databases::DataBase;
use crate::facilities::{FacilityCategory, Facility};
use crate::products::Product;
use crate::rates::{Time, Rate};
use crate::recipereaders::{readrecipe, readrecipefile};


//////////////////////////////////
// Locations of Game Data Files //
//////////////////////////////////

lazy_static! {
	static ref GAMEDATADIRECTORY: PathBuf = PathBuf::from("game_data");

	static ref FACILITIESFILENAME: PathBuf = GAMEDATADIRECTORY.join("facilities.toml");
	static ref PRODUCTSFILENAME: PathBuf = GAMEDATADIRECTORY.join("products.toml");
	static ref RECIPESFILENAME: PathBuf = GAMEDATADIRECTORY.join("recipes.dat");
	static ref RATESFILENAME: PathBuf = GAMEDATADIRECTORY.join("rates.toml");
}


///////////////////////////////////////
// Facilities Data Loading Functions //
///////////////////////////////////////

fn loaddata_facilitycategory(db: &mut DataBase, tomldata: &str) {
	let fc_name = tomldata;
	let fc = FacilityCategory::new(fc_name);
	
	if db.facilitycategories.contains(&fc) {
		panic!("duplicate facility category name: {:?}", fc.name());
	}
	db.facilitycategories.insert(fc);
}

fn loaddata_facility(db: &mut DataBase, tomldata: &toml::Table) {
	let f_categoryname = tomldata["category"].as_str().unwrap();
	let f_adjective = tomldata["adjective"].as_str().unwrap();
	let f_speed = match &tomldata["speed"] {
		&toml::Value::Integer(i) => Rational64::new(i, 1),
		&toml::Value::Float(f) => Rational64::from_f64(f).unwrap(),
		v => panic!("invalid facility speed in toml: {:?}", v),
	};
	
	let f = Facility::with_categoryname(
		f_categoryname,
		f_adjective.to_owned(),
		f_speed
	);
	let f_name = f.name();
	
	if db.facilities.contains_key(&f_name) {
		panic!("duplicate facility name: {:?}", &f_name);
	}
	if db.facilitycategories.contains(f.category()) {
		panic!("unknown facility category: {:?}", f.categoryname());
	}
	db.facilities.insert(f_name, f);
}

fn loadfacilitiesdata(db: &mut DataBase, tomlfilename: PathBuf) {
	
	let tomltable = fs::read_to_string(tomlfilename)
	    .expect("should be able to open toml file")
		.parse::<toml::Table>()
		.unwrap();
	
	for categorydata in tomltable["facility categories"].as_array().unwrap() {
		let categorydata = categorydata.as_str().unwrap();
		loaddata_facilitycategory(db, categorydata);
	}
	
	for facilitydata in tomltable["facilities"].as_array().unwrap() {
		let facilitydata = facilitydata.as_table().unwrap();
		loaddata_facility(db, facilitydata);
	}
}


/////////////////////////////////////
// Products Data Loading Functions //
/////////////////////////////////////

fn loaddata_product(db: &mut DataBase, tomldata: &str) {
	let p_name = tomldata;
	let p = Product::new(p_name);
	
	if db.products.contains(&p) {
		panic!("duplicate product name: {:?}", p.name());
	}
	db.products.insert(p);
}

fn loadproductsdata(db: &mut DataBase, tomlfilename: PathBuf) {
	
	let tomltable = fs::read_to_string(tomlfilename)
	    .expect("should be able to open toml file")
		.parse::<toml::Table>()
		.unwrap();
	
	for productdata in tomltable["products"].as_array().unwrap() {
		let productdata = productdata.as_str().unwrap();
		loaddata_product(db, productdata);
	}
}


////////////////////////////////////
// Recipes Data Loading Functions //
////////////////////////////////////

// Implementations of readrecipe() and readrecipefile() are in recipereaders.rs

fn loaddata_recipe(db: &mut DataBase, recipedata: &Vec<String>) {
	let recipeblock = recipedata;
	let r = readrecipe(recipeblock);
	
	if db.recipes.contains_key(r.name()) {
		panic!("duplicate recipe name: {:?}", r.name());
	}
	db.recipes.insert(r.name().to_owned(), r);
}

fn loadrecipesdata(db: &mut DataBase, datafilename: PathBuf) {
	
	// Pass in the database so it can be used to resolve abbreviations
	let recipetable = readrecipefile(datafilename, db);
	
	for recipedata in recipetable.iter() {
		loaddata_recipe(db, recipedata);
	}
}


//////////////////////////////////
// Rates Data Loading Functions //
//////////////////////////////////

fn loaddata_rate(db: &mut DataBase, tomldata: (&str, &toml::Value)) {
	let ratename = tomldata.0;
	let r_persecond = tomldata.1.as_integer().unwrap();
	let r = Rate::new(Rational64::new(r_persecond, 1));
	
	if db.rates.contains_key(ratename) {
		panic!("duplicate rate name: {:?}", ratename);
	}
	db.rates.insert(ratename.to_owned(), r);
}

fn loaddata_time(db: &mut DataBase, tomldata: (&str, &toml::Value)) {
	let timename = tomldata.0;
	let t_seconds = tomldata.1.as_integer().unwrap();
	let ratename = format!("/{}", timename);
	let t = Time::new(Rational64::new(t_seconds, 1));
	let r = Rate::from(t);
	
	if db.times.contains_key(timename) {
		panic!("duplicate time name: {:?}", timename);
	}
	if db.rates.contains_key(&ratename) {
		panic!("duplicate rate name was generated: {:?}", ratename);
	}
	db.times.insert(timename.to_owned(), t);
	db.rates.insert(ratename, r);
}

fn loadratesdata(db: &mut DataBase, tomlfilename: PathBuf) {
	
	let tomltable = fs::read_to_string(tomlfilename)
	    .expect("should be able to open toml file")
		.parse::<toml::Table>()
		.unwrap();
	
	for ratedata in tomltable["rates"].as_table().unwrap() {
		loaddata_rate(db, (ratedata.0, ratedata.1));
	}
	
	for timedata in tomltable["times"].as_table().unwrap() {
		loaddata_time(db, (timedata.0, timedata.1));
	}
}


/////////////////////////////////////////
// Top-Level DataBase Loading Function //
/////////////////////////////////////////

pub fn loaddatabase(db: &mut DataBase) {
	
	print!("Loading contents of DataBase from files...");
	io::stdout().flush().expect("should be able to flush stdout");
	
	loadfacilitiesdata(db, FACILITIESFILENAME.to_path_buf());
	loadproductsdata(db, PRODUCTSFILENAME.to_path_buf());
	loadrecipesdata(db, RECIPESFILENAME.to_path_buf());
	loadratesdata(db, RATESFILENAME.to_path_buf());
	
	println!(" done!");
}
