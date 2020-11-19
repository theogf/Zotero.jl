abstract type ZoteroObject end
abstract type Document <: ZoteroObject end
doc_color = crayon"blue"
pdf_color = crayon"red"
col_color = crayon"green"
reset_color = Crayon(reset=true)

rand_key() = join(rand(vcat('A':'Z', '0':'9'), 8))

@with_kw mutable struct Library
    name::String = ""
    # Links
    alternate::Dict{String, Any} = Dict{String, Any}("href" => "", "type" => "text/html")
    id::Int = 0
    type::String = ""
end

function Library(dict::Dict{String, Any})
    alternate = dict["links"]["alternate"]
    delete!(dict, "links")
    dict["alternate"] = alternate
    Library(;Dict(Symbol(key)=>value for (key, value) in dict)...)
end

@with_kw mutable struct ParentDoc <: Document
    key::String = rand_key()
    library::Library
    # Meta Info
    meta::Dict{String, Any} = Dict{String, Any}()
    # Links
    links::Dict{String, Any} = Dict{String, Any}()
    # Data
    data::Dict{String, Any} = Dict{String, Any}()
    version::Int = 0
    attachments::Vector{Document} = Document[]
end

@with_kw mutable struct Attachment <: Document
    key::String = rand_key()
    library::Library
    # Meta Info
    meta::Dict{String, Any} = Dict{String, Any}()
    # Links
    links::Dict{String, Any} = Dict{String, Any}()
    # Data
    data::Dict{String, Any} = Dict{String, Any}()
    version::Int = 0
    attachments::Vector{Document} = Document[]
end

@with_kw mutable struct PDF <: Document
    key::String = rand_key()
    library::Library
    # Meta Info
    meta::Dict{String, Any} = Dict{String, Any}()
    # Links
    links::Dict{String, Any} = Dict{String, Any}()
    # Data
    data::Dict{String, Any} = Dict{String, Any}()
    version::Int = 0
    attachments::Vector{Document} = Document[]
end

@with_kw mutable struct URL <: Document
    key::String = rand_key()
    library::Library
    # Meta Info
    meta::Dict{String, Any} = Dict{String, Any}()
    # Links
    links::Dict{String, Any} = Dict{String, Any}()
    # Data
    data::Dict{String, Any} = Dict{String, Any}()
    version::Int = 0
    attachments::Vector{Document} = Document[]
end

@with_kw mutable struct Presentation <: Document
    key::String = rand_key()
    library::Library
    # Meta Info
    meta::Dict{String, Any} = Dict{String, Any}()
    # Links
    links::Dict{String, Any} = Dict{String, Any}()
    # Data
    data::Dict{String, Any} = Dict{String, Any}()
    version::Int = 0
    attachments::Vector{Document} = Document[]
end

@with_kw mutable struct Note <: Document
    key::String = rand_key()
    library::Library
    # Meta Info
    meta::Dict{String, Any} = Dict{String, Any}()
    # Links
    links::Dict{String, Any} = Dict{String, Any}()
    # Data
    data::Dict{String, Any} = Dict{String, Any}()
    version::Int = 0
    attachments::Vector{Document} = Document[]
end

function dict_to_doc(dict::Dict{String, Any})
    dict["library"] = Library(dict["library"])
    dict = Dict(Symbol(key)=>value for (key, value) in dict) # Convert in symbol convention
    if !haskey(dict[:data], "parentItem")
        return ParentDoc(;dict...)
    end
    if dict[:data]["itemType"] == "attachment"
        if dict[:data]["contentType"] == "application/pdf"
            return PDF(;dict...)
        elseif dict[:data]["contentType"] == "text/html"
            return URL(;dict...)
        else
            return Attachment(;dict...)
        end
    elseif dict[:data]["itemType"] == "note"
        return Note(;dict...)
    # elseif dict[:data]["ItemType"] == "presentation"
    #     return Presentation(;dict...)
    end
end
@with_kw mutable struct Collection <: ZoteroObject
    key::String = rand_key()
    library::Library
    # Meta Info
    numCollections::Int = 0
    numItems::Int = 0
    # Links
    self::Dict{String, Any} = Dict{String, Any}("href" => "", "type" => "application/json")
    alternate::Dict{String, Any} = Dict{String, Any}("href" => "", "type" => "text/html")
    up::Dict{String, Any} = Dict{String, Any}("href" => "", "type" => "application/json")
    # Data
    name::String = ""
    parentCollection::String = ""
    relations::Dict = Dict{String, Any}()
    version::Int = 0
    # Contained objects
    cols::Vector{Collection} = Collection[]
    docs::Vector{Document} = Document[]
end

function Collection(dict::Dict{String, Any})
    dict["data"]["parentCollection"] isa Bool ? dict["data"]["parentCollection"] = "" : nothing
    merged_dicts = merge(
        Dict("key" => dict["key"], "library" => Library(dict["library"])),
        dict["meta"],
        dict["links"],
        dict["data"],
        )
    Collection(;Dict(Symbol(key)=>value for (key, value) in merged_dicts)...)
end

Base.getindex(c::Collection, i::Int) = getindex(c.docs, i)
Base.iterate(c::Collection, state) = iterate(c.docs, state)
Base.iterate(c::Collection) = iterate(c.docs)
Base.length(c::Collection) = length(c.docs)

title(c::Collection) = c.name
title(d::ParentDoc) = d.data["title"]

AbstractTrees.children(::Document) = ()
AbstractTrees.children(c::Collection) = vcat(c.cols, c.docs)

ispdf(d::Document) = endswith(d.creatorSummary, ".pdf")

AbstractTrees.printnode(io::IO, d::ParentDoc) = print(io, doc_color, d.data["title"], reset_color)
AbstractTrees.printnode(io::IO, c::Collection) = print(io, col_color, c.name, reset_color)


function get_library(client::ZoteroClient; kwargs...)
    root = Collection(name="root", key="", library=Library())
    dicts = request_json(client, "GET", "collections"; kwargs...)
    @showprogress for dict in dicts
        col = Collection(dict)
        if col.parentCollection == ""
            update_col!(client, col)
            push!(root.cols, col)
        end
    end
    root.numCollections = length(root.cols)
    return root
end


function update_col!(client::ZoteroClient, col::Collection)
    # First add all items
    collect_items!(client, col, refresh=true)
    # Then add all subcollections
    dicts = request_json(client, "GET", joinpath("collections", col.key, "collections"))
    for dict in dicts
        new_col = Collection(dict)
        update_col!(client, new_col)
        push!(col.cols, new_col)
    end
    return col
end

function organize(docs::AbstractVector)
    topdocs = Document[]
    for doc in docs
        if doc isa ParentDoc
            organize!(doc, docs)
            push!(topdocs, doc)
        end
    end
    return topdocs
end

function organize!(topdoc::ParentDoc, docs::AbstractVector)
    for doc in docs
        if haskey(doc.data, "parentItem") && doc.data["parentItem"] == topdoc.key
            push!(topdoc.attachments, doc)
        end
    end
end

function obj_to_dict(doc::Document)
    dict = type2dict(doc)
    return Dict(string(key)=>value for (key, value) in dict)
end

function obj_to_dict(col::Collection)
    dict = type2dict(col)
    delete!(dict, :objects)
    return Dict(string(key)=>value for (key, value) in dict)
end


function find_col(f, client::ZoteroClient, col::Collection=get_library(client))
    if f(col)
        return col
    end
    for c in col.cols
        res = find_col(f, client, c)
        isnothing(res) ? nothing : return res
    end
    return nothing
end