"Abstract type representing all kind objects being stored in Zotero"
abstract type ZoteroObject end
"Document represents the concrete elements of the collections"
abstract type Document <: ZoteroObject end
# We use colors for distinguishing the tree structure more easily
const doc_color = crayon"blue"
const pdf_color = crayon"red"
const col_color = crayon"green"
const reset_color = Crayon(reset=true)

# Generate a random key for newly created documents
rand_key(rng::AbstractRNG = default_rng()) = join(rand(rng, vcat('A':'Z', '0':'9'), 8))

 @kwdef struct Library
    name::String = ""
    # Links
    alternate::Dict{Symbol, Any} = Dict{Symbol, Any}(:href => "", :type => "text/html")
    id::Int = 0
    type::String = ""
end

function Library(dict::Dict{Symbol, Any})
    alternate = dict[:links]["alternate"]
    delete!(dict, :links)
    dict[:alternate] = Dict(alternate)
    Library(;dict...)
end

@kwdef struct ParentDoc <: Document
    key::String = rand_key()
    library::Library
    # Meta Info
    meta::Dict{Symbol, Any} = Dict{Symbol, Any}()
    # Links
    links::Dict{Symbol, Any} = Dict{Symbol, Any}()
    # Data
    data::Dict{Symbol, Any} = Dict{Symbol, Any}()
    version::Int = 0
    attachments::Vector{Document} = Document[]
end

@kwdef struct Attachment <: Document
    key::String = rand_key()
    library::Library
    # Meta Info
    meta::Dict{Symbol, Any} = Dict{Symbol, Any}()
    # Links
    links::Dict{Symbol, Any} = Dict{Symbol, Any}()
    # Data
    data::Dict{Symbol, Any} = Dict{Symbol, Any}()
    version::Int = 0
    attachments::Vector{Document} = Document[]
end

@kwdef struct PDF <: Document
    key::String = rand_key()
    library::Library
    # Meta Info
    meta::Dict{Symbol, Any} = Dict{Symbol, Any}()
    # Links
    links::Dict{Symbol, Any} = Dict{Symbol, Any}()
    # Data
    data::Dict{Symbol, Any} = Dict{Symbol, Any}()
    version::Int = 0
    attachments::Vector{Document} = Document[]
end

@kwdef struct URL <: Document
    key::String = rand_key()
    library::Library
    # Meta Info
    meta::Dict{Symbol, Any} = Dict{Symbol, Any}()
    # Links
    links::Dict{Symbol, Any} = Dict{Symbol, Any}()
    # Data
    data::Dict{Symbol, Any} = Dict{Symbol, Any}()
    version::Int = 0
    attachments::Vector{Document} = Document[]
end

@kwdef struct Presentation <: Document
    key::String = rand_key()
    library::Library
    # Meta Info
    meta::Dict{Symbol, Any} = Dict{Symbol, Any}()
    # Links
    links::Dict{Symbol, Any} = Dict{Symbol, Any}()
    # Data
    data::Dict{Symbol, Any} = Dict{Symbol, Any}()
    version::Int = 0
    attachments::Vector{Document} = Document[]
end

@kwdef struct Note <: Document
    key::String = rand_key()
    library::Library
    # Meta Info
    meta::Dict{Symbol, Any} = Dict{Symbol, Any}()
    # Links
    links::Dict{Symbol, Any} = Dict{Symbol, Any}()
    # Data
    data::Dict{Symbol, Any} = Dict{Symbol, Any}()
    version::Int = 0
    attachments::Vector{Document} = Document[]
end

function dict_to_doc(dict::Dict{Symbol, Any})
    dict[:library] = Library(Dict(dict[:library]))
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
@kwdef mutable struct Collection <: ZoteroObject
    key::String = rand_key()
    library::Library
    # Meta Info
    numCollections::Int = 0
    numItems::Int = 0
    # Links
    self::Dict{Symbol, Any} = Dict{Symbol, Any}(:href => "", :type => "application/json")
    alternate::Dict{Symbol, Any} = Dict{Symbol, Any}(:href => "", :type => "text/html")
    up::Dict{Symbol, Any} = Dict{Symbol, Any}(:href => "", :type => "application/json")
    # Data
    name::String = ""
    parentCollection::String = ""
    relations::Dict = Dict{Symbol, Any}()
    version::Int = 0
    # Contained objects
    cols::Vector{Collection} = Collection[]
    docs::Vector{Document} = Document[]
end

function Collection(dict::Dict{Symbol, Any})
    dict[:data] = Dict(dict[:data])
    if dict[:data][:parentCollection] isa Bool
        dict[:data][:parentCollection] = ""
    end
    merged_dicts = merge(
    Dict(:key => dict[:key], :library => Library(Dict(dict[:library]))),
        dict[:meta],
        dict[:links],
        dict[:data],
        )
    Collection(;merged_dicts...)
end

Base.getindex(c::Collection, i::Int) = getindex(c.docs, i)
Base.iterate(c::Collection, state) = iterate(c.docs, state)
Base.iterate(c::Collection) = iterate(c.docs)
Base.length(c::Collection) = length(c.docs)

title(c::Collection) = c.name
title(d::ParentDoc) = d.data[:title]

AbstractTrees.children(::Document) = ()
AbstractTrees.children(c::Collection) = vcat(c.cols, c.docs)

ispdf(d::Document) = endswith(d.creatorSummary, ".pdf")

AbstractTrees.printnode(io::IO, d::ParentDoc) = print(io, doc_color, title(d), reset_color)
AbstractTrees.printnode(io::IO, c::Collection) = print(io, col_color, c.name, reset_color)

Base.show(io::IO, ::MIME"text/plain", c::Collection) = print_tree(io, c)

function get_library(client::ZoteroClient; kwargs...)
    root = Collection(name="root", key="", library=Library())
    dicts = request_json(client, "GET", "collections"; kwargs...)
    @showprogress for dict in dicts
        col = Collection(Dict(dict))
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
        if haskey(doc.data, :parentItem) && doc.data[:parentItem] == topdoc.key
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
    return Dict(string(key)=>value for (key, value) in dict if key != :objects)
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