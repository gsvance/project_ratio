mod rationalutilities;
mod userquestions;

mod rates;
mod facilities;
mod products;
mod recipes;
// mod proliferators;

mod databases;
mod abbreviations;
mod recipereaders;
mod dataloaders;

mod factories;
// mod algorithms;

pub fn add(left: usize, right: usize) -> usize {
    left + right
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_works() {
        let result = add(2, 2);
        assert_eq!(result, 4);
    }
}
