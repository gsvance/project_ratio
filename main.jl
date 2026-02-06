#!/usr/bin/env julia
# main.jl
# The top-level executable code for my DSP production chains project


################################
# All Includes for the Project #
################################

# General utilities
include("rationalutilities.jl")
include("userquestions.jl")

# Types for representing DSP game concepts
include("rates.jl")
include("facilities.jl")
include("products.jl")
include("recipes.jl")
#include("proliferators.jl")

# DataBase code for loading data and making queries
include("databases.jl")
include("abbreviations.jl")
include("recipereaders.jl")
include("dataloaders.jl")

# Factories and algorithms for manipulating them based on user input
include("factories.jl")
include("algorithms.jl")


##################################
# Important Subroutines for Main #
##################################

function createdatabase()
	
	db = DataBase()
	
	println()
	loaddatabase!(db)
	maketables!(db)
	
	db
end


#####################################
# Main Function Declared and Called #
#####################################

function main()
	
	db = createdatabase()
	
	while true
		factory = generatefactory(db)
		isnothing(factory) && break
		print("\n\n")
		display(factory)
		println()
		readline()
	end
	
	return
end

main()

