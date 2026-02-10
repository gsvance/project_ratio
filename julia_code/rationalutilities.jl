# rationalutilities.jl
# Utilities for picky methods of input and output involving rationals


#############################
# Rational Output Utilities #
#############################

const PRETTYDIGITS = 2

function prettystring(r::Real)
	if isinteger(r)
		return string(convert(Integer, r))
	else
		return string(round(r, digits = PRETTYDIGITS))
	end
end


############################
# Rational Input Utilities #
############################

const RATIONALREGEX = r"^ *([-+]?) *([0-9]+) */{1,2} *([0-9]+) *$"

# This implementation with all the trial-and-error branching is a bit hacky
# It ought to work okay -- a better implementation would involve more regexes
# TODO: implement a better version of this function with all the picky details
function tryreadrational(str::AbstractString)
	
	m = match(RATIONALREGEX, str)
	if !isnothing(m)
		r = parse(Int, m[2]) // parse(Int, m[3])
		return m[1] == "-" ? -r : r
	end
	
	i = tryparse(Int, str)
	if !isnothing(i)
		return i // one(i)
	end
	
	f = tryparse(Float64, str)
	if !isnothing(f)
		return rationalize(Int, f)
	end
	
	return nothing
end

function readrational(str::AbstractString)
	r = tryreadrational(str)
	isnothing(r) &&
		error("string ", repr(str), " could not be read as a rational")
	r
end

