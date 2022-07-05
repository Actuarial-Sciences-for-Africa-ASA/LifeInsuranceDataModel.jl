module InsuranceProducts
import BitemporalPostgres
import SearchLight: DbId
import Base: @kwdef
using BitemporalPostgres
export Product, ProductRevision, ProductPart, ProductPartRevision, ProductPartRole

"""
Product

  a component of a bitemporal entity

"""
@kwdef mutable struct Product <: BitemporalPostgres.Component
  id::DbId = DbId()
  ref_history::DbId = InfinityKey
  ref_version::DbId = InfinityKey
end

"""
Procuct_Revision

  a revision of a Product component of a bitemporal entity

"""
@kwdef mutable struct ProductRevision <: BitemporalPostgres.ComponentRevision
  id::DbId = DbId()
  ref_component::DbId = InfinityKey
  ref_validfrom::DbId = InfinityKey
  ref_invalidfrom::DbId = InfinityKey
  description::String = ""
end

"""
ProductPartRole

  role e.g. main or supplemental risk like life and occupational disabilty, profit participation

"""
@kwdef mutable struct ProductPartRole <: Role
  id::DbId = DbId()
  domain::String = "ProductPart"
  value::String = ""
end

"""
ProductPart

  the relation between a product and it's component tariffs

"""
@kwdef mutable struct ProductPart <: BitemporalPostgres.SubComponent
  id::DbId = DbId()
  ref_history::DbId = InfinityKey
  ref_version::DbId = InfinityKey
  ref_super::DbId = InfinityKey
end

"""
ProcuctPart_Revision

  a revision of a ProductPart component of a bitemporal entity

"""
@kwdef mutable struct ProductPartRevision <: BitemporalPostgres.ComponentRevision
  id::DbId = DbId()
  ref_component::DbId = InfinityKey
  ref_validfrom::DbId = InfinityKey
  ref_invalidfrom::DbId = InfinityKey
  ref_tariff::DbId = InfinityKey
  ref_role::DbId = InfinityKey
  description::String = ""
end


"""
Tariff

  a component of a bitemporal entity

"""
@kwdef mutable struct Tariff <: BitemporalPostgres.Component
  id::DbId = DbId()
  ref_history::DbId = InfinityKey
  ref_version::DbId = InfinityKey
end

"""
Tariff_Revision

  a revision of a Tariff component of a bitemporal entity

"""
@kwdef mutable struct TariffRevision <: BitemporalPostgres.ComponentRevision
  id::DbId = DbId()
  ref_component::DbId = InfinityKey
  ref_validfrom::DbId = InfinityKey
  ref_invalidfrom::DbId = InfinityKey
  description::String = ""
end


end # module