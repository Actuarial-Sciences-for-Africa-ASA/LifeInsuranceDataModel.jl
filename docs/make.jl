push!(LOAD_PATH, "../src/")
using Documenter
import LifeInsuranceDataModel, LifeInsuranceDataModel.InsuranceContracts, LifeInsuranceDataModel.InsurancePartners, LifeInsuranceDataModel.InsuranceTariffs
makedocs(
    sitename="LifeInsuranceDataModel",
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md"
        "LifeInsuranceDataModel API" => [
            "LifeInsuranceDataModel" => "api/LifeInsuranceDataModel.md",
            "Contract" => "api/InsuranceContracts.md",
            "Partner" => "api/InsurancePartners.md",
            "Tariff" => "api/InsuranceTariffs.md"
        ]
    ]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo="github.com/michaelfliegner/LifeInsuranceDataModel.jl"
)
