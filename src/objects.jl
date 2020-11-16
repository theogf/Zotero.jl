abstract type ZoteroObject end

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

@with_kw mutable struct Document <: ZoteroObject
    key::String = rand_key()
    library::Library
    # Meta Info
    creatorSummary::String = ""
    parsedDate::String = ""
    numChildren::Int = 0
    # Links
    self::Dict{String, Any} = Dict{String, Any}("href" => "", "type" => "application/json")
    alternate::Dict{String, Any} = Dict{String, Any}("href" => "", "type" => "text/html")
    attachment::Dict{String, Any} = Dict{String, Any}("href" => "", "type" => "application/json")
    enclosure::Dict{String, Any} = Dict{String, Any}()
    up::Dict{String, Any} = Dict{String, Any}("href" => "", "type" => "application/json")
    # Data
    data::Dict{String, Any} = Dict{String, Any}()
    version::Int = 0
end

function Document(dict::Dict{String, Any})
    merged_dicts = merge(
        Dict("key" => dict["key"], "data" => dict["data"], "library" => Library(dict["library"])),
        dict["meta"],
        dict["links"],
        )
    Document(;Dict(Symbol(key)=>value for (key, value) in merged_dicts)...)
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

Base.getindex(c::Collection, i::Int) = getindex(c.items, i)
Base.iterate(c::Collection, state) = iterate(c.items, state)
Base.iterate(c::Collection) = iterate(c.items)
Base.length(c::Collection) = length(c.items)

AbstractTrees.children(::Document) = ()
AbstractTrees.children(c::Collection) = vcat(c.cols, c.docs)

ispdf(d::Document) = endswith(d.creatorSummary, ".pdf")

AbstractTrees.printnode(io::IO, d::Document) = print(io, ispdf(d) ? pdf_color : doc_color, d.creatorSummary, reset_color)
AbstractTrees.printnode(io::IO, c::Collection) = print(io, col_color, c.name, reset_color)


function get_library(client::ZoteroClient; kwargs...)
    root = Collection(name="root", key="", library=Library())
    dicts = request_json(client, "GET", "collections"; kwargs...)
    for dict in dicts
        col = Collection(dict)
        if col.parentCollection == ""
            update_col!(client, col)
        end
        push!(root.cols, col)
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

function obj_to_dict(doc::Document)
    dict = type2dict(doc)
    return Dict(string(key)=>value for (key, value) in dict)
end

function obj_to_dict(col::Collection)
    dict = type2dict(col)
    delete!(dict, :objects)
    return Dict(string(key)=>value for (key, value) in dict)
end


function find_col_by_name(client::ZoteroClient, col::Collection=get_library(client))
    
end