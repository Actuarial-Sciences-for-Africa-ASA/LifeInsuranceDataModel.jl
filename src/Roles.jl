module Roles
import SearchLight.AbstractModel

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


end