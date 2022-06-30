module InsuranceContracts
import BitemporalPostgres
import SearchLight: DbId, AbstractModel
import Base: @kwdef
export Contract, ContractRevision, ContractPartnerRole, ContractPartnerRef, ContractPartnerRefRevision, ProductItem, TariffItemRole, ProductItemRevision, TariffItem, TariffItemRevision, TariffItemPartnerRole, TariffItemPartnerRef, TariffItemPartnerRefRevision
using BitemporalPostgres

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
  position::Integer = 0::Int64
  ref_validfrom::DbId = InfinityKey
  ref_invalidfrom::DbId = InfinityKey
  description::String = ""
end

"""
Role

  role of a relationship 

"""
abstract type Role <: AbstractModel end

function get_id(role::Role)::DbId
  role.id
end
function get_domain(role::Role)::DbId
  role.domain
end
function get_value(role::Role)::DbId
  role.value
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
  ref_role::DbId = InfinityKey
  ref_validfrom::DbId = InfinityKey
  ref_invalidfrom::DbId = InfinityKey
  description::String = ""
  ref_partner::DbId = DbId()
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
end

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

end
