using Zotero
using Test
using JSON3
using DotEnv

DotEnv.config(joinpath(@__DIR__, ".env"))

@testset "Zotero.jl" begin
    include("objects.jl")
    include("client.jl")
    # Write your tests here.
end


c = ZoteroClient("test")
dicts = Zotero.request_json(c, "GET", "collections/LKXGUR69/items")
dict = dicts[1]
Zotero.dict_to_doc(dict)

l = Zotero.get_library(c)
print_tree(l)

Zotero.find_col(x->Zotero.title(x)=="Optimization", c, l)