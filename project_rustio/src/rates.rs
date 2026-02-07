// rates.rs
// Simple types for representing measurements with dimensions of time or 1/time

// TODO: add functions for parsing times and rates from strings with units
// TODO: add functions for outputing times and rates with converted units

use std::{convert, fmt, ops::{self, DivAssign}};

use num::rational::Rational64;

use crate::rationalutilities::prettystring;


// I want to keep rates and times rational, so they should avoid float math
// This is "a rational" as defined in math class, i.e., the infinite set Q
trait IntegerOrRational {
	fn ration(self) -> Rational64;
}

impl IntegerOrRational for i64 {
	fn ration(self) -> Rational64 {
		Rational64::new(self, 1)
	}
}

impl IntegerOrRational for Rational64 {
	fn ration(self) -> Rational64 {
		self
	}
}


//////////////////////////////
// Time Type Implementation //
//////////////////////////////

#[derive(Debug, Clone, Copy, PartialOrd, Ord, PartialEq, Eq, Hash)]
pub struct Time {
	pub seconds: Rational64,
}

impl Time {
	pub fn new<T: IntegerOrRational>(seconds: T) -> Self {
		let seconds = seconds.ration();
		Self { seconds }
	}
}

impl fmt::Display for Time {
	fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
		write!(f, "{}s", prettystring(self.seconds))
	}
}

impl num::Zero for Time {
	fn zero() -> Self {
		Self::new(Rational64::zero())
	}

	fn is_zero(&self) -> bool {
		self.seconds.is_zero()
	}
}

impl ops::Neg for Time {
	type Output = Self;

	fn neg(self) -> Self::Output {
		Self::new(-self.seconds)
	}
}

impl ops::Add for Time {
	type Output = Self;

	fn add(self, rhs: Self) -> Self::Output {
		Self::new(self.seconds + rhs.seconds)
	}
}

impl ops::AddAssign for Time {
	fn add_assign(&mut self, rhs: Self) {
		self.seconds += rhs.seconds;
	}
}

impl ops::Sub for Time {
	type Output = Self;

	fn sub(self, rhs: Self) -> Self::Output {
		Self::new(self.seconds - rhs.seconds)
	}
}

impl ops::SubAssign for Time {
	fn sub_assign(&mut self, rhs: Self) {
		self.seconds -= rhs.seconds;
	}
}

impl<T: IntegerOrRational> ops::Mul<T> for Time {
	type Output = Time;

	fn mul(self, rhs: T) -> Self::Output {
		let rhs = rhs.ration();
		Time::new(self.seconds * rhs)
	}
}

impl ops::Mul<Time> for i64 {
	type Output = Time;

	fn mul(self, rhs: Time) -> Self::Output {
		let lhs = self.ration();
		Time::new(lhs * rhs.seconds)
	}
}

impl ops::Mul<Time> for Rational64 {
    type Output = Time;

	fn mul(self, rhs: Time) -> Self::Output {
		let lhs = self.ration();
		Time::new(lhs * rhs.seconds)
	}
}

impl<T: IntegerOrRational> ops::MulAssign<T> for Time {
	fn mul_assign(&mut self, rhs: T) {
		let rhs = rhs.ration();
		self.seconds *= rhs;
	}
}

impl<T: IntegerOrRational> ops::Div<T> for Time {
	type Output = Time;

	fn div(self, rhs: T) -> Self::Output {
		let rhs = rhs.ration();
		Time::new(self.seconds / rhs)
	}
}

impl ops::Div for Time {
	type Output = Rational64;

	fn div(self, rhs: Self) -> Self::Output {
		self.seconds / rhs.seconds
	}
}

impl<T: IntegerOrRational> DivAssign<T> for Time {
	fn div_assign(&mut self, rhs: T) {
		let rhs = rhs.ration();
		self.seconds /= rhs;
	}
}


//////////////////////////////
// Rate Type Implementation //
//////////////////////////////

#[derive(Debug, Clone, Copy, PartialOrd, Ord, PartialEq, Eq)]
pub struct Rate {
	pub persecond: Rational64,
}

impl Rate {
	pub fn new<T: IntegerOrRational>(persecond: T) -> Self {
		let persecond = persecond.ration();
		Self { persecond }
	}
}

