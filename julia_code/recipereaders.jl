# recipereaders.jl
# Code for parsing recipes from the recipe data file into Julia types


############################################
# Recipe Block Specification for Data File #
############################################

# Any whitespace at the start or end of a line is stripped before parsing
# Recipe blocks are separated by one or more blank lines in the data file
# Any line beginning with a '#' is ignored (and not considered to be blank)

# A BNF-style description of the recipe block grammar:
#            recipe_block := outputs arrow_line inputs optional_nametag_line
#                 outputs := ingredient_line | ingredient_line outputs
#              arrow_line := "^" time_period "s" "(" facility_category ")"
#                  inputs := ingredient_line | ingredient_line inputs
#   optional_nametag_line := "" | "<>" recipe_name
#         ingredient_line := number product_name

const COMMENTLINEREGEX = r"^\#.*$"
const ARROWLINEREGEX = r"^\^ *([0-9.]+) *s *\((.+)\)$"
const NAMETAGLINEREGEX = r"^<> *(.+)$"
const INGREDIENTLINEREGEX = r"^([0-9]+) +(.+)$"


################################################
# Functions for Parsing the Entire Recipe File #
################################################

# This operates something like split(listoflines, isempty, keepempty = false)
# However, Base.split() only accepts sequences <: AbstractString as its input
# There really could exist a somewhat more general version of that function
# Why won't split just accept an arbitrary iterable and predicate function?
# And I can't seem to trick Julia into doing it by wrapping a Vector{String}
# It runs into all kinds of problems with AbstractChar and the SubString type
# This array-splitting problem also seems to be weirdly, totally un-Google-able
# Am I the only person who has ever wanted to split up an array like this???
function _splitonblanklines(listoflines::AbstractVector{<:AbstractString})
	
	sampleview = view(listoflines,
		firstindex(listoflines) : lastindex(listoflines))
	listofblocks = Vector{typeof(sampleview)}()
	
	currentblockstart = nothing
	
	for i in eachindex(listoflines)
		
		if isempty(listoflines[i])
			if !isnothing(currentblockstart)
				block = view(listoflines, currentblockstart : (i-1))
				push!(listofblocks, block)
			end
			currentblockstart = nothing
		elseif isnothing(currentblockstart)
			currentblockstart = i
		end
	end
	
	if !isnothing(currentblockstart)
		block = view(listoflines, currentblockstart : lastindex(listoflines))
		push!(listofblocks, block)
	end
	
	listofblocks
end

function readrecipefile(datafilename::AbstractString, db::DataBase)
	
	filelines = map(strip, readlines(datafilename))
	filelines = filter(!contains(COMMENTLINEREGEX), filelines)
	
	allproducts = Set{String}(name(p) for p in db.products)
	productresolver = AbbreviationResolver(allproducts)
	
	allcategories = Set{String}(name(fc) for fc in db.facilitycategories)
	categoryresolver = AbbreviationResolver(allcategories)
	
	for i in eachindex(filelines)
		
		m = match(INGREDIENTLINEREGEX, filelines[i])
		if !isnothing(m)
			numberstring, productname = m.captures
			if !(productname in allproducts)
				fullproductname = productresolver(productname)
				filelines[i] = "$(numberstring) $(fullproductname)"
			end
			continue
		end
			
		m = match(ARROWLINEREGEX, filelines[i])
		if !isnothing(m)
			secondsstring, categoryname = m.captures
			if !(categoryname in allcategories)
				fullcategoryname = categoryresolver(categoryname)
				filelines[i] = "^ $(secondsstring) s ($(fullcategoryname))"
			end
		end
	end
	
	_splitonblanklines(filelines)
end


#########################################
# Functions for Parsing a Single Recipe #
#########################################

function _parseingredient(recipeblock::AbstractVector{<:AbstractString}, i)
	
	checkbounds(Bool, recipeblock, i) || return nothing
	
	m = match(INGREDIENTLINEREGEX, recipeblock[i])
	isnothing(m) && return nothing
	
	numberstring, productname = m.captures
	ProductQuantity(parse(Int, numberstring), productname)
end

function _parsearrowline(recipeblock::AbstractVector{<:AbstractString}, i)
	
	checkbounds(Bool, recipeblock, i) || error("arrow line index out of bounds")
	
	m = match(ARROWLINEREGEX, recipeblock[i])
	isnothing(m) && error("unable to parse arrow line: ", repr(recipeblock[i]))
	
	secondsstring, categoryname = m.captures
	Time(readrational(secondsstring)), FacilityCategory(categoryname)
end

function _parsenametagline(recipeblock::AbstractVector{<:AbstractString}, i)
	
	checkbounds(Bool, recipeblock, i) || return nothing
	i == lastindex(recipeblock) ||
		error("started to parse nametag line before end of recipe")
	
	m = match(NAMETAGLINEREGEX, recipeblock[i])
	isnothing(m) &&
		error("unable to parse nametag line: ", repr(recipeblock[i]))
	
	recipename = only(m.captures)
	string(recipename)
end

function readrecipe(recipeblock::AbstractVector{<:AbstractString})
	
	i = firstindex(recipeblock)
	
	r_outputs = Vector{ProductQuantity{Int}}()
	ingredient = _parseingredient(recipeblock, i)
	while !isnothing(ingredient)
		push!(r_outputs, ingredient)
		i = nextind(recipeblock, i)
		ingredient = _parseingredient(recipeblock, i)
	end
	
	r_period, r_madein = _parsearrowline(recipeblock, i)
	i = nextind(recipeblock, i)
	
	r_inputs = Vector{ProductQuantity{Int}}()
	ingredient = _parseingredient(recipeblock, i)
	while !isnothing(ingredient)
		push!(r_inputs, ingredient)
		i = nextind(recipeblock, i)
		ingredient = _parseingredient(recipeblock, i)
	end
	
	r_name = _parsenametagline(recipeblock, i)
	
	Recipe(r_name, r_outputs, r_inputs, r_period, r_madein)
end

