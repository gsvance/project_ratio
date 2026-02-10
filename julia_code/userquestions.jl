# userquestions.jl
# Functions for acquiring a few types of terminal input from the user


using REPL.TerminalMenus


###############################################
# Ask User to Pick One Item from a Collection #
###############################################

# The null choice is the text label for choosing "none of these options"
# If the user selects the null choice or quits the menu, then return nothing
function getuserchoice(message::AbstractString, choicescollection,
	nullchoice::AbstractString; sortby::Union{Function, Nothing} = nothing)
	
	isempty(choicescollection) && return nothing
	
	ElType = eltype(choicescollection)
	orderedchoices = ElType[choice for choice in choicescollection]
	isnothing(sortby) || sort!(orderedchoices, by = sortby)
	
	strings = String[string(choice) for choice in orderedchoices]
	push!(strings, nullchoice)
	
	menu = RadioMenu(strings, pagesize = 20)
	println()
	index = request(message, menu)
	
	if index == -1 || index == lastindex(strings)
		return nothing
	else
		return orderedchoices[index]
	end
end


###########################################
# Ask User to Answer a Yes or No Question #
###########################################

# Return a Bool indicating whether the user answered "yes" to the question
# If the user quits the menu, return the default value, which is usually "no"
function getuserbool(question::AbstractString, default::Bool = false)
	
	strings = String["yes", "no"]
	
	menu = RadioMenu(strings)
	println()
	index = request(question, menu)
	
	index == -1 ? default : strings[index] == "yes"
end


################################################
# Ask User to Enter a Line of Text for Parsing #
################################################

# Ask the user to enter a line of text until it passes some given parse test
# Prompt with a message, then pass the input string to the parser function
# Repeat until the parser returns not nothing, then return whatever it gave
# By default, just return whatever the first string is that the user enters
function getusertext(message::AbstractString, parser::Function = identity)
	
	parsevalue = nothing
	
	while true
		println()
		print(message)
		parsevalue = parser(readline())
		isnothing(parsevalue) || break
	end
	
	parsevalue
end

