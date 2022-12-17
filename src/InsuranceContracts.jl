module InsuranceContracts
import BitemporalPostgres
import SearchLight: DbId, AbstractModel
import Base: @kwdef

export Contract, ContractRevision, ContractPartnerRole, ContractPartnerRef, ContractPartnerRefRevision, ProductItem, TariffItemRole, ProductItemRevision,
  TariffItem, TariffItemRevision, TariffItemPartnerRole, TariffItemPartnerRef, TariffItemPartnerRefRevision
using BitemporalPostgres

"""
BitemporalPostgres.revisionTypes(entity::Val{:Contract}) 
  defining the ComponentRevision types occurring in Contracts
"""
BitemporalPostgres.revisionTypes(entity::Val{:Contract}) = [ContractPartnerRefRevision,
  ContractRevision, ProductItemRevision,
  TariffItemPartnerRefRevision, TariffItemRevision
]

"""
Contract

  a contract component of a bitemporal entity

"""
@kwdef mutable struct Contract <: BitemporalPostgres.Component
  id::DbId = DbId()
  ref_history::DbId = InfinityKey
  ref_version::DbId = InfinityKey
end

"""
ContractRevision

  a revision of a contract component

"""
@kwdef mutable struct ContractRevision <: BitemporalPostgres.ComponentRevision
  id::DbId = DbId()
  ref_component::DbId = InfinityKey
  ref_validfrom::DbId = InfinityKey
  ref_invalidfrom::DbId = InfinityKey
  description::String = ""
end

Base.copy(src::ContractRevision) = ContractRevision(
  ref_component=src.ref_component,
  description=src.description,
)
"""
BitemporalPostgres.get_typeof_revision(component::Contract) :: Type{ContractRevision}
"""
function BitemporalPostgres.get_typeof_revision(component::Contract)::Type{ContractRevision}
  ContractRevision
end

"""
BitemporalPostgres.get_typeof_component(revision::ContractRevision) :: Type{Contract}
"""
function BitemporalPostgres.get_typeof_component(revision::ContractRevision)::Type{Contract}
  Contract
end

"""
ProductItem

  a productitem component of a contract component

"""
@kwdef mutable struct ProductItem <: BitemporalPostgres.SubComponent
  id::DbId = DbId()
  ref_history::DbId = InfinityKey
  ref_version::DbId = InfinityKey
  ref_super::DbId = InfinityKey
end

"""
ProductItemRevision

  a revision of a productitem component

"""
@kwdef mutable struct ProductItemRevision <: BitemporalPostgres.ComponentRevision
  id::DbId = DbId()
  ref_component::DbId = InfinityKey
  ref_validfrom::DbId = InfinityKey
  ref_invalidfrom::DbId = InfinityKey
  ref_product::DbId = InfinityKey
  description::String = ""
end

"""
BitemporalPostgres.get_typeof_revision(component::ProductItem) :: Type{ProductItemRevision}
"""
function BitemporalPostgres.get_typeof_revision(component::ProductItem)::Type{ProductItemRevision}
  ProductItemRevision
end

"""
BitemporalPostgres.get_typeof_component(revision::ProductItemRevision) :: Type{ProductItem}
"""
function BitemporalPostgres.get_typeof_component(revision::ProductItemRevision)::Type{ProductItem}
  ProductItem
end

Base.copy(src::ProductItemRevision) = ProductItemRevision(
  ref_component=src.ref_component,
  description=src.description,)

"""
BitemporalPostgres.get_typeof_revision(component::ProductItem) :: Type{ProductItemRevision}
"""
function BitemporalPostgres.get_typeof_revision(component::ProductItem)::Type{ProductItemRevision}
  ProductItemRevision
end

"""
BitemporalPostgres.get_typeof_component(revision::ProductItemRevision) :: Type{ProductItem}
"""
function BitemporalPostgres.get_typeof_component(revision::ProductItemRevision)::Type{ProductItem}
  ProductItem
end

"""
ContractPartnerRole

  role e.g. policy holder or premium payer

"""
@kwdef mutable struct ContractPartnerRole <: Role
  id::DbId = DbId()
  domain::String = "ContractPartner"
  value::String = ""
end

"""
ContractPartnerRef

  a partner reference of a contract component, i.e. policy holder, premium payer

"""
@kwdef mutable struct ContractPartnerRef <: BitemporalPostgres.SubComponent
  id::DbId = DbId()
  ref_history::DbId = InfinityKey
  ref_version::DbId = InfinityKey
  ref_super::DbId = InfinityKey
end

