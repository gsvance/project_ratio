# factories.jl
# Data types for a DSP factory and the groups of producers that make it up


#####################################
# RecipeCrafter Type Implementation #
#####################################

# When playing DSP, the number of facilities built obviously must be an Int
# However, we live in theory land where everything is perfectly "at ratio"
# To translate this fantasy number back into the DSP world, use ceil(howmany)
mutable struct RecipeCrafter
	recipe::Recipe
	facility::Facility
	howmany::Rational{Int}  # Int in DSP terms
	
	# TODO: proliferation info for recipe inputs
	#::Proliferator
	#::ProliferationMode
	
	rates::Dict{Product, Rate}
	
	function RecipeCrafter(recipe::Recipe, facility::Facility, howmany::Real)
		howmany > zero(howmany) ||
			error("RecipeProducer should not have howmany <= 0")
		new(recipe, facility, convert(Rational{Int}, howmany),
			Dict{Product, Rate}())
	end
end

# This constructor takes a production rate and computes the value of howmany
function RecipeCrafter(recipe::Recipe, facility::Facility,
	goal::ProductQuantity{Rate})
	
	p, rate = product(goal), quantity(goal)
	rc = RecipeCrafter(recipe, facility, 1)  # Temp value of howmany == 1
	
	haskey(rates(rc), p) && rates(rc)[p] > zero(Rate) ||
		error("given recipe does not produce goal product")
	
	rateratio = rate / rates(rc)[p]
	
	rc.howmany *= rateratio
	
	# TODO: consider proliferation of the recipe crafter
	
	_computerates!(rc)
	rc
end

recipe(rc::RecipeCrafter) = rc.recipe
facility(rc::RecipeCrafter) = rc.facility
howmany(rc::RecipeCrafter) = rc.howmany

# Note: this function needs to be careful about not overwriting Dict entries
# For example, X-Ray Cracking has Hydrogen inputs *and* outputs to account for
# Use get!() here so the output rate will not be overwritten by the input rate
function _computerates!(rc::RecipeCrafter)
	
	empty!(rc.rates)
	
	for output in outputs(recipe(rc))
		reciperate = quantity(output) / period(recipe(rc))
		totalrate = reciperate * speed(facility(rc)) * howmany(rc)
		rc.rates[product(output)] =
			get!(rc.rates, product(output), zero(Rate)) + totalrate
	end
	
	for input in inputs(recipe(rc))
		reciperate = quantity(input) / period(recipe(rc))
		totalrate = reciperate * speed(facility(rc)) * howmany(rc)
		rc.rates[product(input)] =
			get!(rc.rates, product(input), zero(Rate)) - totalrate
	end
	
	# TODO: proliferation would affect all these recipe rates
	# *and* it would consume proliferator product at a certain rate
	
	rc.rates
end

rates(rc::RecipeCrafter) = (isempty(rc.rates) && _computerates!(rc); rc.rates)

function Base.show(io::IO, rc::RecipeCrafter)
	print(io, "Group of ")
	print(io, prettystring(howmany(rc)))
	print(io, " ")
	print(io, name(facility(rc)))
	print(io, " crafting ")
	print(io, name(recipe(rc)))
end


###############################
# Factory Type Implementation #
###############################

struct Factory
	goal::ProductQuantity{Rate}
	crafters::Vector{RecipeCrafter}
	
	# TODO: output proflieration info for primary product
	#::Proliferator
	
	rates::Dict{Product, Rate}
	ignoredrates::Dict{Product, Bool}  # if true, ignore negative rates
	
	function Factory(goal::ProductQuantity{Rate})
		new(goal, Vector{RecipeCrafter}(), Dict{Product, Rate}(),
			Dict{Product, Bool}())
	end
end

goal(f::Factory) = f.goal
crafters(f::Factory) = f.crafters

function _computerates!(f::Factory)
	
	empty!(f.rates)
	
	f.rates[product(goal(f))] = -quantity(goal(f))
	mergewith!(+, f.rates, (rates(crafter) for crafter in crafters(f))...)
	
	f.rates
end

rates(f::Factory) = (isempty(f.rates) && _computerates!(f); f.rates)

function isignored(f::Factory, p::Product)
	haskey(rates(f), p) || error("product must exist to check if ignored")
	get!(f.ignoredrates, p, false)
end

# Negative rates are those which still need production added via crafters
# Ignored products have no recipe or they were shot down by the user
function negativerates(f::Factory)
	filter(rates(f)) do (product, productrate)
		!isignored(f, product) && productrate < zero(Rate)
	end
end

# Sometimes we need to know which crafters are producing a given product
function findcrafters(f::Factory, p::Product)
	filter(f.crafters) do crafter
		haskey(rates(crafter), p) && rates(crafter)[p] > zero(Rate)
	end
end

function Base.show(io::IO, f::Factory)
	
	INDENT = " " ^ 2
	
	print(io, "Factory:\n", INDENT, "Goal: ", goal(f))
	
	print(io, '\n', INDENT, "Crafters (", length(crafters(f)), "):")
	for crafter in crafters(f)
		print(io, '\n', INDENT ^ 2, crafter)
	end
	isempty(crafters(f)) && print(io, '\n', INDENT ^ 2, "(none)")
	
	inputs = filter(((product, rate),) -> rate < zero(Rate), rates(f))
	print(io, '\n', INDENT, "Inputs Required (", length(inputs), "):")
	for (product, productrate) in inputs
		print(io, '\n', INDENT ^ 2, ProductQuantity(-productrate, product))
	end
	isempty(inputs) && print(io, '\n', INDENT ^ 2, "(none)")
	
	byproducts = filter(((product, rate),) -> rate > zero(Rate), rates(f))
	print(io, '\n', INDENT, "Byproducts (", length(byproducts), "):")
	for (product, productrate) in byproducts
		print(io, '\n', INDENT ^ 2, ProductQuantity(productrate, product))
	end
	isempty(byproducts) && print(io, '\n', INDENT ^ 2, "(none)")
end


##################################
# Factory Manipulation Functions #
##################################

function setignored!(f::Factory, p::Product)
	haskey(rates(f), p) || error("product must exist to be set as ignored")
	f.ignoredrates[p] = true
	f
end

function setallignored!(f::Factory)
	for product in keys(rates(f))
		f.ignoredrates[product] = true
	end
	f
end

function connectcrafter!(f::Factory, rc::RecipeCrafter)
	rc in f.crafters && error("cannot connect same crafter to a factory twice")
	push!(f.crafters, rc)
	_computerates!(f)
	f
end

function upgradecrafter!(f::Factory, rc::RecipeCrafter,
	productionincrease::ProductQuantity{Rate})
	
	target = product(productionincrease)
	Δrate = quantity(productionincrease)
	
	rc in f.crafters || error("crafter must be factory-connected to upgrade")
	haskey(rates(rc), target) && rates(rc)[target] > zero(Rate) ||
		error("upgrading crafter does not produce target product")
	rates(rc)[target] + Δrate > zero(Rate) ||
		error("final upgraded crafter rate must be positive")
	
	upgraderatio = (rates(rc)[target] + Δrate) / rates(rc)[target]
	
	rc.howmany *= upgraderatio
	
	# TODO: consider how the proliferation of the crafter is to be upgraded
	
	_computerates!(rc)
	_computerates!(f)
	
	f
end

