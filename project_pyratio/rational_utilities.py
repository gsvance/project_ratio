# rational_utilities.py
# Utilities for picky methods of input and output involving rationals

from fractions import Fraction


#############################
# Rational Output Utilities #
#############################

PRETTY_DIGITS: int = 2


def pretty_string(r: Fraction | float | int) -> str:
    if int(r) == r:
        return str(int(r))
    else:
        return str(round(float(r), ndigits=PRETTY_DIGITS))


############################
# Rational Input Utilities #
############################

def try_read_rational(string: str) -> Fraction | None:
    try:
        return Fraction(string.replace("//", "/", 1))
    except ValueError:
        return None


def read_rational(string: str) -> Fraction:
    r = try_read_rational(string)
    if r is None:
        raise ValueError(f"string {string!r} could not be read as a rational")
    return r
