# recipes.jl
# A type representing DSP recipes including inputs, outputs, and time periods


struct Recipe
	name::String
	# I'm using tuples here because I want recipes to be *strongly* immutable
	# All types that represent DSP game concepts should be immutable for safety
	outputs::Tuple{Vararg{ProductQuantity{Int}}}
	inputs::Tuple{Vararg{ProductQuantity{Int}}}
	period::Time
	madein::FacilityCategory
	
	function Recipe(name::AbstractString,
		outputs::AbstractVector{ProductQuantity{Int}},
		inputs::AbstractVector{ProductQuantity{Int}}, period::Time,
		madein::FacilityCategory)
		
		cleanedname = strip(name)
		isempty(cleanedname) && error("recipe name empty or all whitespace")
		
		# At some point, I may want to allow empty input or output lists...
		# ...but for the time being, these checks exist to preserve my sanity
		isempty(outputs) && error("recipe output collection is empty")
		isempty(inputs) && error("recipe input collection is empty")
		
		# Let's enforce the invariant of making sure the tuples are sorted
		# The actual order doesn't deeply matter, thus the use of hash()
		# What we care about here is that the ordering will be *consistent*
		# This invariant is important for equality comparisons between recipes
		# Vectors passed into this constructor could have elements in any order
		# That order should not affect whether recipe instances compare equal
		tupleoutputs = Tuple(sort(outputs, by = hash))
		tupleinputs = Tuple(sort(inputs, by = hash))
		
		new(string(cleanedname), tupleoutputs, tupleinputs, period, madein)
	end
end

function Recipe(outputs::AbstractVector{ProductQuantity{Int}},
	inputs::AbstractVector{ProductQuantity{Int}}, period::Time,
	madein::FacilityCategory)
	
	# Recipes with no special name are always named after their sole output
	autoname = name(only(outputs))
	
	Recipe(autoname, outputs, inputs, period, madein)
end

function Recipe(name::Nothing, outputs::AbstractVector{ProductQuantity{Int}},
	inputs::AbstractVector{ProductQuantity{Int}}, period::Time,
	madein::FacilityCategory)
	
	Recipe(outputs, inputs, period, madein)
end

name(r::Recipe) = r.name
outputs(r::Recipe) = r.outputs
inputs(r::Recipe) = r.inputs
period(r::Recipe) = r.period
category(r::Recipe) = r.madein

# Single line recipe printing
function Base.show(io::IO, r::Recipe)
	
	print(io, name(r))
	print(io, ": ")
	
	print(io, "[")
	join(io, (string(output) for output in outputs(r)), ", ")
	print(io, "]")
	
	print(io, " <<< ")
	print(io, period(r), " (", category(r), ")")
	print(io, " <<< ")
	
	print(io, "[")
	join(io, (string(input) for input in inputs(r)), ", ")
	print(io, "]")
end

# Multi-line recipe printing
function Base.show(io::IO, ::MIME"text/plain", r::Recipe)
	
	RECIPEINDENT = " " ^ 2
	
	print(io, name(r))
	print(io, ":\n")
	
	print(io, RECIPEINDENT, "[")
	join(io, (string(output) for output in outputs(r)), ", ")
	print(io, "]\n")
	
	print(io, RECIPEINDENT ^ 2, "^\n", RECIPEINDENT ^ 2, "^ ")
	print(io, period(r), " (", category(r), ")")
	print(io, "\n", RECIPEINDENT ^ 2, "^\n")
	
	print(io, RECIPEINDENT, "[")
	join(io, (string(input) for input in inputs(r)), ", ")
	print(io, "]")
end

