using Zotero
using Test

@testset "Zotero.jl" begin
    # Write your tests here.
end


c = ZoteroClient("test")

response = Zotero.HTTP.request(c, "GET", "collections/LKXGUR69")