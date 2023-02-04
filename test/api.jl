using Zotero
using Test
using DotEnv
DotEnv.config(joinpath(@__DIR__, ".env"))

@testset "Test API requests" begin
end
c = ZoteroClient()
lib = get_library(c)