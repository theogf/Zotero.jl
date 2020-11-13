using Zotero
using Documenter

makedocs(;
    modules=[Zotero],
    authors="Théo Galy-Fajou <theo.galyfajou@gmail.com> and contributors",
    repo="https://github.com/theogf/Zotero.jl/blob/{commit}{path}#L{line}",
    sitename="Zotero.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://theogf.github.io/Zotero.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/theogf/Zotero.jl",
)
