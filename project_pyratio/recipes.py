# recipes.py
# A type representing DSP recipes including inputs, outputs, and time periods

from dataclasses import dataclass

from facilities import FacilityCategory
from products import ProductQuantity
from rates import Time


@dataclass(init=False, frozen=True, slots=True)
class Recipe:
    name: str
    # I'm using tuples here because I want recipes to be *strongly* immutable
    # All types that represent DSP game concepts should be immutable for safety
    outputs: tuple[ProductQuantity[int], ...]
    inputs: tuple[ProductQuantity[int], ...]
    period: Time
    made_in: FacilityCategory

    def __init__(
        self,
        name: str | None,
        outputs: list[ProductQuantity[int]],
        inputs: list[ProductQuantity[int]],
        period: Time,
        made_in: FacilityCategory
    ) -> None:
        if len(outputs) == 1:
            autoname = outputs[0].name

        # Recipes with no special name are always named after their sole output
        if name is None:
            name = autoname

        cleaned_name = name.strip()
        if cleaned_name == "":
            raise ValueError("recipe name empty or all whitespace")

        # At some point, I may want to allow empty input or output lists...
        # ...but for the time being, these checks exist to preserve my sanity
        if len(outputs) < 1:
            raise ValueError("recipe output collection is empty")
        if len(inputs) < 1:
            raise ValueError("recipe input collection is empty")

        # Let's enforce the invariant of making sure the tuples are sorted
        # The actual order doesn't deeply matter, thus the use of hash()
        # What we care about here is that the ordering will be *consistent*
        # This invariant is important for equality comparisons between recipes
        # Vectors passed into this constructor could have elements in any order
        # That order should not affect whether recipe instances compare equal
        tuple_outputs = tuple(sorted(outputs, key=hash))
        tuple_inputs = tuple(sorted(inputs, key=hash))

        object.__setattr__(self, "name", cleaned_name)
        object.__setattr__(self, "outputs", tuple_outputs)
        object.__setattr__(self, "inputs", tuple_inputs)
        object.__setattr__(self, "period", period)
        object.__setattr__(self, "made_in", made_in)

    @property
    def category(self) -> FacilityCategory:
        return self.made_in

    # Single line recipe printing
    def __repr__(self) -> str:
        parts: list[str] = []

        parts.append(self.name)
        parts.append(": ")

        parts.append("[")
        parts.append(", ".join(str(output) for output in self.outputs))
        parts.append("]")

        parts.append(" <<< ")
        parts.append(f"{self.period} ({self.category})")
        parts.append(" <<< ")

        parts.append("[")
        parts.append(", ".join(str(input_) for input_ in self.inputs))
        parts.append("]")

        return "".join(parts)

    # Multi-line recipe printing
    def __str__(self) -> str:
        RECIPE_INDENT: str = " " * 2
        parts: list[str] = []

        parts.append(self.name)
        parts.append(":\n")

        parts.append(f"{RECIPE_INDENT}[")
        parts.append(", ".join(str(output) for output in self.outputs))
        parts.append("]\n")

        parts.append(f"{RECIPE_INDENT * 2}^\n{RECIPE_INDENT * 2}^ ")
        parts.append(f"{self.period} ({self.category})")
        parts.append(f"\n{RECIPE_INDENT * 2}^\n")

        parts.append(f"{RECIPE_INDENT}[")
        parts.append(", ".join(str(input_) for input_ in self.inputs))
        parts.append("]")

        return "".join(parts)
