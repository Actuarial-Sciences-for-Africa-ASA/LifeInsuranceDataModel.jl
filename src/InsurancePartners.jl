module InsurancePartners
import BitemporalPostgres
import SearchLight: DbId
import Base: @kwdef
export Partner, PartnerRevision
using BitemporalPostgres
using Dates

"""
BitemporalPostgres.revisionTypes(entity::Val{:Partner}) 
  defining the ComponentRevision types occurring in Contracts
"""
BitemporalPostgres.revisionTypes(entity::Val{:Partner}) = [PartnerRevision]

"""
Partner

  a component of a bitemporal entity

"""
@kwdef mutable struct Partner <: BitemporalPostgres.Component
  id::DbId = DbId()
  ref_history::DbId = InfinityKey
  ref_version::DbId = InfinityKey
end

"""
Partner_Revision

  a revision of a Partner component of a bitemporal entity

"""
@kwdef mutable struct PartnerRevision <: BitemporalPostgres.ComponentRevision
  id::DbId = DbId()
  ref_component::DbId = InfinityKey
  ref_validfrom::DbId = InfinityKey
  ref_invalidfrom::DbId = InfinityKey
  description::String = ""
  date_of_birth::Date = Date(2000, 1, 1)
end

Base.copy(src::PartnerRevision) = PartnerRevision(
  ref_component=src.ref_component,
  description=src.description)
end