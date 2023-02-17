module InsuranceTariffs
import BitemporalPostgres
import SearchLight: DbId
import Base: @kwdef
export Tariff, TariffRevision, TariffPartnerRole, TariffPartnerRoleRevision
using BitemporalPostgres
TariffItemRevision

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
  parameters::String = ""
  mortality_table::String = ""
end

Base.copy(src::TariffRevision) = TariffRevision(
  ref_component=src.ref_component,
  description=src.description)
#
"""
TariffPartnerRole

  a subcomponent of a tariff entity
  enumerationg the roles of tariff partners

"""
@kwdef mutable struct TariffPartnerRole <: BitemporalPostgres.SubComponent
  id::DbId = DbId()
  ref_history = DbId()
  ref_version = DbId()
  ref_super = DbId()
end

"""
TariffPartnerRoleRevision

  a partner role revision of a Tariff component of a bitemporal entity

"""
@kwdef mutable struct TariffPartnerRoleRevision <: BitemporalPostgres.ComponentRevision
  id::DbId = DbId()
  ref_component::DbId = InfinityKey
  ref_validfrom::DbId = InfinityKey
  ref_invalidfrom::DbId = InfinityKey
  ref_role::DbId = InfinityKey
end

Base.copy(src::TariffPartnerRoleRevision) = TariffPartnerRoleRevision(
  ref_component=src.ref_component,
  ref_role=src.ref_role)

"""
BitemporalPostgres.revisionTypes(entity::Val{:Tariff}) 
  defining the ComponentRevision types occurring in Contracts
"""
BitemporalPostgres.revisionTypes(entity::Val{:Tariff}) = [TariffRevision, TariffPartnerRoleRevision]

"""
BitemporalPostgres.get_typeof_revision(component::Tariff) :: Type{TariffRevision}
"""
function BitemporalPostgres.get_typeof_revision(component::Tariff)::Type{TariffRevision}
  TariffRevision
end

"""
BitemporalPostgres.get_typeof_component(revision::TariffRevision) :: Type{Tariff}
"""
function BitemporalPostgres.get_typeof_component(revision::TariffRevision)::Type{Tariff}
  Tariff
end

"""
BitemporalPostgres.get_typeof_revision(component::TariffPartnerRole) :: Type{TariffPartnerRoleRevision}
"""
function BitemporalPostgres.get_typeof_revision(component::TariffPartnerRole)::Type{TariffPartnerRoleRevision}
  TariffPartnerRole
end

"""
BitemporalPostgres.get_typeof_component(revision::TariffPartnerRoleRevision) :: Type{TariffPartnerRole}
"""
function BitemporalPostgres.get_typeof_component(revision::TariffPartnerRoleRevision)::Type{TariffPartnerRole}
  TariffPartnerRole
end


end # module