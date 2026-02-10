# rates.jl
# Simple types for representing measurements with dimensions of time or 1/time

# TODO: add functions for parsing times and rates from strings with units
# TODO: add functions for outputing times and rates with converted units


# I want to keep rates and times rational, so they should avoid float math
# This is "a rational" as defined in math class, i.e., the infinite set Q
const IntegerOrRational = Union{Integer, Rational}


############################
# Time Type Implementation #
############################

struct Time <: Number
	seconds::Rational{Int}
end

Base.show(io::IO, t::Time) = print(io, prettystring(t.seconds), "s")

Base.zero(::Time) = Time(0 // 1)
Base.:<(t1::Time, t2::Time) = t1.seconds < t2.seconds

Base.:-(t::Time) = Time(-t.seconds)

Base.:+(t1::Time, t2::Time) = Time(t1.seconds + t2.seconds)
Base.:-(t1::Time, t2::Time) = Time(t1.seconds - t2.seconds)

Base.:*(x::IntegerOrRational, t::Time) = Time(x * t.seconds)
Base.:*(t::Time, x::IntegerOrRational) = Time(t.seconds * x)

Base.:/(t::Time, x::IntegerOrRational) = Time(t.seconds // x)
Base.:/(t1::Time, t2::Time) = t1.seconds // t2.seconds


############################
# Rate Type Implementation #
############################

struct Rate <: Number
	persecond::Rational{Int}
end

Base.show(io::IO, r::Rate) = print(io, prettystring(r.persecond), "/s")

Base.zero(::Rate) = Rate(0 // 1)
Base.:<(r1::Rate, r2::Rate) = r1.persecond < r2.persecond

Base.:-(r::Rate) = Rate(-r.persecond)

Base.:+(r1::Rate, r2::Rate) = Rate(r1.persecond + r2.persecond)
Base.:-(r1::Rate, r2::Rate) = Rate(r1.persecond - r2.persecond)

Base.:*(x::IntegerOrRational, r::Rate) = Rate(x * r.persecond)
Base.:*(r::Rate, x::IntegerOrRational) = Rate(r.persecond * x)

Base.:/(r::Rate, x::IntegerOrRational) = Rate(r.persecond // x)
Base.:/(r1::Rate, r2::Rate) = r1.persecond // r2.persecond


###############################
# Time-Rate Type Interactions #
###############################

Rate(t::Time) = Rate(inv(t.seconds))
Time(r::Rate) = Time(inv(r.persecond))

Base.:/(x::IntegerOrRational, t::Time) = x * Rate(t)
Base.:/(x::IntegerOrRational, r::Rate) = x * Time(r)

Base.:*(t::Time, r::Rate) = t.seconds * r.persecond
Base.:*(r::Rate, t::Time) = r.persecond * t.seconds

