# algorithms.jl
# Various smart functions for expanding factory plans in steps


###########################################
# Decisions that are Deferred to the User #
###########################################

# Utility return type for makeexpanddecision() function
struct ExpandDecision
	newcrafter::Bool
	argument::Any
end

function makeexpanddecision(factory::Factory, db::DataBase, p::Product)
	
	existingcrafters = findcrafters(factory, p)
	possiblerecipes = findrecipes(db, p)
	
	newcrafter = Dict{String, Bool}()
	args = Dict{String, Any}()
	
	for crafter in existingcrafters
		str = string("Expand Crafter: ", crafter)
		newcrafter[str] = false
		args[str] = crafter
	end
	
	for recipe in possiblerecipes
		str = string("New Crafter: ", name(recipe))
		newcrafter[str] = true
		args[str] = recipe
	end
	
	options = keys(newcrafter)
	chosenstring = getuserchoice("Choose how to produce $(p):", options,
		"<ignore this product>", sortby = identity)
	
	if isnothing(chosenstring)
		return nothing
	else
		return ExpandDecision(newcrafter[chosenstring], args[chosenstring])
	end
end

function makefacilitydecision(db::DataBase, recipe::Recipe)
	
	possiblefacilities = findfacilities(db, recipe)
	
	if length(possiblefacilities) > 1
		return getuserchoice("Select a facility to craft $(name(recipe)):",
			possiblefacilities, "<nevermind, ignore this product>",
			sortby = speed)
	else
		return only(possiblefacilities)
	end
end

function makegoaldecision(db::DataBase)
	
	item = getuserchoice("Choose the product this factory should yield:",
		db.products, "<quit program>", sortby = name)
	isnothing(item) && return nothing
	
	persecond = getusertext("Enter desired production rate (per second): ",
		tryreadrational)
	rate = Rate(persecond)
	
	# TODO: ask if we want the output product to be proliferated
	
	return ProductQuantity(rate, item)
end

function makeproductiondecision(factory::Factory, db::DataBase)
	
	possibletargets = findproductiongaps(factory, db)
	
	if isempty(possibletargets)
		return nothing
	else
		return getuserchoice("Choose next production target to satisfy:",
			possibletargets, "<ignore all and finish>", sortby = name)
	end
end

####################################
# Algorithms for Factory Expansion #
####################################

function findproductiongaps(factory::Factory, db::DataBase)
	
	possiblegaps = negativerates(factory)
	verifiedgaps = Vector{ProductQuantity{Rate}}()
	
	for (product, rate) in possiblegaps
		if isempty(findrecipes(db, product))
			setignored!(factory, product)
		else
			push!(verifiedgaps, ProductQuantity(-rate, product))
		end
	end
	
	verifiedgaps
end

function expandfactoryonce!(factory::Factory, db::DataBase,
	objective::ProductQuantity{Rate})
	
	expanddecision = makeexpanddecision(factory, db, product(objective))
	
	if isnothing(expanddecision)
		setignored!(factory, product(objective))
		return factory
	end
	
	if expanddecision.newcrafter  # Make a new crafter
		
		recipe = expanddecision.argument :: Recipe
		facility = makefacilitydecision(db, recipe)
		
		if isnothing(facility)
			setignored!(factory, product(objective))
			return factory
		end
		
		newcrafter = RecipeCrafter(recipe, facility, objective)
		connectcrafter!(factory, newcrafter)
	
	else # Expand an existing crafter
		
		crafter = expanddecision.argument :: RecipeCrafter
		upgradecrafter!(factory, crafter, objective)
	
	end
	
	return factory
end

function generatefactory(db::DataBase)
	
	goal = makegoaldecision(db)
	isnothing(goal) && return nothing
	factory = Factory(goal)
	
	while true
		target = makeproductiondecision(factory, db)
		if isnothing(target)
			setallignored!(factory)
			break
		else
			expandfactoryonce!(factory, db, target)
		end
	end
	
	factory
end

