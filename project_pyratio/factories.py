# factories.py
# Data types for a DSP factory and the groups of producers that make it up

from fractions import Fraction

from facilities import Facility
from products import Product, ProductQuantity
from rates import Rate
from rational_utilities import pretty_string
from recipes import Recipe


#####################################
# RecipeCrafter Type Implementation #
#####################################

# When playing DSP, the number of facilities built obviously must be an int
# However, we live in theory land where everything is perfectly "at ratio"
# To translate this fantasy number back into the DSP world, use ceil(how_many)
class RecipeCrafter:

    def __init__(
        self,
        recipe: Recipe,
        facility: Facility,
        how_many: Fraction | int | float
    ) -> None:
        if how_many <= 0 :
            raise ValueError("RecipeProducer should not have howmany <= 0")

        self.recipe = recipe
        self.facility = facility
        self.how_many = Fraction(how_many)  # int in DSP terms

        # TODO: proliferation info for recipe inputs
        #::Proliferator
        #::ProliferationMode

        self._rates: dict[Product, Rate] = {}

    # This constructor takes a production rate and computes the value of howmany
    @classmethod
    def with_goal(
        cls,
        recipe: Recipe,
        facility: Facility,
        goal: ProductQuantity[Rate]
    ) -> 'RecipeCrafter':
        p, rate = goal.product, goal.quantity
        rc = RecipeCrafter(recipe, facility, 1)  # Temp value of howmany == 1

        if p not in rc.rates or rc.rates[p] <= Rate.zero():
            raise ValueError("given recipe does not produce goal product")

        rate_ratio = rate / rc.rates[p]

        rc.how_many *= rate_ratio

        # TODO: consider proliferation of the recipe crafter

        rc._compute_rates()
        return rc

    # Note: this function needs to be careful about not overwriting Dict entries
    # For example, X-Ray Cracking has Hydrogen inputs *and* outputs to account for
    # Use get!() here so the output rate will not be overwritten by the input rate
    def _compute_rates(self) -> dict[Product, Rate]:
        self._rates.clear()

        for output in self.recipe.outputs:
            recipe_rate = output.quantity / self.recipe.period
            total_rate = recipe_rate * self.facility.speed * self.how_many
            assert isinstance(total_rate, Rate)
            self._rates[output.product] = (
                self._rates.get(output.product, Rate.zero()) + total_rate
            )

        for input_ in self.recipe.inputs:
            recipe_rate = input_.quantity / self.recipe.period
            total_rate = recipe_rate * self.facility.speed * self.how_many
            assert isinstance(total_rate, Rate)
            self._rates[input_.product] = (
                self._rates.get(input_.product, Rate.zero()) - total_rate
            )

        # TODO: proliferation would affect all these recipe rates
        # *and* it would consume proliferator product at a certain rate

        return self._rates

    @property
    def rates(self) -> dict[Product, Rate]:
        if len(self._rates) == 0:
            self._compute_rates()
        return self.rates

    def __str__(self) -> str:
        parts: list[str] = []
        parts.append("Group of ")
        parts.append(pretty_string(self.how_many))
        parts.append(" ")
        parts.append(self.facility.name)
        parts.append(" crafting ")
        parts.append(self.recipe.name)
        return "".join(parts)

###############################
# Factory Type Implementation #
###############################

