# products.py
# Foundational types for representing DSP recipe ingredients

from dataclasses import dataclass
from typing import Generic, TypeVar


###############################
# Product Type Implementation #
###############################

@dataclass(init=False, frozen=True, slots=True)
class Product:
    name: str

    def __init__(self, name: str) -> None:
        object.__setattr__(self, "name", name.strip())
        if self.name == "":
            raise ValueError("product name empty or all whitespace")

    def __str__(self) -> str:
        return self.name


#######################################
# ProductQuantity Type Implementation #
#######################################

# The quantity type T can be pretty much anything that "quantifies" the product
# Examples: an integer, a production rate... the only limit is my creativity!
T = TypeVar("T")


@dataclass(init=False, frozen=True, slots=True)
class ProductQuantity(Generic[T]):
    quantity: T
    product: Product
    # TODO: add proliferation status as part of this?

    def __init__(self, quantity: T, product: Product | str) -> None:
        if not isinstance(product, Product):
            product = Product(product)
        object.__setattr__(self, "quantity", quantity)
        object.__setattr__(self, "product", product)

    @property
    def name(self) -> str:
        return self.product.name

    def __str__(self) -> str:
        return f"{self.quantity} {self.product}"
