# recipe_readers.py
# Code for parsing recipes from the recipe data file into Python types

from pathlib import Path
import re

from abbreviations import AbbreviationResolver
from databases import DataBase
from facilities import FacilityCategory
from products import ProductQuantity
from rates import Time
from rational_utilities import read_rational
from recipes import Recipe


############################################
# Recipe Block Specification for Data File #
############################################

# Any whitespace at the start or end of a line is stripped before parsing
# Recipe blocks are separated by one or more blank lines in the data file
# Any line beginning with a '#' is ignored (and not considered to be blank)

# A BNF-style description of the recipe block grammar:
#            recipe_block := outputs arrow_line inputs optional_nametag_line
#                 outputs := ingredient_line | ingredient_line outputs
#              arrow_line := "^" time_period "s" "(" facility_category ")"
#                  inputs := ingredient_line | ingredient_line inputs
#   optional_nametag_line := "" | "<>" recipe_name
#         ingredient_line := number product_name

COMMENT_LINE_REGEX: re.Pattern[str] = re.compile(r"^\#.*$")
ARROW_LINE_REGEX: re.Pattern[str] = re.compile(r"^\^ *([0-9.]+) *s *\((.+)\)$")
NAMETAG_LINE_REGEX: re.Pattern[str] = re.compile(r"^<> *(.+)$")
INGREDIENT_LINE_REGEX: re.Pattern[str] = re.compile(r"^([0-9]+) +(.+)$")


################################################
# Functions for Parsing the Entire Recipe File #
################################################

# This operates something like split(listoflines, isempty, keepempty = false)
# However, Base.split() only accepts sequences <: AbstractString as its input
# There really could exist a somewhat more general version of that function
# Why won't split just accept an arbitrary iterable and predicate function?
# And I can't seem to trick Julia into doing it by wrapping a Vector{String}
# It runs into all kinds of problems with AbstractChar and the SubString type
# This array-splitting problem also seems to be weirdly, totally un-Google-able
# Am I the only person who has ever wanted to split up an array like this???
def _split_on_blank_lines(list_of_lines: list[str]) -> list[list[str]]:
    list_of_blocks: list[list[str]] = []
    current_block_start: int | None = None

    for i, line in enumerate(list_of_lines):
        if line == "":
            if current_block_start is not None:
                block = list_of_lines[current_block_start:i]
                list_of_blocks.append(block)
            current_block_start = None
        elif current_block_start is None:
            current_block_start = i

    if current_block_start is not None:
        block = list_of_lines[current_block_start:]
        list_of_blocks.append(block)

    return list_of_blocks


def read_recipe_file(data_file_name: Path, db: DataBase) -> list[list[str]]:
    with open(data_file_name, "r", encoding="utf-8") as f:
        file_lines = map(str.strip, f.readlines())
    file_lines = list(filter(
        lambda line: re.match(COMMENT_LINE_REGEX, line) is None, file_lines
    ))

    all_products = set(p.name for p in db.products)
    product_resolver = AbbreviationResolver(all_products)

    all_categories = set(fc.name for fc in db.facility_categories)
    category_resolver = AbbreviationResolver(all_categories)

    for i, line in enumerate(file_lines):

        m = re.match(INGREDIENT_LINE_REGEX, line)
        if m is not None:
            number_string, product_name = m[1], m[2]
            if product_name not in all_products:
                full_product_name = product_resolver(productname)
                file_lines[i] = f"{number_string} {full_product_name}"
            continue

        m = re.match(ARROW_LINE_REGEX, line)
        if m is not None:
            seconds_string, category_name = m[1], m[2]
            if category_name not in all_categories:
                full_category_name = category_resolver(category_name)
                file_lines[i] = f"^ {seconds_string} s ({full_category_name})"

    return _split_on_blank_lines(file_lines)


#########################################
# Functions for Parsing a Single Recipe #
#########################################

def _parse_ingredient(
    recipe_block: list[str],
    i: int
) -> ProductQuantity[int] | None:
    if i < 0 or i >= len(recipe_block):
        return None

    m = re.match(INGREDIENT_LINE_REGEX, recipe_block[i])
    if m is None:
        return None

    number_string, product_name = m[1], m[2]
    return ProductQuantity(int(number_string), product_name)


def _parse_arrow_line(
    recipe_block: list[str],
    i: int
) -> tuple[Time, FacilityCategory]:
    if i < 0 or i >= len(recipe_block):
        raise ValueError("arrow line index out of bounds")

    m = re.match(ARROW_LINE_REGEX, recipe_block[i])
    if m is None:
        raise ValueError(f"unable to parse arrow line: {recipe_block[i]!r}")

    seconds_string, category_name = m[1], m[2]
    return Time(read_rational(seconds_string)), FacilityCategory(category_name)


def _parse_nametag_line(recipe_block: list[str], i: int) -> str | None:
    if i < 0 or i >= len(recipe_block):
        return None
    if i == len(recipe_block) - 1:
        raise ValueError("started to parse nametag line before end of recipe")

    m = re.match(NAMETAG_LINE_REGEX, recipe_block[i])
    if m is None:
        raise ValueError(f"unable to parse nametag line: {recipe_block[i]!r}")

    recipe_name = m[1]
    return str(recipe_name)


def read_recipe(recipe_block: list[str]) -> Recipe:
    i = 0

    r_outputs: list[ProductQuantity[int]] = []
    ingredient = _parse_ingredient(recipe_block, i)
    while ingredient is not None:
        r_outputs.append(ingredient)
        i += 1
        ingredient = _parse_ingredient(recipe_block, i)

    r_period, r_madein = _parse_arrow_line(recipe_block, i)
    i += 1

    r_inputs: list[ProductQuantity[int]] = []
    ingredient = _parse_ingredient(recipe_block, i)
    while ingredient is not None:
        r_inputs.append(ingredient)
        i += 1
        ingredient = _parse_ingredient(recipe_block, i)

    r_name = _parse_nametag_line(recipe_block, i)

    return Recipe(r_name, r_outputs, r_inputs, r_period, r_madein)
