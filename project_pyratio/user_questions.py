# user_questions.py
# Functions for acquiring a few types of terminal input from the user

from collections.abc import Collection
from typing import Any, Callable, TypeVar

from simple_term_menu import TerminalMenu  # doesn't work on windoze :(


T = TypeVar("T")

###############################################
# Ask User to Pick One Item from a Collection #
###############################################

# The null choice is the text label for choosing "none of these options"
# If the user selects the null choice or quits the menu, then return nothing
def get_user_choice(
    message: str,
    choices_collection: Collection[T],
    null_choice: str,
    *,
    sort_by: Callable[[T], Any] | None = None
) -> T | None:
    if len(choices_collection) == 0:
        return None

    ordered_choices = [choice for choice in choices_collection]
    if sort_by is not None:
        ordered_choices.sort(key=sort_by)

    strings = [str(choice) for choice in ordered_choices]
    strings.append(null_choice)

    menu = RadioMenu(strings, pagesize=20)
    print()
    index = request(message, menu)

    if index == -1 or index == len(strings) - 1:
        return None
    return ordered_choices[index]


###########################################
# Ask User to Answer a Yes or No Question #
###########################################

# Return a Bool indicating whether the user answered "yes" to the question
# If the user quits the menu, return the default value, which is usually "no"
def get_user_bool(question: str, default: bool = False) -> bool:
    strings = ["yes", "no"]

    menu = RadioMenu(strings)
    print()
    index = request(question, menu)

    return default if index == -1 else strings[index] == "yes"


################################################
# Ask User to Enter a Line of Text for Parsing #
################################################

# Ask the user to enter a line of text until it passes some given parse test
# Prompt with a message, then pass the input string to the parser function
# Repeat until the parser returns not nothing, then return whatever it gave
# By default, just return whatever the first string is that the user enters
def get_user_text(
    message: str,
    parser: Callable[[str], Any] = lambda x: x
) -> Any:
    parse_value = None

    while True:
        print()
        print(message, end="", flush=True)
        parse_value = parser(input())
        if parse_value is not None:
            break

    return parse_value
