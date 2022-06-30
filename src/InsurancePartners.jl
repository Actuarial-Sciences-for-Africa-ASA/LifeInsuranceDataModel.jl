module InsurancePartners
import BitemporalPostgres
import SearchLight: DbId
import Base: @kwdef
export Partner, PartnerRevision
using BitemporalPostgres
"""
Partner

  a component of a bitemporal entity

"""
@kwdef mutable struct Partner <: BitemporalPostgres.Component
  id::DbId = DbId()
  ref_history :: DbId = InfinityKey  
  ref_version :: DbId = InfinityKey  
end

"""
Partner_Revision

  a revision of a Partner component of a bitemporal entity

"""
@kwdef mutable struct PartnerRevision <: BitemporalPostgres.ComponentRevision
  id::DbId = DbId()
  ref_component :: DbId = InfinityKey   
  ref_validfrom::DbId = InfinityKey 
  ref_invalidfrom::DbId = InfinityKey 
  description::String = ""
end

end