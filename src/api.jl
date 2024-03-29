function Base.download(client::ZoteroClient, doc::Document; kwargs...)
    request_json(client, "GET", joinpath("items", doc.key))
end

function Base.download(client::ZoteroClient, col::Collection; kwargs...)
    request_json(client, "GET", joinpath("collections", col.key))
end

function download_item(client::ZoteroClient, key::String, dl::Bool=false, kwargs...)
    download(client, ParentDoc(; key=key); dl, kwargs...)
end

function download_collection(client::ZoteroClient, key::String, dl::Bool=false, kwargs...)
    download(client, ParentDoc(;key=key); dl, kwargs...)
end

function collect_items!(client::ZoteroClient, col::Collection; refresh::Bool=false, kwargs...)
    if isempty(col.docs) || refresh
        dicts = request_json(client, "GET", joinpath("collections", col.key, "items"); kwargs)
        docs = dict_to_doc.(Dict.(dicts))
        org_docs = organize(docs)
        col.docs = org_docs
    end
    return col.docs
end