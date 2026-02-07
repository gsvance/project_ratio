# abbreviations.py
# This file defines "abbreviations" and tells Python how to interpret them

from collections.abc import Iterable
from dataclasses import dataclass
import re


###############################
# Abbreviation Implementation #
###############################

# Abbreviation Standard:
# Construct an abbreviation of a string by deleting all characters that are not
# uppercase letters. To get around conflicts when two strings would produce the
# same sequence of uppercase letters, I may optionally choose to NOT delete one
# or more lowercase letters in the string. The remaining letters must always
# appear in the same order as in the original string. An empty string is not a
# valid abbreviation. The optional inclusion of arbitrarily chosen lowercase
# letters means that I cannot write a function to *generate* abbreviations,
# but that's okay. The code doesn't need to produce abbreviations, it just
# needs to be able to unambiguously interpret the ones I invent so that the
# recipes file can be a little less verbose.

@dataclass(init=False, frozen=True, slots=True)
class Abbreviation:
    string: str
    regex: re.Pattern[str]

    def __init__(self, string: str) -> None:
        if string == "":
            raise ValueError("empty abbreviation string")
        if not string.isalpha():
            raise ValueError("non-alphabetic abbreviation string: {string!r}")

        NON_CAPITALS = "[^A-Z]*"  # Zero or more deletable characters in a row
        regex = re.compile(NON_CAPITALS.join(f"^{string}$"))

        object.__setattr__(self, "string", string)
        object.__setattr__(self, "regex", regex)

    def abbreviates(self, long_string: str) -> bool:
        return re.match(self.regex, long_string) is not None


#######################################
# AbbreviationResolver Implementation #
#######################################

class AbbreviationResolver:

    def __init__(self, string_collection: Iterable[str]) -> None:
        self.string_collection: set[str] = set(string_collection)
        self.lookup_table: dict[str, str] = dict()

    def _resolve_abbreviation(self, abbrev: Abbreviation) -> str:
        possible_matches: set[str] = set()
        for long_string in self.string_collection:
            if abbrev.abbreviates(long_string):
                possible_matches.add(long_string)

        if len(possible_matches) > 1:
            raise ValueError(
                "too many strings match abbreviation: "
                f"{abbrev.string!r} => {list(possible_matches)}"
            )
        if len(possible_matches) == 0:
            raise ValueError(
                f"found no strings matching abbreviation: {abbrev.string!r}"
            )

        return possible_matches.pop()

    def __call__(self, abbrev_str: str) -> str:
        try:
            return self.lookup_table[abbrev_str]
        except KeyError:
            return self._resolve_abbreviation(Abbreviation(abbrev_str))
