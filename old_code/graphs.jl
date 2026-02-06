# graphs.jl
# Implementation of a graph with nodes, edges, and associated data values

# This file contains a general-purpose directed graph implementation
# I'm using the standard adjacency list representation for this one
# The nodes and edges of the graph can both have data associated with them
# The Graph is a parameterized type so that you can pick the data types
# This all is a bit overkill for what I'm trying to ultimately accomplish...
# ...but what the heck, I learned some stuff about Julia along the way

# NO NO NO NO NO
# What are the actual things that I need from my graph representation?
# Fast performance for the following functions:
#  - Some system for assigning names to nodes (not exactly a function)
#    - Maybe use a dict for this purpose if I want arbitrary node names
#    - Otherwise, just name them with a bunch of small ints
#    - The dict could fit either implementation, but works better with lists
#  - Add a new node
#    - Slow for a matrix, but fast for lists
#  - Add a new edge
#    - Fast for either implementation
#  - Retrieve node/edge data
#    - Either implementation could make this fast with separate storage
#  - Make changes to node/edge data
#    - Either implementation could make this fast with separate storage
#  - Print... I dunno... some representation of the graph
#    - Not sure what to say here
#  - Find all edges going out of a node (list of neighbor nodes)
#    - Fast for lists, slow for matrix
#  - Find all edges going into a node (list of nodes that have this neighbor)
#    - Slow for lists and matrix, but could make lists fast with extra lists
#  - Support for source and sink nodes (possibly)
#    - Probably handled in either implementation by node data anyway...
#  - Memory usage isn't really a concern for me (not a function)
#    - Won't need to evaluate graph sparsity for either implementation

# I think we want the adjacency list representation here
# The matrix makes adding nodes take too long
# The matrix makes finding all neighbors take too long
# The list can be made to make neighbors fast in both directo=ions
# The matrix is good at checking for adjacency, but I don't need that
# The list (implemented using sets) can check adjacency quickly too

# Adjacency list graph struct with support for node and edge data of any type
# Includes secondary adjacency list for finding nodes with *incoming* edges
struct Graph{NodeDataType, EdgeDataType}
	outgoing::Dict{Int, BitSet}  # Standard adjacency list
	incoming::Dict{Int, BitSet}  # Secondary list for oppositely directed edges
	nodedata::Dict{Int, NodeDataType}  # Separate storage for node data
	edgedata::Dict{Tuple{Int, Int}, EdgeDataType}  # Storage for edge data
end

# Graph constructor without any arguments, all dicts are initialized empty
function Graph{NDT, EDT}() where {NDT, EDT}
	Graph{NDT, EDT}(Dict{Int, BitSet}(), Dict{Int, BitSet}(),
		Dict{Int, NDT}(), Dict{Tuple{Int, Int}, EDT}())
end

# Return whether G contains a node with the given nodename
function hasnode(G::Graph, nodename::Int)::Bool
	haskey(G.outgoing, nodename)
end

# Return whether G contains an edge connecting tailnode to headnode
# Raise an error if either of the specified nodes does not exist
function hasedge(G::Graph, tailnode::Int, headnode::Int)::Bool
	hasnode(G, tailnode) || error("tail node $tailnode does not exist")
	hasnode(G, headnode) || error("head node $headnode does not exist")
	headnode in G.outgoing[tailnode]
end

# Check whether G contains a node called nodename
# Raise an error if the result does not match the assertion
# (this is something of an internal function)
function _testfornode(G::Graph, nodename::Int, assertion::Bool)
	if hasnode(G, nodename) == assertion
		return
	else
		if assertion
			error("node $nodename does not exist")
		else
			error("node $nodename already exists")
		end
	end
end

# Check (internally) whether G contains an edge from tailnode to headnode
# Raise an error if the result does not match the assertion
# (this is something of an internal function)
function _testforedge(G::Graph, tailnode::Int, headnode::Int, assertion::Bool)
	if hasedge(G, tailnode, headnode) === assertion
		return
	else
		if assertion
			error("edge from node $tailnode to $headnode does not exist")
		else
			error("edge from node $tailnode to $headnode already exists")
		end
	end
end

# Add a new node to G called nodename
# Raise an error if the node already exists
function addnode!(G::Graph, nodename::Int)
	_testfornode(G, nodename, false)
	G.outgoing[nodename] = BitSet()
	G.incoming[nodename] = BitSet()
	return G
end

# Convenience function to find an available node name int
function imaginenewnodename(G::Graph)
	newname = 1
	while hasnode(G, newname)
		newname += 1
	end
	return newname
end

# Add a new edge to G directed from tailnode to headnode
# Raise an error if the edge already exists
function addedge!(G::Graph, tailnode::Int, headnode::Int)
	_testforedge(G, tailnode, headnode, false)
	push!(G.outgoing[tailnode], headnode)
	push!(G.incoming[headnode], tailnode)
	return G
end

# Return the number of nodes in G
# (not really planning to use this function)
function nodecount(G::Graph)
	length(G.outgoing)
end

