# proliferators.jl
# 


###
# 
###

struct Proliferator
	product::Product
	sprays::Int
	extra::Rational{Int}
	speedup::Rational{Int}
end

@enum ProliferationMode::Int8 extraproducts=1 productionspeedup=2

