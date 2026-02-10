# groups.jl
# 


# collection -- can contain 0, 1, or more values
# homogenous -- getting values is type stable
# immutable -- constant length, no setindex!(), immutable values
# iterable -- can retrieve elements via for loop
# unordered -- order unimportant for == comparsions
# not a set, can have mutliple copies of a given value
# i think what i want is a homogeneous frozen multiset


####
#
####

struct GroupNode{T}
	data::T
	next::Union{GroupNode{T}, Nothing}
	
	function GroupNode(data::T, next::Union{GroupNode{T}, Nothing}) where T
		new{T}(data, next)
	end
	#GroupNode(data::T) where T = new{T}(data, nothing)
end

datanext(node::GroupNode) = (node.data, node.next)
datanext(::Nothing) = nothing

struct Group{T}
	len::Int
	head::Union{GroupNode{T}, Nothing}
	
	function Group(collection)
		
		T = eltype(collection)
		isconcretetype(T) || error("group eltype must be concrete")
		isimmutable(T) || error("group eltype must be immutable")
		
		node::Union{GroupNode{T}, Nothing} = nothing
		len = 0
		for element in collection
			node = GroupNode(element, node)
			len += 1
		end
		
		new{T}(len, node)
	end
end

Base.iterate(group::Group) = datanext(group.head)
function Base.iterate(::Group{T}, state::Union{GroupNode{T}, Nothing}) where T
	datanext(state)
end

Base.IteratorSize(::Type{Group}) = HasLength()
Base.IteratorEltype(::Type{Group}) = HasEltype()
Base.eltype(::Type{Group{T}}) where T = T
Base.length(group::Group) = group.len

Base.isempty(group::Group) = group.len == 0





