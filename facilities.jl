# facilities.jl
# Types for representing production buildings and building classes from DSP


########################################
# FacilityCategory Type Implementation #
########################################

struct FacilityCategory
	name::String
	
	function FacilityCategory(name::AbstractString)
		cleanedname = strip(name)
		isempty(cleanedname) &&
			error("facility category name empty or all whitespace")
		new(string(cleanedname))
	end
end

name(fc::FacilityCategory) = fc.name

Base.show(io::IO, fc::FacilityCategory) = print(io, name(fc))


################################
# Facility Type Implementation #
################################

struct Facility
	category::FacilityCategory
	adjective::String
	speed::Rational{Int}
end

function Facility(categoryname::AbstractString, adjective::AbstractString,
	speed::Real)
	
	Facility(FacilityCategory(categoryname), adjective, speed)
end

category(f::Facility) = f.category
speed(f::Facility) = f.speed

function name(f::Facility)
	if isempty(f.adjective)
		return string(f.category)
	else
		return string(f.adjective, " ", f.category)
	end
end

function Base.show(io::IO, f::Facility)
	print(io, name(f))
	print(io, " (")
	print(io, prettystring(speed(f)))
	print(io, "x)")
end

