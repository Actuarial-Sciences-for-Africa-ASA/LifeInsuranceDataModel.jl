# LifeInsuranceDataModel.jl

The notion of section is used here to describe object revisions as of a certain pair of points in - 2 dimensional - transaction and reference time. So it is a geometrical metaphor of two crossing cuts = i.e. sections - reducing 2D-transaction and reference time to 1D-reference time using a point in transaction time and reducing 1D-reference time using a point in reference time to yield a point in the version space.

## Customizing
### Adding bitemporal entities and components
Current entities are Contract, Partner,Product,Tariff.
- Create packages like InsuranceContracts.jl and include
it in LifeInsuranceDataModel.jl. Export Your new Symbols.
- Create or update the enumeration function  to contain all subcomponents' revision types you assign or add to the root entity of type T:
``BitemporalPostgres.revisionTypes(entity::Val{T})::Vector{T} where {T<:Symbol}``
Example:
  - ``BitemporalPostgres.revisionTypes(entity::Val{:Contract})``
- add functions ``get_typeof_revision`` and ``get_typeof_component`` for the new revision and component.
Examples:
  - ``BitemporalPostgres.get_typeof_revision(component::Contract) :: Type{ContractRevision}`` and
  - ``BitemporalPostgres.get_typeof_component(revision::ContractRevision) :: Type{Contract}``
- Add DDL for your entity or component in functions up and down of package DDL.jl 
  - create tables for your structs and
  - and create constraints and triggers using the function ``createRevisionsTriggerAndConstraint(trigger::Symbol,constraint::Symbol,table::Symbol,)``
- Add your tables to sqlsnippets/droptables.sql preserving the reverse order of dependencies (no dependencies first)

end


![UML Model](../assets/LifeInsuranceDataModel.png)

```@autodocs
Modules = [LifeInsuranceDataModel]
```