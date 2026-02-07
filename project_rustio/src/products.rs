// products.rs
// Foundational types for representing DSP recipe ingredients

use std::fmt;


/////////////////////////////////
// Product Type Implementation //
/////////////////////////////////

#[derive(Debug, Clone, PartialOrd, Ord, PartialEq, Eq, Hash)]
pub struct Product {
	name: String,
}

impl Product {
	pub fn new(name: &str) -> Self {
		let cleanedname = name.trim();
		if cleanedname.is_empty() {
			panic!("product name empty or all whitespace");
		}
		Self { name: cleanedname.to_owned() }
	}

	pub fn name(&self) -> &str {
		&self.name
	}
}

impl fmt::Display for Product {
	fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
		write!(f, "{}", self.name())
	}
}

/////////////////////////////////////////
// ProductQuantity Type Implementation //
/////////////////////////////////////////

// The quantity type T can be pretty much anything that "quantifies" the product
// Examples: an integer, a production rate... the only limit is my creativity!
#[derive(Debug, Clone, PartialOrd, Ord, PartialEq, Eq, Hash)]
pub struct ProductQuantity<T: Copy> {
	quantity: T,
	product: Product,
	// TODO: add proliferation status as part of this?
}

impl<T: Copy> ProductQuantity<T> {
	pub fn new(quantity: T, product: Product) -> Self {
		Self { quantity, product }
	}

	pub fn with_productname(quantity: T, productname: &str) -> Self {
		let product = Product::new(productname);
		Self { quantity, product }
	}

	pub fn quantity(&self) -> T {
		self.quantity
	}

	pub fn product(&self) -> &Product {
		&self.product
	}
	
	pub fn name(&self) -> &str {
		self.product.name()
	}
}

impl<T: Copy + fmt::Display> fmt::Display for ProductQuantity<T> {
	fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
		write!(f, "{} {}", self.quantity, self.product)
	}
}
