using Zotero
using Test
using JSON

@testset "Zotero.jl" begin
    # Write your tests here.
end


c = ZoteroClient("test")
dicts = Zotero.request_json(c, "GET", "collections/LKXGUR69/items")
dict = dicts[1]
Zotero.dict_to_doc(dict)

l = Zotero.get_library(c)
print_tree(l)