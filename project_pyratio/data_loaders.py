# data_loaders.py
# Functions for loading DSP data types from (mainly TOML) files into Python

from pathlib import Path
import tomllib
from typing import Any

from databases import DataBase
from facilities import FacilityCategory, Facility
from products import Product
from rates import Rate, Time
from recipe_readers import read_recipe, read_recipe_file


################################
# Locations of Game Data Files #
################################

GAME_DATA_DIRECTORY: Path = Path("game_data")

FACILITIES_FILE_NAME: Path = GAME_DATA_DIRECTORY / "facilities.toml"
PRODUCTS_FILE_NAME: Path = GAME_DATA_DIRECTORY / "products.toml"
RECIPES_FILE_NAME: Path = GAME_DATA_DIRECTORY / "recipes.dat"
RATES_FILE_NAME: Path = GAME_DATA_DIRECTORY / "rates.toml"


#####################################
# Facilities Data Loading Functions #
#####################################

def _load_data_facility_category(db: DataBase, toml_data: str) -> DataBase:
    fc_name = toml_data

    fc = FacilityCategory(fc_name)

    if fc in db.facility_categories:
        raise ValueError(f"duplicate facility category name: {fc.name!r}")

    db.facility_categories.add(fc)
    return db


def _load_data_facility(db: DataBase, toml_data: dict[str, Any]) -> DataBase:
    f_category_name: str = toml_data["category"]
    f_adjective: str = toml_data["adjective"]
    f_speed: int | float = toml_data["speed"]

    f = Facility(f_category_name, f_adjective, f_speed)

    if f.name in db.facilities:
        raise ValueError(f"duplicate facility name: {f.name!r}")
    if f.category not in db.facility_categories:
        raise ValueError(f"unknown facility category: {f.category.name!r}")

    db.facilities[f.name] = f
    return db


def _load_facilities_data(db: DataBase, toml_file_name: Path) -> DataBase:
    with open(toml_file_name, "rb", encoding="utf-8") as f:
        toml_table = tomllib.load(f)

    for category_data in toml_table["facility categories"]:
        _load_data_facility_category(db, category_data)

    for facility_data in toml_table["facilities"]:
        _load_data_facility(db, facility_data)

    return db


###################################
# Products Data Loading Functions #
###################################

def _load_data_product(db: DataBase, toml_data: str) -> DataBase:
    p_name = toml_data

    p = Product(p_name)

    if p in db.products:
        raise ValueError(f"duplicate product name: {p.name!r}")

    db.products.add(p)
    return db


def _load_products_data(db: DataBase, toml_file_name: Path) -> DataBase:
    with open(toml_file_name, "rb", encoding="utf-8") as f:
        toml_table = tomllib.load(f)

    for product_data in toml_table["products"]:
        _load_data_product(db, product_data)

    return db


##################################
# Recipes Data Loading Functions #
##################################

# Implementations of readrecipe() and readrecipefile() are in recipereaders.py

def _load_data_recipe(db: DataBase, recipe_data: list[str]) -> DataBase:
    recipe_block = recipe_data

    r = read_recipe(recipe_block)

    if r.name in db.recipes:
        raise ValueError(f"duplicate recipe name: {r.name!r}")

    db.recipes[r.name] = r
    return db


def _load_recipes_data(db: DataBase, data_file_name: Path) -> DataBase:

    # Pass in the database so it can be used to resolve abbreviations
    recipe_table = read_recipe_file(data_file_name, db)

    for recipe_data in recipe_table:
        _load_data_recipe(db, recipe_data)

    return db


################################
# Rates Data Loading Functions #
################################

def _load_data_rate(db: DataBase, toml_data: tuple[str, Any]) -> DataBase:
    rate_name = toml_data[0]
    r_per_second: int = toml_data[1]

    r = Rate(r_per_second)

    if rate_name in db.rates:
        raise ValueError(f"duplicate rate name: {rate_name!r}")

    db.rates[rate_name] = r
    return db


def _load_data_time(db: DataBase, toml_data: tuple[str, Any]) -> DataBase:
    time_name = toml_data[0]
    t_seconds: int = toml_data[1]

    rate_name = "/" + time_name

    t = Time(t_seconds)
    r = Rate(t)

    if time_name in db.times:
        raise ValueError(f"duplicate time name: {time_name!r}")
    if rate_name in db.rates:
        raise ValueError(f"duplicate rate name was generated: {rate_name!r}")

    db.times[time_name] = t
    db.rates[rate_name] = r
    return db


def _load_rates_data(db: DataBase, toml_file_name: Path) -> DataBase:
    with open(toml_file_name, "rb", encoding="utf-8") as f:
        toml_table = tomllib.load(f)

    for rate_data in toml_table["rates"]:
        _load_data_rate(db, rate_data)

    for time_data in toml_table["times"]:
        _load_data_time(db, time_data)

    return db


#######################################
# Top-Level DataBase Loading Function #
#######################################

def load_database(db: DataBase) -> DataBase:
    print("Loading contents of DataBase from files...", end="", flush=True)

    _load_facilities_data(db, FACILITIES_FILE_NAME)
    _load_products_data(db, PRODUCTS_FILE_NAME)
    _load_recipes_data(db, RECIPES_FILE_NAME)
    _load_rates_data(db, RATES_FILE_NAME)

    print(" done!")
    return db
