# facilities.py
# Types for representing production buildings and building classes from DSP

from dataclasses import dataclass
from fractions import Fraction

from rational_utilities import pretty_string


########################################
# FacilityCategory Type Implementation #
########################################

@dataclass(init=False, frozen=True, slots=True)
class FacilityCategory:
    name: str

    def __init__(self, name: str) -> None:
        object.__setattr__(self, "name", name.strip())
        if self.name == "":
            raise ValueError("facility category name empty or all whitespace")

    def __str__(self) -> str:
        return self.name


################################
# Facility Type Implementation #
################################

@dataclass(init=False, frozen=True, slots=True)
class Facility:
    category: FacilityCategory
    adjective: str
    speed: Fraction

    def __init__(
        self,
        category: FacilityCategory | str,
        adjective: str,
        speed: Fraction | float
    ) -> None:
        if not isinstance(category, FacilityCategory):
            category = FacilityCategory(category)
        if not isinstance(speed, Fraction):
            speed = Fraction(speed)
        object.__setattr__(self, "category", category)
        object.__setattr__(self, "adjective", adjective)
        object.__setattr__(self, "speed", speed)

    @property
    def name(self) -> str:
        if self.adjective == "":
            return f"{self.category}"
        else:
            return f"{self.adjective} {self.category}"

    def __str__(self) -> str:
        return f"{self.name} ({pretty_string(self.speed)}x)"
