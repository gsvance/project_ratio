# algorithms.py
# Various smart functions for expanding factory plans in steps

from dataclasses import dataclass
from typing import Any

from databases import DataBase
from facilities import Facility
from factories import Factory, RecipeCrafter
from products import Product, ProductQuantity
from rates import Rate
from rational_utilities import try_read_rational
from recipes import Recipe
from user_questions import get_user_choice, get_user_text


###########################################
# Decisions that are Deferred to the User #
###########################################

# Utility return type for makeexpanddecision() function
@dataclass(frozen=True, slots=True)
class ExpandDecision:
    new_crafter: bool
    argument: Any


def make_expand_decision(
    factory: Factory,
    db: DataBase,
    p: Product
) -> ExpandDecision | None:
    existing_crafters = factory.find_crafters(p)
    possible_recipes = db.find_recipes(p)

    new_crafter: dict[str, bool] = {}
    args: dict[str, Any] = {}

    for crafter in existing_crafters:
        string = f"Expand Crafter: {crafter}"
        new_crafter[string] = False
        args[string] = crafter

    for recipe in possible_recipes:
        string = f"New Crafter: {recipe.name}"
        new_crafter[string] = True
        args[string] = recipe

    options = list(new_crafter.keys())
    chosen_string = get_user_choice(
        f"Choose how to produce {p}:",
        options,
        "<ignore this product>",
        sort_by=lambda x: x
    )

    if chosen_string is None:
        return None
    return ExpandDecision(new_crafter[chosen_string], args[chosen_string])


def make_facility_decision(db: DataBase, recipe: Recipe) -> Facility:
    possible_facilities = db.find_facilities(recipe)

    if len(possible_facilities) > 1:
        return get_user_choice(
            f"Select a facility to craft {recipe.name}:",
            possible_facilities,
            "<nevermind, ignore this product>",
            sortby=lambda x : x.speed
        )
    assert len(possible_facilities) == 1
    return possible_facilities.pop()


def make_goal_decision(db: DataBase) -> ProductQuantity[Rate] | None:
    item = get_user_choice(
        "Choose the product this factory should yield:",
        db.products,
        "<quit program>",
        sort_by=lambda x: x.name
    )
    if item is None:
        return None

    per_second = get_user_text(
        "Enter desired production rate (per second): ",
        try_read_rational
    )
    rate = Rate(per_second)

    # TODO: ask if we want the output product to be proliferated

    return ProductQuantity(rate, item)


def make_production_decision(
    factory: Factory,
    db: DataBase
) -> ProductQuantity[Rate] | None:
    possible_targets = find_production_gaps(factory, db)

    if len(possible_targets) == 0:
        return None
    return get_user_choice(
        "Choose next production target to satisfy:",
        possible_targets,
        "<ignore all and finish>",
        sort_by=lambda x: x.name
    )


####################################
# Algorithms for Factory Expansion #
####################################

def find_production_gaps(
    factory: Factory,
    db: DataBase
) -> list[ProductQuantity[Rate]]:
    possible_gaps = factory.negative_rates()
    verified_gaps: list[ProductQuantity[Rate]] = []

    for product, rate in possible_gaps.items():
        if len(db.find_recipes(product)) == 0:
            factory.set_ignored(product)
        else:
            verified_gaps.append(ProductQuantity(-rate, product))

    return verified_gaps


def expand_factory_once(
    factory: Factory,
    db: DataBase,
    objective: ProductQuantity[Rate]
) -> Factory:
    expand_decision = make_expand_decision(factory, db, objective.product)

    if expand_decision is None:
        factory.set_ignored(objective.product)
        return factory

    if expand_decision.new_crafter:  # Make a new crafter

        recipe: Recipe = expand_decision.argument
        facility = make_facility_decision(db, recipe)

        if facility is None:
            factory.set_ignored(objective.product)
            return factory

        new_crafter = RecipeCrafter.with_goal(recipe, facility, objective)
        factory.connect_crafter(new_crafter)

    else:  # Expand an existing crafter

        crafter: RecipeCrafter = expand_decision.argument
        factory.upgrade_crafter(crafter, objective)

    return factory


def generate_factory(db: DataBase) -> Factory | None:
    goal = make_goal_decision(db)
    if goal is None:
        return None
    factory = Factory(goal)

    while True:
        target = make_production_decision(factory, db)
        if target is None:
            factory.set_all_ignored()
            break
        expand_factory_once(factory, db, target)

    return factory
