# rates.py
# Simple types for representing measurements with dimensions of time or 1/time

# TODO: add functions for parsing times and rates from strings with units
# TODO: add functions for outputing times and rates with converted units

from dataclasses import dataclass
from fractions import Fraction
from numbers import Number
from typing import Union

from rational_utilities import pretty_string


# I want to keep rates and times rational, so they should avoid float math
# This is "a rational" as defined in math class, i.e., the infinite set Q
IntegerOrRational = Union[int, Fraction]


############################
# Time Type Implementation #
############################

@dataclass(init=False, order=True, frozen=True, slots=True)
class Time(Number):
    seconds: Fraction

    def __init__(self, seconds: Union[IntegerOrRational, 'Rate']) -> None:
        if isinstance(seconds, Rate):
            seconds = Fraction(1, 1) / seconds.per_second
        elif not isinstance(seconds, Fraction):
            seconds = Fraction(seconds)
        object.__setattr__(self, "seconds", seconds)

    def __str__(self) -> str:
        return f"{pretty_string(self.seconds)}s"

    @classmethod
    def zero(cls) -> 'Time':
        return Time(Fraction(0, 1))

    def __neg__(self) -> 'Time':
        return Time(-self.seconds)

    def __add__(self, other: 'Time') -> 'Time':
        return Time(self.seconds + other.seconds)

    def __sub__(self, other: 'Time') -> 'Time':
        return Time(self.seconds - other.seconds)

    def __mul__(
        self,
        other: Union[IntegerOrRational, 'Rate']
    ) -> Union['Time', Fraction]:
        if isinstance(other, Rate):
            return self.seconds * other.per_second
        return Time(self.seconds * other)

    def __rmul__(self, other: IntegerOrRational) -> Union['Time', Fraction]:
        return self * other

    def __truediv__(
        self,
        other: Union['Time', IntegerOrRational]
    ) -> Union['Time', Fraction]:
        if isinstance(other, Time):
            return self.seconds / other.seconds
        else:
            return Time(self.seconds / other)

    def __rtruediv__(self, other: IntegerOrRational) -> 'Rate':
        return Rate(self / other)


############################
# Rate Type Implementation #
############################

@dataclass(init=False, order=True, frozen=True, slots=True)
class Rate(Number):
    per_second: Fraction

    def __init__(self, per_second: Union[IntegerOrRational, 'Time']) -> None:
        if isinstance(per_second, Time):
            per_second = Fraction(1, 1) / per_second.seconds
        elif not isinstance(per_second, Fraction):
            per_second = Fraction(per_second)
        object.__setattr__(self, "per_second", per_second)

    def __str__(self) -> str:
        return f"{pretty_string(self.per_second)}/s"

    @classmethod
    def zero(cls) -> 'Rate':
        return Rate(Fraction(0, 1))

    def __neg__(self) -> 'Rate':
        return Rate(-self.per_second)

    def __add__(self, other: 'Rate') -> 'Rate':
        return Rate(self.per_second + other.per_second)

    def __sub__(self, other: 'Rate') -> 'Rate':
        return Rate(self.per_second - other.per_second)

    def __mul__(
        self,
        other: Union[IntegerOrRational, 'Time']
    ) -> Union['Rate', Fraction]:
        if isinstance(other, Time):
            return self.per_second * other.seconds
        return Rate(self.per_second * other)

    def __rmul__(self, other: IntegerOrRational) -> Union['Rate', Fraction]:
        return self * other

    def __truediv__(
        self,
        other: Union[IntegerOrRational, 'Rate']
    ) -> Union['Rate', Fraction]:
        if isinstance(other, Rate):
            return self.per_second / other.per_second
        return Rate(self.per_second / other)

    def __rtruediv__(self, other: IntegerOrRational) -> 'Time':
        return Time(self / other)