impl fmt::Display for Rate {
	fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
		write!(f, "{}/s", prettystring(self.persecond))
	}
}

impl num::Zero for Rate {
	fn zero() -> Self {
		Self::new(Rational64::zero())
	}

	fn is_zero(&self) -> bool {
		self.persecond.is_zero()
	}
}

impl ops::Neg for Rate {
	type Output = Self;

	fn neg(self) -> Self::Output {
		Self::new(-self.persecond)
	}
}

impl ops::Add for Rate {
	type Output = Self;

	fn add(self, rhs: Self) -> Self::Output {
		Self::new(self.persecond + rhs.persecond)
	}
}

impl ops::AddAssign for Rate {
	fn add_assign(&mut self, rhs: Self) {
		self.persecond += rhs.persecond;
	}
}

impl ops::Sub for Rate {
	type Output = Self;

	fn sub(self, rhs: Self) -> Self::Output {
		Self::new(self.persecond - rhs.persecond)
	}
}

impl ops::SubAssign for Rate {
	fn sub_assign(&mut self, rhs: Self) {
		self.persecond -= rhs.persecond;
	}
}

impl<T: IntegerOrRational> ops::Mul<T> for Rate {
	type Output = Rate;

	fn mul(self, rhs: T) -> Self::Output {
		let rhs = rhs.ration();
		Rate::new(self.persecond * rhs)
	}
}

impl ops::Mul<Rate> for i64 {
	type Output = Rate;

	fn mul(self, rhs: Rate) -> Self::Output {
		let lhs = self.ration();
		Rate::new(lhs * rhs.persecond)
	}
}

impl ops::Mul<Rate> for Rational64 {
	type Output = Rate;

	fn mul(self, rhs: Rate) -> Self::Output {
		let lhs = self.ration();
		Rate::new(lhs * rhs.persecond)
	}
}

impl<T: IntegerOrRational> ops::MulAssign<T> for Rate {
	fn mul_assign(&mut self, rhs: T) {
		let rhs = rhs.ration();
		self.persecond *= rhs;
	}
}

impl<T: IntegerOrRational> ops::Div<T> for Rate {
	type Output = Rate;

	fn div(self, rhs: T) -> Self::Output {
		let rhs = rhs.ration();
		Rate::new(self.persecond / rhs)
	}
}

impl ops::Div for Rate {
	type Output = Rational64;

	fn div(self, rhs: Self) -> Self::Output {
		self.persecond / rhs.persecond
	}
}

impl<T: IntegerOrRational> ops::DivAssign<T> for Rate {
	fn div_assign(&mut self, rhs: T) {
		let rhs = rhs.ration();
		self.persecond /= rhs;
	}
}


/////////////////////////////////
// Time-Rate Type Interactions //
/////////////////////////////////

impl convert::From<Time> for Rate {
    fn from(value: Time) -> Self {
		Self::new(value.seconds.recip())
	}
}

impl convert::From<Rate> for Time {
	fn from(value: Rate) -> Self {
		Self::new(value.persecond.recip())
	}
}

impl ops::Div<Time> for i64 {
	type Output = Rate;

	fn div(self, rhs: Time) -> Self::Output {
		self * Rate::from(rhs)
	}
}

impl ops::Div<Time> for Rational64 {
	type Output = Rate;

	fn div(self, rhs: Time) -> Self::Output {
		self * Rate::from(rhs)
	}
}

impl ops::Div<Rate> for i64 {
	type Output = Time;

	fn div(self, rhs: Rate) -> Self::Output {
		self * Time::from(rhs)
	}
}

impl ops::Div<Rate> for Rational64 {
	type Output = Time;

	fn div(self, rhs: Rate) -> Self::Output {
		self * Time::from(rhs)
	}
}

impl ops::Mul<Rate> for Time {
	type Output = Rational64;

	fn mul(self, rhs: Rate) -> Self::Output {
		self.seconds * rhs.persecond
	}
}

impl ops::Mul<Time> for Rate {
	type Output = Rational64;

	fn mul(self, rhs: Time) -> Self::Output {
		self.persecond * rhs.seconds
	}
}
