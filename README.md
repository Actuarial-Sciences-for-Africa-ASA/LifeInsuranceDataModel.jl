[![CI](https://github.com/actuarial-sciences-for-africa-asa/LifeInsuranceDataModel.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/actuarial-sciences-for-africa-asa/LifeInsuranceDataModel.jl/actions/workflows/CI.yml)

[![Documentation](https://github.com/actuarial-sciences-for-africa-asa/LifeInsuranceDataModel.jl/actions/workflows/GenDocs.yml/badge.svg)](https://github.com/actuarial-sciences-for-africa-asa/LifeInsuranceDataModel.jl/actions/workflows/GenDocs.yml)

This is a prototype model for bitemporal data management based on [a Julia bitemporal data management API](https://github.com/actuarial-sciences-for-africa-asa/BitemporalPostgres.jl)

It is intended to provide persistence for [this Webapp](https://github.com/actuarial-sciences-for-africa-asa/BitemporalReactive.jl)

The Data Model of the prototype. This is - as of now - all about versioning of entities and relationships for a Life Insurance app - domain specific attributes will be added when calculations will come into play. (Like the examples from [LifeContingencies.jl](https://github.com/JuliaActuary/LifeContingencies.jl))

Current features are:

- populating the database
- displaying contract versions and history

[Test and sample code for the BitemporalPostgres-API](testsCreateContract.jl)

[The same test and sample code as a Jupyter notebook](testsCreateContract.ipynb)

When You open this project in a [gitpod container](https://gitpod.io/workspaces) the test code will be executed automatically to spin up and populate the database. 

![UML Model](docs/src/assets/LifeInsuranceDataModel.png)
