module Zotero

using AbstractTrees: AbstractTrees, print_tree
using Base: @kwdef
using Crayons
using DotEnv
using HTTP
using JSON3
using ProgressMeter
using Random: AbstractRNG, default_rng
using ZipFile

import HTTP: request

export ZoteroClient
export print_tree


include("client.jl")
include("objects.jl")
include("api.jl")

end
