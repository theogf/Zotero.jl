function Base.download(client::ZoteroClient, doc::Document; dl=false)
    request_json(client, "GET", joinpath("items", doc.key))
end

function Base.download(client::ZoteroClient, col::Collection; dl=false)
    request_json(client, "GET", joinpath("collections", col.key))
end

function download_item(client::ZoteroClient, key::String, dl=false, kwargs...)
    download(client, Document(; key=key); dl=dl, kwargs...)
end

function download_collection(client::ZoteroClient, key::String, dl=false, kwargs...)
    download(client, Document(; key=key); dl=dl, kwargs...)
end

function collect_items!(client::ZoteroClient, col::Collection; refresh=false, kwargs...)
    if isempty(col.docs) || refresh
        dicts = request_json(client, "GET", joinpath("collections", col.key, "items"); kwargs)
        col.docs = Document.(dicts)
    end
    return col.docs
end