class Factory:

    def __init__(self, goal: ProductQuantity[Rate]) -> None:
        self.goal = goal
        self.crafters: list[RecipeCrafter] = []

        # TODO: output proflieration info for primary product
        #::Proliferator

        self._rates: dict[Product, Rate] = {}

        # If true, ignore negative rates
        self.ignored_rates: dict[Product, bool] = {}

    def _compute_rates(self) -> dict[Product, Rate]:
        self._rates.clear()

        self._rates[self.goal.product] = -self.goal.quantity
        for crafter in self.crafters:
            for product, rate in crafter.rates.items():
                self._rates[product] = (
                    self._rates.get(product, Rate.zero()) + rate
                )

        return self._rates

    @property
    def rates(self) -> dict[Product, Rate]:
        if len(self._rates) == 0:
            self._compute_rates()
        return self._rates

    def is_ignored(self, p: Product) -> bool:
        if p not in self.rates:
            raise ValueError("product must exist to check if ignored")
        return self.ignored_rates.get(p, False)

    # Negative rates are those which still need production added via crafters
    # Ignored products have no recipe or they were shot down by the user
    def negative_rates(self) -> dict[Product, Rate]:
        negatives: dict[Product, Rate] = {}
        for product, product_rate in self.rates.items():
            if not self.is_ignored(product) and product_rate < Rate.zero():
                negatives[product] = product_rate
        return negatives

    # Sometimes we need to know which crafters are producing a given product
    def find_crafters(self, p: Product) -> list[RecipeCrafter]:
        crafters: list[RecipeCrafter] = []
        for crafter in self.crafters:
            if p in crafter.rates and crafter.rates[p] > Rate.zero():
                crafters.append(crafter)
        return crafters

    def __str__(self) -> str:
        INDENT: str = " " * 2
        parts: list[str] = []

        parts.append("Factory:\n{INDENT}Goal: {self.goal}")

        parts.append(f"\n{INDENT}Crafters ({len(self.crafters)}):")
        for crafter in self.crafters:
            parts.append(f"\n{INDENT * 2}{crafter}")
        if len(self.crafters) == 0:
            parts.append(f"\n{INDENT * 2}(none)")

        inputs = [
            (product, rate) for product, rate in self.rates.items()
            if rate < Rate.zero()
        ]
        parts.append(f"\n{INDENT}Inputs Required ({len(inputs)}):")
        for product, product_rate in inputs:
            parts.append(
                f"\n{INDENT * 2}{ProductQuantity(-product_rate, product)}"
            )
        if len(inputs) == 0:
            parts.append(f"\n{INDENT * 2}(none)")

        byproducts = [
            (product, rate) for product, rate in self.rates.items()
            if rate > Rate.zero()
        ]
        parts.append(f"\n{INDENT}Byproducts ({len(byproducts)}):")
        for product, product_rate in byproducts:
            parts.append(
                f"\n{INDENT * 2}{ProductQuantity(product_rate, product)}"
            )
        if len(byproducts) == 0:
            parts.append(f"\n{INDENT * 2}(none)")

        return "".join(parts)

    ##################################
    # Factory Manipulation Functions #
    ##################################

    def set_ignored(self, p: Product) -> 'Factory':
        if p not in self.rates:
            raise ValueError("product must exist to be set as ignored")
        self.ignored_rates[p] = True
        return self

    def set_all_ignored(self) -> 'Factory':
        for product in self.rates:
            self.ignored_rates[product] = True
        return self

    def connect_crafter(self, rc: RecipeCrafter) -> 'Factory':
        if rc in self.crafters:
            raise ValueError("cannot connect same crafter to a factory twice")
        self.crafters.append(rc)
        self._compute_rates()
        return self

    def upgrade_crafter(
        self,
        rc: RecipeCrafter,
        production_increase: ProductQuantity[Rate]
    ) -> 'Factory':
        target = production_increase.product
        delta_rate = production_increase.quantity

        if rc not in self.crafters:
            raise ValueError("crafter must be factory-connected to upgrade")
        if target in rc.rates:
            if rc.rates[target] <= Rate.zero():
                raise ValueError(
                    "upgrading crafter does not produce target product"
                )
        if rc.rates[target] + delta_rate <= Rate.zero():
            raise ValueError("final upgraded crafter rate must be positive")

        upgrade_ratio = (rc.rates[target] + delta_rate) / rc.rates[target]
        assert isinstance(upgrade_ratio, Fraction)
        rc.how_many *= upgrade_ratio

        # TODO: consider how the proliferation of the crafter is to be upgraded

        rc._compute_rates()
        self._compute_rates()

        return self
