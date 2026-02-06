# products.jl
# Foundational types for representing DSP recipe ingredients


###############################
# Product Type Implementation #
###############################

struct Product
	name::String
	
	function Product(name::AbstractString)
		cleanedname = strip(name)
		isempty(cleanedname) && error("product name empty or all whitespace")
		new(string(cleanedname))
	end
end

name(p::Product) = p.name

Base.show(io::IO, p::Product) = print(io, name(p))


#######################################
# ProductQuantity Type Implementation #
#######################################

# The quantity type T can be pretty much anything that "quantifies" the product
# Examples: an integer, a production rate... the only limit is my creativity!
struct ProductQuantity{T}
	quantity::T
	product::Product
	# TODO: add proliferation status as part of this?
end

function ProductQuantity(quantity::T, productname::AbstractString) where T
	ProductQuantity{T}(quantity, Product(productname))
end

quantity(pq::ProductQuantity) = pq.quantity
product(pq::ProductQuantity) = pq.product
name(pq::ProductQuantity) = name(pq.product)

function Base.show(io::IO, pq::ProductQuantity)
	show(io, quantity(pq))
	print(io, " ")
	show(io, product(pq))
end

