using BitemporalPostgres, LifeInsuranceDataModel, TimeZones, Dates

function fn(ns::Vector{Dict{String,Any}}, v::String)
    for n in ns
        if (n["version"] == v)
            return (n)
        else
            if (length(n["children"]) > 0)
                m = fn(n["children"], v)
                if !isnothing((m))
                    return m
                end
            end
        end
    end
end


# function convert(node::BitemporalPostgres.Node)::Dict{String,Any}
#     i = Dict(string(fn) => getfield(getfield(node, :interval), fn) for fn in fieldnames(ValidityInterval))
#     shdw = length(node.shadowed) == 0 ? [] : map(node.shadowed) do child
#         convert(child)
#     end
#     Dict("version" => string(i["ref_version"]), "interval" => i, "children" => shdw, "label" => "committed " * string(i["tsdb_validfrom"]) * " valid as of " * string(Date(i["tsworld_validfrom"], UTC)))
# end

ENV["SEARCHLIGHT_USERNAME"] = ENV["USER"]
ENV["SEARCHLIGHT_PASSWORD"] = ENV["USER"]
#histo = map(convert, LifeInsuranceDataModel.history_forest(11).shadowed)
#
#res = fn(histo, "11")
#
#println(res)
#
#println(pwd())
# ZonedDateTime(Date("2025-12-01"), tz"UTC")
csection(1, now(tz"UTC"), MaxDate - Day(1), 0)