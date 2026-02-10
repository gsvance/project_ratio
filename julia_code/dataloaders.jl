# dataloaders.jl
# Functions for loading DSP data types from (mainly TOML) files into Julia


using TOML


################################
# Locations of Game Data Files #
################################

const GAMEDATADIRECTORY = joinpath("..", "game_data")

const FACILITIESFILENAME = joinpath(GAMEDATADIRECTORY, "facilities.toml")
const PRODUCTSFILENAME = joinpath(GAMEDATADIRECTORY, "products.toml")
const RECIPESFILENAME = joinpath(GAMEDATADIRECTORY, "recipes.dat")
const RATESFILENAME = joinpath(GAMEDATADIRECTORY, "rates.toml")


#####################################
# Facilities Data Loading Functions #
#####################################

function _loaddata!(db::DataBase, ::Type{FacilityCategory}, tomldata::String)
	
	fc_name = tomldata
	
	fc = FacilityCategory(fc_name)
	
	fc in db.facilitycategories && 
			error("duplicate facility category name: ", repr(name(fc)))
	
	push!(db.facilitycategories, fc)
	db
end

function _loaddata!(db::DataBase, ::Type{Facility}, tomldata::Dict{String, Any})
	
	f_categoryname = tomldata["category"] :: String
	f_adjective = tomldata["adjective"] :: String
	f_speed = tomldata["speed"] :: Union{Int, Float64}
	
	f = Facility(f_categoryname, f_adjective, f_speed)
	
	haskey(db.facilities, name(f)) &&
		error("duplicate facility name: ", repr(name(f)))
	category(f) in db.facilitycategories ||
		error("unknown facility category: ", repr(categoryname(f)))
	
	db.facilities[name(f)] = f
	db
end

function _loadfacilitiesdata!(db::DataBase, tomlfilename::AbstractString)
	
	tomltable = TOML.parsefile(tomlfilename)
	
	for categorydata in tomltable["facility categories"]
		_loaddata!(db, FacilityCategory, categorydata)
	end
	
	for facilitydata in tomltable["facilities"]
		_loaddata!(db, Facility, facilitydata)
	end
	
	db
end


###################################
# Products Data Loading Functions #
###################################

function _loaddata!(db::DataBase, ::Type{Product}, tomldata::String)
	
	p_name = tomldata
	
	p = Product(p_name)
	
	p in db.products && 
			error("duplicate product name: ", repr(name(p)))
	
	push!(db.products, p)
	db
end

function _loadproductsdata!(db::DataBase, tomlfilename::AbstractString)
	
	tomltable = TOML.parsefile(tomlfilename)
	
	for productdata in tomltable["products"]
		_loaddata!(db, Product, productdata)
	end
	
	db
end


##################################
# Recipes Data Loading Functions #
##################################

# Implementations of readrecipe() and readrecipefile() are in recipereaders.jl

function _loaddata!(db::DataBase, ::Type{Recipe},
	recipedata::AbstractVector{<:AbstractString})
	
	recipeblock = recipedata
	
	r = readrecipe(recipeblock) :: Recipe
	
	haskey(db.recipes, name(r)) &&
		error("duplicate recipe name: ", repr(name(r)))
	
	db.recipes[name(r)] = r
	db
end

function _loadrecipesdata!(db::DataBase, datafilename::AbstractString)
	
	# Pass in the database so it can be used to resolve abbreviations
	recipetable = readrecipefile(datafilename, db)
	
	for recipedata in recipetable
		_loaddata!(db, Recipe, recipedata)
	end
	
	db
end

################################
# Rates Data Loading Functions #
################################

function _loaddata!(db::DataBase, ::Type{Rate}, tomldata::Pair{String, Any})
	
	ratename = tomldata.first
	r_persecond = tomldata.second :: Int
	
	r = Rate(r_persecond)
	
	haskey(db.rates, ratename) &&
		error("duplicate rate name: ", repr(ratename))
	
	db.rates[ratename] = r
	db
end

function _loaddata!(db::DataBase, ::Type{Time}, tomldata::Pair{String, Any})
	
	timename = tomldata.first
	t_seconds = tomldata.second :: Int
	
	ratename = string("/", timename)
	
	t = Time(t_seconds)
	r = Rate(t)
	
	haskey(db.times, timename) && 
		error("duplicate time name: ", repr(timename))
	haskey(db.rates, ratename) &&
		error("duplicate rate name was generated: ", repr(ratename))
	
	db.times[timename] = t
	db.rates[ratename] = r
	db
end

function _loadratesdata!(db::DataBase, tomlfilename::AbstractString)
	
	tomltable = TOML.parsefile(tomlfilename)
	
	for ratedata in tomltable["rates"]
		_loaddata!(db, Rate, ratedata)
	end
	
	for timedata in tomltable["times"]
		_loaddata!(db, Time, timedata)
	end
	
	db
end


#######################################
# Top-Level DataBase Loading Function #
#######################################

function loaddatabase!(db::DataBase)
	
	print("Loading contents of DataBase from files...")
	flush(stdout)
	
	_loadfacilitiesdata!(db, FACILITIESFILENAME)
	_loadproductsdata!(db, PRODUCTSFILENAME)
	_loadrecipesdata!(db, RECIPESFILENAME)
	_loadratesdata!(db, RATESFILENAME)
	
	println(" done!")
	db
end

