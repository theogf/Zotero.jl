using Zotero
using Test
using DotEnv
DotEnv.config(joinpath(@__DIR__, ".env"))

@testset "Test API requests" begin
    c = ZoteroClient()
    @testset "Accessing" begin
        lib = get_library(c)
    end
end