"""
ContractPartnerRefRevision

  a revision of a contract's partner reference

"""
@kwdef mutable struct ContractPartnerRefRevision <: BitemporalPostgres.ComponentRevision
  id::DbId = DbId()
  ref_component::DbId = InfinityKey
  ref_role::DbId = DbId()
  ref_validfrom::DbId = InfinityKey
  ref_invalidfrom::DbId = InfinityKey
  description::String = ""
  ref_partner::DbId = DbId()
end

Base.copy(src::ContractPartnerRefRevision) = ContractPartnerRefRevision(
  ref_component=src.ref_component,
  description=src.description)

"""
BitemporalPostgres.get_typeof_revision(component::ContractPartnerRef) :: Type{ContractPartnerRefRevision}
"""
function BitemporalPostgres.get_typeof_revision(component::ContractPartnerRef)::Type{ContractPartnerRefRevision}
  ContractPartnerRefRevision
end

"""
BitemporalPostgres.get_typeof_component(revision::ContractPartnerRefRevision) :: Type{ContractPartnerRef}
"""
function BitemporalPostgres.get_typeof_component(revision::ContractPartnerRefRevision)::Type{ContractPartnerRef}
  ContractPartnerRef
end
"""
TariffItemRole

  role e.g. main or supplemental risk like life and occupational disabilty

"""
@kwdef mutable struct TariffItemRole <: Role
  id::DbId = DbId()
  domain::String = "TariffItem"
  value::String = ""
end

"""
TariffItem

  a reference to a tariff with contractual parameters

"""
@kwdef mutable struct TariffItem <: BitemporalPostgres.SubComponent
  id::DbId = DbId()
  ref_history::DbId = InfinityKey
  ref_version::DbId = InfinityKey
  ref_super::DbId = InfinityKey
end

"""
TariffItemRevision

  a revision of a tariffitem

"""
@kwdef mutable struct TariffItemRevision <: BitemporalPostgres.ComponentRevision
  id::DbId = DbId()
  ref_component::DbId = InfinityKey
  ref_role::DbId = InfinityKey
  ref_validfrom::DbId = InfinityKey
  ref_invalidfrom::DbId = InfinityKey
  description::String = ""
  ref_tariff::DbId = DbId()
  net_premium::Float64 = 0.0
  annuity_immediate::Float64 = 0.0
  deferment::Integer = 0
  annuity_due::Float64 = 0.0
end
"""
BitemporalPostgres.get_typeof_revision(component::TariffItem) :: Type{TariffItemRevision}
"""
function BitemporalPostgres.get_typeof_revision(component::TariffItem)::Type{TariffItemRevision}
  TariffItemRevision
end

"""
BitemporalPostgres.get_typeof_component(revision::TariffItemRevision) :: Type{TariffItem}
"""
function BitemporalPostgres.get_typeof_component(revision::TariffItemRevision)::Type{TariffItem}
  TariffItem
end

Base.copy(src::TariffItemRevision) = TariffItemRevision(
  ref_component=src.ref_component,
  description=src.description)

"""
TariffItemPartnerRole

  role of Partner for tariffitem, 1. or 2. insured person

"""
@kwdef mutable struct TariffItemPartnerRole <: Role
  id::DbId = DbId()
  domain::String = "TariffItemPartner"
  value::String = ""
end

"""
TariffItemPartnerRef

  a reference to a partner of a tariffitem, i.e. insured person

"""
@kwdef mutable struct TariffItemPartnerRef <: BitemporalPostgres.SubComponent
  id::DbId = DbId()
  ref_history::DbId = InfinityKey
  ref_version::DbId = InfinityKey
  ref_super::DbId = InfinityKey
end

"""
TariffItemPartnerRefRevision

  a revision of a productItem's partner reference

"""
@kwdef mutable struct TariffItemPartnerRefRevision <: BitemporalPostgres.ComponentRevision
  id::DbId = DbId()
  ref_component::DbId = InfinityKey
  ref_role::DbId = InfinityKey
  ref_validfrom::DbId = InfinityKey
  ref_invalidfrom::DbId = InfinityKey
  description::String = ""
  ref_partner::DbId = DbId()
end

"""
BitemporalPostgres.get_typeof_revision(component::TariffItemPartnerRef) :: Type{TariffItemPartnerRefRevision}
"""
function BitemporalPostgres.get_typeof_revision(component::TariffItemPartnerRef)::Type{TariffItemPartnerRefRevision}
  TariffItemPartnerRefRevision
end

"""
BitemporalPostgres.get_typeof_component(revision::TariffItemPartnerRefRevision) :: Type{TariffItemPartnerRef}
"""
function BitemporalPostgres.get_typeof_component(revision::TariffItemPartnerRefRevision)::Type{TariffItemPartnerRef}
  TariffItemPartnerRef
end
Base.copy(src::TariffItemPartnerRefRevision) = TariffItemPartnerRefRevision(
  ref_component=src.ref_component,
  description=src.description)

end
