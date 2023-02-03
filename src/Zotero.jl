module Zotero

using HTTP
import HTTP: request
using AbstractTrees: AbstractTrees, print_tree
using Parameters
using JSON3
using Crayons
using ProgressMeter
using ZipFile

export ZoteroClient
export print_tree


include("client.jl")
include("objects.jl")
include("api.jl")

end
