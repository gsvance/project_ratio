# proliferators.py
# 

from dataclasses import dataclass
from enum import Enum
from fractions import Fraction

from products import Product


###
# 
###

@dataclass(frozen=True, slots=True)
class Proliferator:
    product: Product
    sprays: int
    extra: Fraction
    speedup: Fraction


ProliferationMode = Enum(
    "ProliferationMode", ["EXTRA_PRODUCTS", "PRODUCTION_SPEEDUP"]
)
