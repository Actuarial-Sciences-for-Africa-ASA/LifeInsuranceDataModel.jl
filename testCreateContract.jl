#loading packages
push!(LOAD_PATH, "src");
import Base: @kwdef
using Pkg
Pkg.activate(".")
Pkg.instantiate()
using Test
using LifeInsuranceDataModel
using BitemporalPostgres
using SearchLight
using SearchLightPostgreSQL
using TimeZones
using ToStruct
using JSON
# purging the data model entirely - empty the schema
LifeInsuranceDataModel.connect()
SearchLight.query("DROP SCHEMA public CASCADE")
SearchLight.query("CREATE SCHEMA public")
# Loading the data model- Create tables, constraints etc. and load Roles
# loading inverses of the role tables to provide role descriptions in object creation, for instance like in: "ref_role=cpRole["Policy Holder"]

LifeInsuranceDataModel.load_model()
@testset "CreateContract" begin

    cpRole = Dict{String,Int64}()
    map(find(LifeInsuranceDataModel.ContractPartnerRole)) do entry
        cpRole[entry.value] = entry.id.value
    end
    tiprRole = Dict{String,Int64}()
    map(find(LifeInsuranceDataModel.TariffItemPartnerRole)) do entry
        tiprRole[entry.value] = entry.id.value
    end
    titrRole = Dict{String,Int64}()
    map(find(LifeInsuranceDataModel.TariffItemRole)) do entry
        titrRole[entry.value] = entry.id.value
    end

    ppRole = Dict{String,Int64}()
    map(find(LifeInsuranceDataModel.ProductPartRole)) do entry
        ppRole[entry.value] = entry.id.value
    end

    # Or just connect to an existing model

    LifeInsuranceDataModel.connect()
    # Create a Partner

    p = LifeInsuranceDataModel.Partner()
    pr = LifeInsuranceDataModel.PartnerRevision(description="Partner 1", sex="f", smoker=false)
    w = Workflow(type_of_entity="Partner",
        tsw_validfrom=ZonedDateTime(2014, 5, 30, 21, 0, 1, 1, tz"UTC"),
    )
    create_entity!(w)
    create_component!(p, pr, w)
    commit_workflow!(w)

    Partner1 = p.id.value

    p = LifeInsuranceDataModel.Partner()
    pr = LifeInsuranceDataModel.PartnerRevision(description="Partner 2", sex="m", smoker=true)
    w = Workflow(type_of_entity="Partner",
        tsw_validfrom=ZonedDateTime(2014, 5, 30, 21, 0, 1, 1, tz"UTC"),
    )
    create_entity!(w)
    create_component!(p, pr, w)
    commit_workflow!(w)

    Partner2 = p.id.value

    tariffparameters = """
  {"n": {"type": "Int", "default": 0,"value":null},
   "m": {"type": "Int", "default": 0,"value":null},
   "begin": {"type": "Date", "default": "2020-01-01","value":null}
  }
    """
    contract_attributes = """
{"n": {"type": "Int", "default": 0,"value":null},
 "m": {"type": "Int", "default": 0,"value":null},
 "begin": {"type": "Date", "default": "2020-01-01","value":null}
}
  """

    LifeRiskTariff = create_tariff("Life Risk Insurance", 1, tariffparameters, contract_attributes)
    TerminalIllnessTariff = create_tariff("Terminal Illness", 2, tariffparameters, contract_attributes)
    OccupationalDisabilityTariff = create_tariff("Occupational Disability", 2, tariffparameters, contract_attributes)
    ProfitParticipationTariff = create_tariff("Profit participation", 2, tariffparameters, contract_attributes)
    LifeRiskTariff2 = create_tariff(
        "Two Life Risk Insurance", 2, "{}", contract_attributes, [1, 2])

    find(TariffRevision)
    find(Tariff, SQLWhereExpression("id=?", ProfitParticipationTariff))
    find(Tariff, SQLWhereExpression("id=?", TerminalIllnessTariff))

    # Create Product

    p = Product()
    pr = ProductRevision(interface_id=1, description="Life Risk")

    pp = ProductPart()
    ppr = ProductPartRevision(
        ref_tariff=LifeRiskTariff,
        ref_role=ppRole["Main Coverage - Life"],
        description="Main Coverage - Life",
    )

    pp2 = ProductPart()
    ppr2 = ProductPartRevision(
        ref_tariff=ProfitParticipationTariff,
        ref_role=ppRole["Profit participation"],
        description="Profit participation Lif Risk",
    )

    w0 = Workflow(
        type_of_entity="Product",
        tsw_validfrom=ZonedDateTime(2014, 5, 30, 21, 0, 1, 1, tz"UTC"),
    )
    create_entity!(w0)
    create_component!(p, pr, w0)
    create_subcomponent!(p, pp, ppr, w0)
    create_subcomponent!(p, pp2, ppr2, w0)
    commit_workflow!(w0)

    LifeRiskProduct = p.id.value
    println(LifeRiskProduct)

    p = Product()
    pr = ProductRevision(interface_id=2, description="Two Life Risk")

    pp = ProductPart()
    ppr = ProductPartRevision(
        ref_tariff=LifeRiskTariff2,
        ref_role=ppRole["Main Coverage - Life"],
        description="Main Coverage - Two Life",
    )

    pp2 = ProductPart()
    ppr2 = ProductPartRevision(
        ref_tariff=ProfitParticipationTariff,
        ref_role=ppRole["Profit participation"],
        description="Profit participation Two Life Risk",
    )

    w0 = Workflow(
        type_of_entity="Product",
        tsw_validfrom=ZonedDateTime(2014, 5, 30, 21, 0, 1, 1, tz"UTC"),
    )
    create_entity!(w0)
    create_component!(p, pr, w0)
    create_subcomponent!(p, pp, ppr, w0)
    create_subcomponent!(p, pp2, ppr2, w0)
    commit_workflow!(w0)

    TwoLifeRiskProduct = p.id.value
    println(TwoLifeRiskProduct)


    p = Product()
    pr = ProductRevision(interface_id=3, description="Life Risk - Terminal Illness")

    pp = ProductPart()
    ppr = ProductPartRevision(
        ref_tariff=LifeRiskTariff,
        ref_role=ppRole["Main Coverage - Life"],
        description="Main Coverage - Life",
    )

    pp2 = ProductPart()
    ppr2 = ProductPartRevision(
        ref_tariff=ProfitParticipationTariff,
        ref_role=ppRole["Profit participation"],
        description="Profit participation Life Risk",
    )

    pp3 = ProductPart()
    ppr3 = ProductPartRevision(
        ref_tariff=TerminalIllnessTariff,
        ref_role=ppRole["Supplementary Coverage - Terminal Illness"],
        description="additional cover Terminal Illness",
    )

    pp4 = ProductPart()
    ppr4 = ProductPartRevision(
        ref_tariff=ProfitParticipationTariff,
        ref_role=ppRole["Profit participation"],
        description="Profit participation Terminal Illness",
    )

    pp5 = ProductPart()
    ppr5 = ProductPartRevision(
        ref_tariff=OccupationalDisabilityTariff,
        ref_role=ppRole["Supplementary Coverage - Occupational Disablity"],
        description="additional cover Occupational Disablity",
    )

    pp6 = ProductPart()
    ppr6 = ProductPartRevision(
        ref_tariff=ProfitParticipationTariff,
        ref_role=ppRole["Profit participation"],
        description="Profit participation Occ.Disablity",
    )



    w0 = Workflow(
        type_of_entity="Product",
        tsw_validfrom=ZonedDateTime(2014, 5, 30, 21, 0, 1, 1, tz"UTC"),
    )
    create_entity!(w0)
    create_component!(p, pr, w0)
    create_subcomponent!(p, pp, ppr, w0)
    create_subcomponent!(p, pp2, ppr2, w0)
    create_subcomponent!(p, pp3, ppr3, w0)
    create_subcomponent!(p, pp4, ppr4, w0)
    create_subcomponent!(p, pp5, ppr5, w0)
    create_subcomponent!(p, pp6, ppr6, w0)
    commit_workflow!(w0)

    LifeRiskTIODProduct = p.id.value
    println(LifeRiskTIODProduct)

    # Testing

    # Create contract blue

    w1 = Workflow(
        type_of_entity="Contract",
        tsw_validfrom=ZonedDateTime(2014, 5, 30, 21, 0, 1, 1, tz"UTC"),
    )

    create_entity!(w1)
    c = Contract()
    cr = ContractRevision(description="contract creation properties")
    create_component!(c, cr, w1)

    cpr = ContractPartnerRef(ref_super=c.id)
    cprr = ContractPartnerRefRevision(
        ref_partner=Partner1,
        ref_role=cpRole["Policy Holder"],
        description="policiyholder ref properties",
    )
    create_subcomponent!(c, cpr, cprr, w1)
    # pi 1
    LifeRiskTIODProduct = find(Product, SQLWhereExpression("id=?", 2))[1].id.value
    PartnerroleMap = Dict{Integer,PartnerSection}()
    PartnerRole = tiprRole["Insured Person"]
    PartnerroleMap[PartnerRole] = psection(Partner1, now(tz"UTC"), w1.tsw_validfrom, 0)
    PartnerRole = tiprRole["2nd Insured Person"]
    PartnerroleMap[PartnerRole] = psection(Partner2, now(tz"UTC"), w1.tsw_validfrom, 0)

    cpi = ProductItem(ref_super=c.id)
    cpir = ProductItemRevision(
        ref_product=LifeRiskTIODProduct,
        description="from contract creation",
    )
    create_subcomponent!(c, cpi, cpir, w1)

    LifeInsuranceDataModel.create_product_instance(
        w1,
        cpi,
        LifeRiskTIODProduct,
        PartnerroleMap,
    )
    commit_workflow!(w1)
    # update Contract yellow

    cr1 = ContractRevision(ref_component=c.id, description="contract 1, 2nd mutation")
    w2 = Workflow(
        type_of_entity="Contract",
        ref_history=w1.ref_history,
        tsw_validfrom=ZonedDateTime(2016, 5, 30, 21, 0, 1, 1, tz"UTC"),
    )
    update_entity!(w2)
    update_component!(cr, cr1, w2)
    @test w2.ref_history == w1.ref_history
    commit_workflow!(w2)
    @test w2.ref_history == w1.ref_history
    # update Contract red
    w3 = Workflow(
        type_of_entity="Contract",
        ref_history=w2.ref_history,
        tsw_validfrom=ZonedDateTime(2015, 5, 30, 21, 0, 1, 1, tz"UTC"),
    )
    update_entity!(w3)
    cr1 = findcomponentrevision(ContractRevision, c.id, w3.ref_version)[1]
    cr2 = ContractRevision(ref_component=c.id, description="contract 1, 3rd mutation retrospective")
    update_component!(cr1, cr2, w3)


    commit_workflow!(w3)
    @test w3.ref_history == w2.ref_history

    w4 = Workflow(
        type_of_entity="Contract",
        ref_history=w2.ref_history,
        tsw_validfrom=ZonedDateTime(2018, 5, 30, 21, 0, 1, 1, tz"UTC"),
    )
    update_entity!(w4)
    cr3 = ContractRevision(ref_component=c.id, description="contract 1, 4th mutation")
    update_component!(cr2, cr3, w4)

    # pi 2
    LifeRiskTIODProduct = find(Product, SQLWhereExpression("id=?", 2))[1].id.value
    PartnerRole = tiprRole["Insured Person"]

    cpi = ProductItem(ref_super=c.id)
    cpir = ProductItemRevision(
        ref_product=LifeRiskTIODProduct,
        description="from contract 4th mutation",
    )
    create_subcomponent!(c, cpi, cpir, w4)

    println("vor neuem Teil")


    LifeInsuranceDataModel.create_product_instance(
        w4,
        cpi,
        LifeRiskTIODProduct,
        PartnerroleMap,
    )
    commit_workflow!(w4)

