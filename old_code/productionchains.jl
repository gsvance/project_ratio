# productionchains.jl
# Code for manipulating graph representations of DSP production chains

# The contents of this file are supposedly the point of this entire project
# It took me quite a while to actually get around to filling up this file
# Turns out it needs a lot of supporting code to really get anywhere at all

# Production node representing an actual group of buildings crafting a recipe
struct RecipeNodeData
	recipe::Recipe
	building::Facility
	howmany::Rational{Int}
	# TODO: add proliferator stuff eventually
end

# Source nodes opaquely output a particular product at a particular rate
# This can later be expanded into a full-on recipe node with the desired output
# However, we can only do that expansion if a suitable recipe exists
# Some supply nodes we may not want to expand further -- mark those with a flag
struct SupplyNodeData
	supplies::Product
	productionrate::Rate
	preventexpansion::Bool
end

function SupplyNodeData(supplies::Product, productionrate::Rate)
	SupplyNodeData(supplies, productionrate, false)
end

# Sink nodes opaqely consume a particular input at a particular rate
# One demand node marked as primary is the ultimate goal of the production line
struct DemandNodeData
	demands::Product
	consumptionrate::Rate
	primary::Bool
end

function DemandNodeData(demands::Product, consumptionrate::Rate)
	DemandNodeData(demands, consumptionrate, false)
end

# Splitter nodes have one or more inputs and outputs of the same product
# The only rule is that the sum of the inputs must equal the sum of the outputs
struct SplitterNodeData
	cargo::Product
	totalrate::Rate
	outputrates::Vector{Rate}
	inputrates::Vector{Rate}
	
	function SplitterNodeData(cargo::Product, totalrate::Rate,
		outputrates::Vector{Rate}, inputrates::Vector{Rate})
		
		_verifysplitter(totalrate, outputrates, inputrates)
		new(cargo, totalrate, outputrates, inputrates)
	end
end

function _verifysplitter(totalrate::Rate, outputrates::Vector{Rate},
	inputrates::Vector{Rate})
	
	(sum(outputrates) == totalrate && sum(inputrates) == totalrate) ||
		error("encountered splitter node verification failure")
end

function _verifysplitter(snd::SplitterNodeData)
	_verifysplitter(snd.totalrate, snd.outputrates, snd.inputrates)
end

# Nodes can be recipe nodes, source "supply" nodes, or sink "demand" nodes
NodeData = Union{RecipeNodeData, SupplyNodeData, DemandNodeData, SplitterNodeData}

# Graph edges are basically just conveyor belts
struct EdgeData
	cargo::Product
	throughput::Rate
	# TODO: add proliferator stuff eventually
end

ProductionChain = Graph{NodeData, EdgeData}

struct NodeRates
	outward::Dict{Product, Vector{Rate}}
	inward::Dict{Product, Vector{Rate}}
end

function NodeRates()
	NodeRates(Dict{Product, Vector{Rate}}(), Dict{Product, Vector{Rate}}())
end

function calculatenoderates(nodedata::DemandNodeData)::NodeRates
	nr = NodeRates()
	nr.inward[nodedata.demands] = [nodedata.consumptionrate]
	return nr
end

function calculatenoderates(nodedata::SupplyNodeData)::NodeRates
	nr = NodeRates()
	nr.outward[nodedata.supplies] = [nodedata.productionrate]
	return nr
end

function calculatenoderates(nodedata::RecipeNodeData)::NodeRates
	
	nr = calculatenoderates(nodedata.recipe)
	modifier = nodedata.building.productionspeed * nodedata.howmany
	
	for outputproduct in keys(nr.outward)
		nr.outward[outputproduct] .*= modifier
	end
	
	for inputproduct in keys(nr.inward)
		nr.inward[inputproduct] .*= modifier
	end
	
	return nr
end

function calculatenoderates(noderecipe::Recipe)::NodeRates
	
	nr = NodeRates()
	
	for outputquantity in noderecipe.outputs
		outputrate = outputquantity.number / noderecipe.period
		nr.outward[outputquantity.item] = [outputrate]
	end
	
	for inputquantity in noderecipe.inputs
		inputrate = inputquantity.number / noderecipe.period
		nr.inward[inputquantity.item] = [inputrate]
	end
	
	return nr
end

