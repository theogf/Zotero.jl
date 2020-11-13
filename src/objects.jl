abstract type ZoteroObject end

doc_color = crayon"blue"
pdf_color = crayon"red"
col_color = crayon"green"
reset_color = Crayon(reset=true)

@with_kw mutable struct Document <: ZoteroObject
    ID::String = ""
end


@with_kw mutable struct Collection <: ZoteroObject
    ID::String = string(uuid4())
    items::Vector{ZoteroObject} = ZoteroObject[]
end

Document(dict::Dict{String, Any}) = Document(;Dict(Symbol(key)=>value for (key, value) in dict)...)
Collection(dict::Dict{String, Any}) = Collection(;Dict(Symbol(key)=>value for (key, value) in dict)...)

Base.getindex(c::Collection, i::Int) = c.objects[i]
Base.iterate(c::Collection, state) = iterate(c.objects, state)
Base.iterate(c::Collection) = iterate(c.objects)
Base.length(c::Collection) = length(c.objects)

AbstractTrees.children(::Document) = ()
AbstractTrees.children(c::Collection) = c.objects

ispdf(d::Document) = endswith(d.VissibleName, ".pdf")

AbstractTrees.printnode(io::IO, d::Document) = print(io, ispdf(d) ? pdf_color : doc_color, d.VissibleName, reset_color)
AbstractTrees.printnode(io::IO, c::Collection) = print(io, col_color, c.VissibleName, reset_color)

function create_tree(docs::AbstractVector{<:ZoteroObject})
    root = Collection(ID = "", VissibleName = "Root")
    push!(root.objects, Collection(ID = "Trash", VissibleName = "Trash"))
    update_obj!(root, docs) # Recursive loop on documents
    return root
end

function update_obj!(col::Collection, docs)
    for doc in docs
        if doc.Parent == col.ID
            update_obj!(doc, docs)
            push!(col.objects, doc)
        end
    end
end

update_obj!(::Document, ::Any) = nothing

function obj_to_dict(doc::Document)
    dict = type2dict(doc)
    return Dict(string(key)=>value for (key, value) in dict)
end

function obj_to_dict(col::Collection)
    dict = type2dict(col)
    delete!(dict, :objects)
    return Dict(string(key)=>value for (key, value) in dict)
end