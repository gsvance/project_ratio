# databases.py
# Database type for reading, storing, and supplying all forms of DSP game data

from facilities import FacilityCategory, Facility
from products import Product
from rates import Rate, Time
from recipes import Recipe


#######################################
# DataBase Type and Inner Constructor #
#######################################

class DataBase:

    def __init__(self) -> None:
        self.facility_categories: set[FacilityCategory] = set()
        self.facilities: dict[str, Facility] = {}
        self.products: set[Product] = set()
        self.recipes: dict[str, Recipe] = {}
        self.rates: dict[str, Rate] = {}
        self.times: dict[str, Time] = {}
        self.lookup_table_facilities: dict[FacilityCategory, set[Facility]] = {}
        self.lookup_table_recipes: dict[Product, set[Recipe]] = {}

    ###############################
    # Lookup Table Initialization #
    ###############################

    def _make_table_facilities(self) -> 'DataBase':
        for facility in self.facilities.values():
            if facility.category not in self.lookup_table_facilities:
                self.lookup_table_facilities[facility.category] = set()
            self.lookup_table_facilities[facility.category].add(facility)
        return self

    def _make_table_recipes(self) -> 'DataBase':
        for recipe in self.recipes.values():
            for quantity in recipe.outputs:
                if quantity.product not in self.lookup_table_recipes:
                    self.lookup_table_recipes[quantity.product] = set()
                self.lookup_table_recipes[quantity.product].add(recipe)
        return self

    def make_tables(self) -> 'DataBase':
        print("Making lookup tables for DataBase...", end="", flush=True)
        self._make_table_facilities()
        self._make_table_recipes()
        print(" done!")
        return self

    ############################
    # DataBase Query Functions #
    ############################

    def find_facilities(
        self,
        category: FacilityCategory | str | Recipe
    ) -> set[Facility]:
        if isinstance(category, str):
            category = FacilityCategory(category)
        elif isinstance(category, Recipe):
            category = category.category
        return self.lookup_table_facilities.get(category, set())

    def find_recipes(
        self,
        recipe_output: Product | str
    ) -> set[Recipe]:
        if not isinstance(recipe_output, Product):
            recipe_output = Product(recipe_output)
        return self.lookup_table_recipes.get(recipe_output, set())
