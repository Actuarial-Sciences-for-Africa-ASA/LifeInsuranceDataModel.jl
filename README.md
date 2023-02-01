[![CI](https://github.com/actuarial-sciences-for-africa-asa/LifeInsuranceDataModel.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/actuarial-sciences-for-africa-asa/LifeInsuranceDataModel.jl/actions/workflows/CI.yml)

[![Documentation](https://github.com/actuarial-sciences-for-africa-asa/LifeInsuranceDataModel.jl/actions/workflows/GenDocs.yml/badge.svg)](https://github.com/actuarial-sciences-for-africa-asa/LifeInsuranceDataModel.jl/actions/workflows/GenDocs.yml)

This is a prototype model for bitemporal data management based on [a Julia bitemporal data management API](https://github.com/actuarial-sciences-for-africa-asa/BitemporalPostgres.jl)

The Data Model of the prototype. This is - as of now - all about versioning of entities and relationships for a Life Insurance app - domain specific attributes will be added when calculations will come into play. (Like the examples from [LifeContingencies.jl](https://github.com/JuliaActuary/LifeContingencies.jl))

Current features are:

- Bitemporal CRUD of contracts, products and partners 
  - using transaction logic making uncommitted transaction data persistent, such that uncommitted transactions can be 
    - suspended and resumed and 
    - passed on in workflow contexts, where
    - ownership of a workflow can be transferred between users.
- Support of MVVM Architecture by
  - creation of cross sections of the two-dimensional data model given transaction and reference time - ¨state of affairs as of referenced time as persisted of transaction time¨ thus providing view model content for display and editing.
  - enabling conversion of sections into JSON and vice versa using nested Dict{String,Any}. Leveraging [Stipple,jl](https://github.com/GenieFramework/Stipple.jl) a reactive JSON based view model can be created from and synched with these julia dictionaries.
  - view model editing with savepointing using a stack of transient view model states
  - persisting view model state into an uncommitted transaction whereby the last view model states becomes the new bottom of the stack. 
  - rolling back and committing workflow contexts
and [gitpod](.gitpod.Dockerfile)
- Test and sample code scripts
  - [for the BitemporalPostgres-API. Creation, Mutation, Committing](testsCreateContract.jl)
  - [and mutations persisted pending and rolled back](testPendingMutations.jl)
  - to be completed to cover all features
- scripts for [github workflow](.github/workflows/CI.yml) and [gitpod](.gitpod.Dockerfile) providing a running postgres instance.

<!--[not up to date
  The same test and sample code as a Jupyter notebook. Creation ...](testsCreateContract.ipynb)
[and mutations ... ](testPendingMutations.ipynb)
-->
<!-- fawlty as of now
When You open this project in a [gitpod container](https://gitpod.io/workspaces) the test code will be executed automatically to spin up and populate the database. -->

![UML Model](docs/src/assets/LifeInsuranceDataModel.png)
# 
