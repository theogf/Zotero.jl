function Base.download(client::ZoteroClient, obj::Collection)
    request_json(client, "GET", joinpath("collections"))
end