end # testset create contract

@testset "get_typeof methods" begin
    t = ContractRevision
    @test get_typeof_revision(get_typeof_component(t())()) == t
    t = TariffItemRevision
    @test get_typeof_revision(get_typeof_component(t())()) == t
end

@testset "get_typeof methods" begin
    for t in [ContractRevision, ContractPartnerRefRevision, ProductItemRevision, TariffItemRevision, TariffItemPartnerRefRevision]

        @test get_typeof_revision(get_typeof_component(t())()) == t
    end
end



using BitemporalPostgres, SearchLight
history = 9
txntime = MaxDate

res = SearchLight.query(
    "select s.tsdb_invalidfrom as sdbinv, m.tsdb_validfrom as mdbval, 
m.tsworld_validfrom as mwval, s.tsworld_validfrom as swval,m.tsworld_invalidfrom as mwinv,s.tsworld_invalidfrom as swinv, 
m.id as mid, s.id as sid , m.ref_history as mh , m.ref_version as mv , s.ref_version as sv
from validityintervals m join validityintervals s 
on m.ref_history=s.ref_history
and m.ref_version != s.ref_version
and m.tsdb_validfrom = s.tsdb_invalidfrom
and m.tsworld_validfrom <= s.tsworld_validfrom 
--and tstzrange(m.tsworld_validfrom, m.tsworld_invalidfrom) @> s.tsworld_validfrom -- tstzrange(s.tsworld_validfrom,s.tsworld_invalidfrom)
where m.ref_history=$history
and m.tsdb_invalidfrom = TIMESTAMPTZ '$txntime'",
)

println(res)

txns = SearchLight.query("select tsdb_validfrom as vf from validityintervals union
                         select tsdb_invalidfrom as vf from validityintervals 
                         group by vf order by vf")

refs = SearchLight.query("select tsworld_validfrom as vf from validityintervals union
                         select tsworld_invalidfrom as vf from validityintervals 
                         group by vf order by vf")

println(txns)

println(refs)

txnDict = Dict()
for i = 1:first(size(txns))
    txnDict[txns[i, 1]] = i
end


refDict = Dict()
for i = 1:first(size(refs))
    refDict[refs[i, 1]] = i
end

println(txnDict)

println(refDict)

using BitemporalPostgres
valints = find(ValidityInterval)


vi = valints[1]