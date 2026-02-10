# abbreviations.jl
# This file defines "abbreviations" and tells Julia how to interpret them


###############################
# Abbreviation Implementation #
###############################

# Abbreviation Standard:
# Construct an abbreviation of a string by deleting all characters that are not
# uppercase letters. To get around conflicts when two strings would produce the
# same sequence of uppercase letters, I may optionally choose to NOT delete one
# or more lowercase letters in the string. The remaining letters must always
# appear in the same order as in the original string. An empty string is not a
# valid abbreviation. The optional inclusion of arbitrarily chosen lowercase
# letters means that I cannot write a function to *generate* abbreviations,
# but that's okay. The code doesn't need to produce abbreviations, it just
# needs to be able to unambiguously interpret the ones I invent so that the
# recipes file can be a little less verbose.

struct Abbreviation
	str::String
	re::Regex
	
	function Abbreviation(str::AbstractString)
		
		isempty(str) && error("empty abbreviation string")
		all(isletter, str) ||
			error("non-alphabetic abbreviation string: ", repr(str))
		
		NONCAPITALS = "[^A-Z]*"  # Zero or more deletable characters in a row
		re = Regex(join("^$(str)\$", NONCAPITALS))
		
		new(string(str), re)
	end
end

function abbreviates(abbrev::Abbreviation, longstring::AbstractString)
	occursin(abbrev.re, longstring)
end


#######################################
# AbbreviationResolver Implementation #
#######################################

struct AbbreviationResolver
	stringcollection::Set{String}
	lookuptable::Dict{String, String}
	
	function AbbreviationResolver(stringcollection)
		new(Set{String}(stringcollection), Dict{String, String}())
	end
end

function _resolveabbreviation(resolver::AbbreviationResolver,
	abbrev::Abbreviation)
	
	possiblematches = Set{String}()
	for longstring in resolver.stringcollection
		abbreviates(abbrev, longstring) && push!(possiblematches, longstring)
	end
	
	if length(possiblematches) != 1
		if length(possiblematches) > 1
			error("too many strings match abbreviation: ", repr(abbrev.str),
				" => ", [m for m in possiblematches])
		else
			error("found no strings matching abbreviation: ", repr(abbrev.str))
		end
	end
	
	only(possiblematches)
end

function (resolver::AbbreviationResolver)(abbrev_str::AbstractString)
	get!(resolver.lookuptable, abbrev_str) do
		_resolveabbreviation(resolver, Abbreviation(abbrev_str))
	end
end