function calculatenoderates(nodedata::SplitterNodeData)::NodeRates
	nr = NodeRates()
	nr.outward[nodedata.cargo] = copy(nodedata.outputrates)
	nr.inward[nodedata.cargo] = copy(nodedata.inputrates)
	return nr
end

function Base.show(io::IO, rnd::RecipeNodeData)
	print(io, "Group of ")
	if denominator(rnd.howmany) == 1
		print(io, numerator(rnd.howmany))
	else # rnd.howmany is not a whole number
		print(io, round(rnd.howmany, digits = 2))
	end
	print(io, " ")
	print(io, facilityname(rnd.building))
	print(io, " crafting ")
	print(io, rnd.recipe.name)
end

function Base.show(io::IO, snd::SupplyNodeData)
	print(io, "Supply of ", snd.supplies, " at ", snd.productionrate)
	snd.preventexpansion && print(io, " (expansion prevented)")
end

function Base.show(io::IO, dnd::DemandNodeData)
	print(io, "Demand for ", dnd.demands, " at ", dnd.consumptionrate)
	dnd.primary && print(io, " (primary demand)")
end

function Base.show(io::IO, snd::SplitterNodeData)
	print(io, "Splitting ", snd.cargo, " at ", snd.totalrate, " total")
end

function Base.show(io::IO, ed::EdgeData)
	print(io, "Carrying ", ed.cargo, " at ", ed.throughput)
end

function Base.show(io::IO, nr::NodeRates)
	
	indent = " " ^ 2
	
	print(io, "NodeRates tabulation:")
	
	print(io, "\n", indent, "Outward rates (", length(nr.outward), "):")
	for (outwardproduct, outwardrate) in nr.outward
		print(io, "\n", indent ^ 2, outwardproduct, " at ")
		if length(outwardrate) == 1
			print(io, only(outwardrate))
		else # outwardrate is a vector with multiple elements
			print(io, outwardrate)
		end
	end
	
	print(io, "\n", indent, "Inward rates (", length(nr.inward), "):")
	for (inwardproduct, inwardrate) in nr.inward
		print(io, "\n", indent ^ 2, inwardproduct, " at ")
		if length(inwardrate) == 1
			print(io, only(inwardrate))
		else # inwardrate is a vector with multiple elements
			print(io, inwardrate)
		end
	end
end

function adddemandnode!(pc::ProductionChain, nodename::Int, dnd::DemandNodeData)
	addnode!(pc, nodename)
	setnodedata!(pc, nodename, dnd)
end

function addsupplynode!(pc::ProductionChain, nodename::Int, snd::SupplyNodeData)
	addnode!(pc, nodename)
	setnodedata!(pc, nodename, snd)
end

function addrecipenode!(pc::ProductionChain, nodename::Int, rnd::RecipeNodeData)
	addnode!(pc, nodename)
	setnodedata!(pc, nodename, rnd)
end

function addconnection!(pc::ProductionChain, fromnode::Int, tonode::Int,
	ed::EdgeData)
	
	fromnoderates = calculatenoderates(getnodedata(pc, fromnode))
	tonoderates = calculatenoderates(getnodedata(pc, tonode))
	
	haskey(fromnoderates.outward, ed.cargo) ||
		error("node $(fromnode) has no connectable output")
	haskey(tonoderates.inward, ed.cargo) ||
		error("node $(tonode) has no connectable input")
	
	ed.throughput in fromnoderates.outward[ed.cargo] ||
		error("node $(fromnode) output rate does not match")
	ed.throughput in tonoderates.inward[ed.cargo] ||
		error("node $(tonode) input rate does not match")
	
	conflictedges = union(outgoingedges(pc, fromnode),
		incomingedges(pc, tonode))
	newedge = (fromnode, tonode)
	
	for conflictedge in conflictedges
		conflicttail, conflicthead = conflictedge
		conflictdata = getedgedata(pc, conflicttail, conflicthead)
		conflictdata == ed &&
			error("adding edge $(newedge) conflicts with $(conflictedge)")
	end
	
	addedge!(pc, fromnode, tonode)
	setedgedata!(pc, fromnode, tonode, ed)
end

function splitconnection!(pc::ProductionChain, fromnode::Int, tonode::Int,
	splitnodename::Int)
	
	edgedata = getedgedata(pc, fromnode, tonode)
	
	deleteedge!(pc, fromnode, tonode)
	
	addnode!(pc, splitnodename)
	setnodedata!(pc, splitnodename,
		SplitterNodeData(edgedata.cargo, edgedata.throughput))
	
	addconnection!(pc, fromnode, splitnodename, edgedata)
	addconnection!(pc, splitnode, tonode, edgedata)
