using Zotero
using Test

@testset "Test creation of client" begin
    token = ENV["ZOTERO_API_TOKEN"]
    user_id = ENV["ZOTERO_USER_ID"]
    client = ZoteroClient()
    @test client.token == token
    @test client.id == user_id
    @test client.prefix == "users"
    @test ZoteroClient() == ZoteroClient(;path=joinpath(@__DIR__, ".env"))
    ENV["IS_ZOTERO_USER"] = false
    client = ZoteroClient()
    delete!(ENV, "IS_ZOTERO_USER")
    @test client.prefix == "groups"
    @test Zotero.base_url(client) == joinpath(Zotero.ZOTERO, "groups", user_id)
end