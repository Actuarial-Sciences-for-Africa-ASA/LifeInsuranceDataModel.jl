module InsuranceTariffs
import BitemporalPostgres
import SearchLight: DbId
import Base: @kwdef
export Tariff, TariffRevision
using BitemporalPostgres

"""
Tariff

  a component of a bitemporal entity

"""
@kwdef mutable struct Tariff <: BitemporalPostgres.Component
  id::DbId = DbId()
  ref_history :: DbId = InfinityKey  
  ref_version :: DbId = InfinityKey  
end

"""
Tariff_Revision

  a revision of a Tariff component of a bitemporal entity

"""
@kwdef mutable struct TariffRevision <: BitemporalPostgres.ComponentRevision
  id::DbId = DbId()
  ref_component :: DbId = InfinityKey   
  ref_validfrom::DbId = InfinityKey 
  ref_invalidfrom::DbId = InfinityKey 
  description::String = ""
end

end # module