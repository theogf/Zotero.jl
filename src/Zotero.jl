module Zotero

using HTTP
using AbstractTrees
using Parameters
using Crayons
using ZipFile

export ZoteroClient

include("client.jl")
include("objects.jl")
include("api.jl")

end
