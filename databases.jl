# databases.jl
# Database type for reading, storing, and supplying all forms of DSP game data


#######################################
# DataBase Type and Inner Constructor #
#######################################

struct DataBase
	
	facilitycategories::Set{FacilityCategory}
	facilities::Dict{String, Facility}
	
	products::Set{Product}
	
	recipes::Dict{String, Recipe}
	
	rates::Dict{String, Rate}
	times::Dict{String, Time}
	
	lookuptable_facilities::Dict{FacilityCategory, Set{Facility}}
	lookuptable_recipes::Dict{Product, Set{Recipe}}
	
	function DataBase()
		# This is either really clever or really bad practice... not sure...
		# I just want to concisely initialize with every data structure empty
		new((FieldType() for FieldType in fieldtypes(DataBase))...)
	end
end


###############################
# Lookup Table Initialization #
###############################

function _maketable_facilities(db::DataBase)
	
	for facility in values(db.facilities)
		if !haskey(db.lookuptable_facilities, category(facility))
			db.lookuptable_facilities[category(facility)] = Set{Facility}()
		end
		push!(db.lookuptable_facilities[category(facility)], facility)
	end
	
	db
end

function _maketable_recipes(db::DataBase)
	
	for recipe in values(db.recipes)
		for quantity in outputs(recipe)
			if !haskey(db.lookuptable_recipes, product(quantity))
				db.lookuptable_recipes[product(quantity)] = Set{Recipe}()
			end
			push!(db.lookuptable_recipes[product(quantity)], recipe)
		end
	end
	
	db
end

function maketables!(db::DataBase)
	
	print("Making lookup tables for DataBase...")
	flush(stdout)
	
	_maketable_facilities(db)
	_maketable_recipes(db)
	
	println(" done!")
	db
end


############################
# DataBase Query Functions #
############################

function findfacilities(db::DataBase, category::FacilityCategory)
	get!(Set{Facility}, db.lookuptable_facilities, category)
end

function findfacilities(db::DataBase, categoryname::AbstractString)
	findfacilities(db, FacilityCategory(categoryname))
end

function findfacilities(db::DataBase, recipe::Recipe)
	findfacilities(db, category(recipe))
end

function findrecipes(db::DataBase, recipeoutput::Product)
	get!(Set{Recipe}, db.lookuptable_recipes, recipeoutput)
end

function findrecipes(db::DataBase, recipeoutputname::AbstractString)
	findrecipes(db, Product(recipeoutputname))
end

