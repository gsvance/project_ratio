# ports.jl
# 



abstract type Port end

mutable struct InputPort <: Port
	cargo::ProductQuantity{Rate}
	owner
	link::Union{OutputPort, Nothing}
end

mutable struct OutputPort <: Port
	cargo::ProductQuantity{Rate}
	owner
	link::Union{InputPort, Nothing}
end

#mutable struct Link
#	a::OutputPort
#	b::InputPort
#end

cargo(p::Port) = p.cargo
owner(p::Port) = p.owner
link(p::Port) = p.link

_directionstring(ip::InputPort) = "Input"
_directionstring(op::OutputPort) = "Output"

function Base.show(io::IO, p::Port)
	print(io, _directionstring(p), "Port(")
	print(io, product(cargo(p)), " at ")
	print(io, quantity(cargo(p)), ", ")
	print(io, isnothing(link(p)) ? "unlinked" : "linked")
	print(io, ")")
end