# Return the number of edges in G
# (not really planning to use this function)
function edgecount(G::Graph)
	sum(length, values(G.outgoing))
end

# Return a bitset of all nodes in the graph G
# (not really planning to use this function)
function nodeset(G::Graph)
	BitSet(keys(G.outgoing))
end

# Return a set of tuples representing all edges in the graph G
# (not really planning to use this function)
function edgeset(G::Graph)
	edges = Set{Tuple{Int, Int}}()
	for nodeone in keys(G.outgoing)
		for nodetwo in G.outgoing[nodeone]
			push!(edges, (nodeone, nodetwo))
		end
	end
	return edges
end

# Return a set of all nodes in G having a directed edge *from* nodename
# Raise an error if the specified node does not exist
function outgoingnodes(G::Graph, nodename::Int)
	_testfornode(G, nodename, true)
	copy(G.outgoing[nodename])
end

function outgoingedges(G::Graph, nodename::Int)
	Set{Tuple{Int, Int}}((nodename, outnode) for outnode in
		outgoingnodes(G, nodename))
end

# Return a set of all nodes in G having a directed edge *to* nodename
# Raise an error if the specified node does not exist
function incomingnodes(G::Graph, nodename::Int)
	_testfornode(G, nodename, true)
	copy(G.incoming[nodename])
end

function incomingedges(G::Graph, nodename::Int)
	Set{Tuple{Int, Int}}((innode, nodename) for innode in
		incomingnodes(G, nodename))
end

# Remove the node called nodename from G
# Raise an error if no such node exists or if the node has any connecting edges
# (not really planning to use this function)
function deletenode!(G::Graph, nodename::Int)
	_testfornode(G, nodename, true)
	isempty(union(outgoingnodes(G, nodename), incomingnodes(G, nodename))) ||
		error("cannot delete node $nodename with connecting edges")
	delete!(G.outgoing, nodename)
	delete!(G.incoming, nodename)
	delete!(G.nodedata, nodename)  # No error if key does not exist
	return G
end

# Remove the edge from tailnode to headnode in G
# Raise an error if no such edge exists
# (not really planning to use this function)
function deleteedge!(G::Graph, tailnode::Int, headnode::Int)
	_testforedge(G, tailnode, headnode, true)
	delete!(G.outgoing[tailnode], headnode)
	delete!(G.incoming[headnode], tailnode)
	delete!(G.edgedata, (tailnode, headnode))  # No error if key does not exist
	return G
end

# Return the node data associated with the node in G called nodename
# Raise an error if no such node exists
function getnodedata(G::Graph{NDT, EDT},
	nodename::Int)::Union{NDT, Nothing} where {NDT, EDT}
	
	_testfornode(G, nodename, true)
	if haskey(G.nodedata, nodename)
		return G.nodedata[nodename]
	else
		return nothing
	end
end

# Return the edge data associated with the edge in G from tailnode to headnode
# Raise an error if no such edge exists
function getedgedata(G::Graph{NDT, EDT},
	tailnode::Int, headnode::Int)::Union{EDT, Nothing} where {NDT, EDT}
	
	_testforedge(G, tailnode, headnode, true)
	if haskey(G.edgedata, (tailnode, headnode))
		return G.edgedata[tailnode, headnode]
	else
		return nothing
	end
end

# Set the nodedata associated with the node nodename in G
# Raise an error if no such node exists
function setnodedata!(G::Graph{NDT, EDT},
	nodename::Int, nodedata::NDT) where {NDT, EDT}
	
	_testfornode(G, nodename, true)
	G.nodedata[nodename] = nodedata
	return G
end

# Set the edgedata associated with the edge from tailnode to headnode in G
# Raise an error if no such edge exists
function setedgedata!(G::Graph{NDT, EDT},
	tailnode::Int, headnode::Int, edgedata::EDT) where {NDT, EDT}
	
	_testforedge(G, tailnode, headnode, true)
	G.edgedata[tailnode, headnode] = edgedata
	return G
end

function Base.show(io::IO, G::Graph{NDT, EDT}) where {NDT, EDT}
	
	INDENT = " " ^ 2
	V, E = nodeset(G), edgeset(G)
	
	print(io, "Graph{$(NDT), $(EDT)}:")
	
	print(io, "\n", INDENT, "Graph nodes (", length(V), "):")
	for nodename in sort(collect(V))
		print(io, "\n", INDENT ^ 2, "Node ", nodename, ": ")
		if haskey(G.nodedata, nodename)
			print(io, getnodedata(G, nodename))
		else
			print(io, "<no node data>")
		end
	end
	
	print(io, "\n", INDENT, "Graph edges (", length(E), "):")
	for edgetuple in sort(collect(E))
		tailnode, headnode = edgetuple
		print(io, "\n", INDENT ^ 2, "Edge ", tailnode, "->", headnode, ": ")
		if haskey(G.edgedata, edgetuple)
			print(io, getedgedata(G, edgetuple[1], edgetuple[2]))
		else
			print(io, "<no edge data>")
		end
	end
end

