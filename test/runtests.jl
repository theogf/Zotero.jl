using Zotero
using Test
using JSON

@testset "Zotero.jl" begin
    # Write your tests here.
end


c = ZoteroClient("test")
dicts = Zotero.request_json(c, "GET", "collections/LKXGUR69/items")
dict = dicts[1]
Zotero.Document(dict)

l = Zotero.get_library(c)