end

function beginproductionchain(goalproduct::Product, goalproductionrate::Rate)
	
	pc = ProductionChain()
	
	# Create the primary demand node for the production chain
	demandnode = imaginenewnodename(pc)
	adddemandnode!(pc, demandnode,
		DemandNodeData(goalproduct, goalproductionrate, true))
	
	# Create an initial supply node to satisfy the primary demand
	supplynode = imaginenewnodename(pc)
	addsupplynode!(pc, supplynode,
		SupplyNodeData(goalproduct, goalproductionrate, false))
	
	# Connect the output of the supply node to the input of the demand node
	addconnection!(pc, supplynode, demandnode,
		EdgeData(goalproduct, goalproductionrate))
	
	return pc
end

function promptuserchoice(subject::AbstractString,
	choices::Vector{T})::T where T
	
	length(choices) == 1 && return only(choices)
	
	println("USER CHOICE REQUIRED -- ", subject)
	
	for (index, choice) in enumerate(choices)
		println("  ", index, ": ", choice)
	end
	
	print("Please enter your choice: ")
	choiceindex = parse(Int, readline())
	
	println("  ", choices[choiceindex], " selected!")
	println()
	
	return choices[choiceindex]
end

function deciderecipe(output::Product, db::DataBase)::Union{Recipe, Nothing}
	
	choices = findrecipesbyoutput(db, output)
	norecipe = "<no recipe>"
	
	choicesvector = collect(keys(choices))
	sort!(choicesvector)
	push!(choicesvector, norecipe)
	
	subject = string(output, " Recipe")
	recipename = promptuserchoice(subject, choicesvector)
	
	if !(recipename == norecipe)
		return choices[recipename]
	else
		return nothing
	end
end

function decidefacility(category::FacilityCategory, db::DataBase)::Facility
	
	choices = findfacilitiesbycategory(db, category)
	
	choicesvector = collect(keys(choices))
	sort!(choicesvector)
	
	subject = string(category, " Type")
	facilityname = promptuserchoice(subject, choicesvector)
	
	choices[facilityname]
end

function expandsupplynode!(pc::ProductionChain, nodename::Int, db::DataBase)
	
	supplynodedata = getnodedata(pc, nodename)
	
	supplynodedata isa SupplyNodeData ||
		error("cannot expand node $(nodename) is not a supply node")
	supplynodedata.preventexpansion &&
		error("node $(nodename) has expansion prevented")
	
	supplies = supplynodedata.supplies
	productionrate = supplynodedata.productionrate
	
	recipe = deciderecipe(supplies, db)
	if recipe === nothing
		# Mark the supply node as not expandable
		setnodedata!(pc, nodename,
			SupplyNodeData(supplies, productionrate, true))
		return
	end
	
	building = decidefacility(recipe.madein, db)
	
	reciperates = calculatenoderates(recipe)
	howmany = productionrate /
		(building.productionspeed * reciperates.outward[supplies])
	
	setnodedata!(pc, nodename, RecipeNodeData(recipe, building, howmany))
	
	noderates = calculatenoderates(getnodedata(pc, nodename))
	
	for (output, outputrate) in noderates.outward
		output == supplies && continue
		demandnode = imaginenewnodename(pc)
		adddemandnode!(pc, demandnode, DemandNodeData(output, outputrate))
		addconnection!(pc, nodename, demandnode, EdgeData(output, outputrate))
	end
	
	for (input, inputrate) in noderates.inward
		supplynode = imaginenewnodename(pc)
		addsupplynode!(pc, supplynode, SupplyNodeData(input, inputrate))
		addconnection!(pc, supplynode, nodename, EdgeData(input, inputrate))
	end
	
	return
end

function expandentirechain!(pc::ProductionChain, db::DataBase)
	
	while true
		allnodes = nodeset(pc)
		
		nextexpand::Union{Int, Nothing} = nothing
		for nodename in allnodes
			nodedata::NodeData = getnodedata(pc, nodename)
			if nodedata isa SupplyNodeData && !(nodedata.preventexpansion)
				nextexpand = nodename
				break
			end
		end
		
		if !(nextexpand === nothing)
			expandsupplynode!(pc, nextexpand, db)
			continue
		end
		
		break
	end
	
	return pc
end

