push!(LOAD_PATH, "../src/")
using Documenter
import LifeInsuranceModel
makedocs(
    sitename="LifeInsuranceModel",
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md"
    ]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo="github.com/michaelfliegner/LifeInsuranceModel.jl"
)
