// userquestions.rs
// Functions for acquiring a few types of terminal input from the user

use std::fmt;
use std::io;

use terminal_menu;


/////////////////////////////////////////////////
// Ask User to Pick One Item from a Collection //
/////////////////////////////////////////////////

// The null choice is the text label for choosing "none of these options"
// If the user selects the null choice or quits the menu, then return nothing
pub fn getuserchoice<T>(
	message: &str,
	choicescollection: impl Iterator<Item = T>,
	nullchoice: &str,
	sort: bool
) -> Option<T>
where
	T: fmt::Display + Ord + Clone
{	
	let choicescollection: Vec<_> = choicescollection.collect();
	if choicescollection.is_empty() {
		return None;
	}
	
	let mut orderedchoices = choicescollection;
	if sort {
		orderedchoices.sort();
	}
	
	let mut strings: Vec<String> = orderedchoices.iter().map(|c| c.to_string()).collect();
	strings.push(nullchoice.to_owned());
	let strings = strings;

	let mut items = Vec::new();
	items.push(terminal_menu::label(message));
	for string in strings.iter() {
		items.push(terminal_menu::button(string));
	}
	let items = items;
	let items_len = items.len();

	let menu = terminal_menu::menu(items);
	terminal_menu::run(&menu);

	if terminal_menu::mut_menu(&menu).canceled() {
		return None;
	}

	let mut index = terminal_menu::mut_menu(&menu).selected_item_index();
	index -= items_len - strings.len();

	if index == strings.len() - 1 {
		None
	} else {
		Some(orderedchoices[index].clone())
	}
}


/////////////////////////////////////////////
// Ask User to Answer a Yes or No Question //
/////////////////////////////////////////////

// Return a Bool indicating whether the user answered "yes" to the question
// If the user quits the menu, return the default value, which is usually "no"
pub fn getuserbool(question: &str, default: bool) -> bool {
	
	let menu = terminal_menu::menu(vec![
		terminal_menu::label(question),
		terminal_menu::button("yes"),
		terminal_menu::button("no"),
	]);
	terminal_menu::run(&menu);
	
	if terminal_menu::mut_menu(&menu).canceled() {
		return default;
	}

	let answer = terminal_menu::mut_menu(&menu).selected_item_name() == "yes";
	answer
}


//////////////////////////////////////////////////
// Ask User to Enter a Line of Text for Parsing //
//////////////////////////////////////////////////

// Ask the user to enter a line of text until it passes some given parse test
// Prompt with a message, then pass the input string to the parser function
// Repeat until the parser returns not nothing, then return whatever it gave
// By default, just return whatever the first string is that the user enters
pub fn getusertext<T>(message: &str, parser: impl Fn(&str) -> Option<T>) -> T {
	let mut parsevalue;
	
	loop {
		println!("");
		print!("{}", message);
		let mut line = String::new();
		io::stdin().read_line(&mut line).expect("should be able to read line");
		parsevalue = parser(&line);
		if parsevalue.is_some() {
			break;
		}
	}
	
	parsevalue.unwrap()
}
