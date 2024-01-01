using MetOfficeStationData
using Documenter

DocMeta.setdocmeta!(MetOfficeStationData, :DocTestSetup, :(using MetOfficeStationData); recursive=true)

makedocs(;
    modules=[MetOfficeStationData],
    authors="Tom Gillam <tpgillam@googlemail.com>",
    repo="https://github.com/tpgillam/MetOfficeStationData.jl/blob/{commit}{path}#{line}",
    sitename="MetOfficeStationData.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://tpgillam.github.io/MetOfficeStationData.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
    checkdocs=:exports,
)

deploydocs(;
    repo="github.com/tpgillam/MetOfficeStationData.jl",
    devbranch="main",
)
