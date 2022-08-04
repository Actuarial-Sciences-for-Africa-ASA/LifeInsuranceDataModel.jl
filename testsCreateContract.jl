
import Base: @kwdef
using Test
using LifeInsuranceDataModel

using BitemporalPostgres
using SearchLight
using SearchLightPostgreSQL
using TimeZones
using ToStruct
using JSON

if (haskey(ENV, "GENIE_ENV") && ENV["GENIE_ENV"] == "dev")
    if (haskey(ENV, "GITPOD_REPO_ROOT"))
        run(```psql -f sqlsnippets/droptables.sql```)
    else
        run(```sudo -u postgres psql -f sqlsnippets/droptables.sql```)
    end
end

LifeInsuranceDataModel.load_model()

@testset "CreateContract" begin

    cpRole = Dict{String,Int64}()
    map(find(LifeInsuranceDataModel.ContractPartnerRole)) do entry
        cpRole[entry.value] = entry.id.value
    end
    piprRole = Dict{String,Int64}()
    map(find(LifeInsuranceDataModel.TariffItemPartnerRole)) do entry
        piprRole[entry.value] = entry.id.value
    end
    pitrRole = Dict{String,Int64}()
    map(find(LifeInsuranceDataModel.TariffItemRole)) do entry
        pitrRole[entry.value] = entry.id.value
    end

    ppRole = Dict{String,Int64}()
    map(find(LifeInsuranceDataModel.ProductPartRole)) do entry
        ppRole[entry.value] = entry.id.value
    end


    # create Partner
    p = LifeInsuranceDataModel.Partner()
    pr = LifeInsuranceDataModel.PartnerRevision(description="Partner 1")
    w = Workflow(
        tsw_validfrom=ZonedDateTime(2014, 5, 30, 21, 0, 1, 1, tz"Africa/Porto-Novo"),
    )
    create_entity!(w)
    create_component!(p, pr, w)
    commit_workflow!(w)

    # create Tariffs
    t = LifeInsuranceDataModel.Tariff()
    tr = LifeInsuranceDataModel.TariffRevision(description="Life Risk Insurance")
    w0 = Workflow(
        tsw_validfrom=ZonedDateTime(2014, 5, 30, 21, 0, 1, 1, tz"Africa/Porto-Novo"),
    )
    create_entity!(w0)
    create_component!(t, tr, w0)
    commit_workflow!(w0)

    t2 = Tariff()
    tr2 = TariffRevision(description="Terminal Illness")
    w0 = Workflow(
        tsw_validfrom=ZonedDateTime(2014, 5, 30, 21, 0, 1, 1, tz"Africa/Porto-Novo"),
    )
    create_entity!(w0)
    create_component!(t2, tr2, w0)
    commit_workflow!(w0)

    t3 = Tariff()
    tr3 = TariffRevision(description="Occupational Disability")
    w0 = Workflow(
        tsw_validfrom=ZonedDateTime(2014, 5, 30, 21, 0, 1, 1, tz"Africa/Porto-Novo"),
    )

    create_entity!(w0)
    create_component!(t3, tr3, w0)
    commit_workflow!(w0)

    t4 = Tariff()
    tr4 = TariffRevision(description="Profit participation")
    w0 = Workflow(
        tsw_validfrom=ZonedDateTime(2014, 5, 30, 21, 0, 1, 1, tz"Africa/Porto-Novo"),
    )
    create_entity!(w0)
    create_component!(t4, tr4, w0)
    commit_workflow!(w0)

    p = Product()
    pr = ProductRevision(description="Life Risk")

    pp = ProductPart()
    ppr = ProductPartRevision(ref_tariff=t.id, ref_role=ppRole["Main Coverage - Life"], description="Main Coverage - Life")

    pp2 = ProductPart()
    ppr2 = ProductPartRevision(ref_tariff=t4.id, ref_role=ppRole["Profit participation"], description="Profit participation Lif Risk")

    w0 = Workflow(
        tsw_validfrom=ZonedDateTime(2014, 5, 30, 21, 0, 1, 1, tz"Africa/Porto-Novo"),
    )
    create_entity!(w0)
    create_component!(p, pr, w0)
    create_subcomponent!(p, pp, ppr, w0)
    create_subcomponent!(p, pp2, ppr2, w0)
    commit_workflow!(w0)

    p1 = Product()
    pr1 = ProductRevision(description="Life Risk Terminal")

    pp1 = ProductPart()
    ppr1 = ProductPartRevision(ref_tariff=t.id, ref_role=ppRole["Main Coverage - Life"], description="Main Coverage - Life")

    pp12 = ProductPart()
    ppr12 = ProductPartRevision(ref_tariff=t4.id, ref_role=ppRole["Profit participation"], description="Profit participation Life Risk")

    pp13 = ProductPart()
    ppr13 = ProductPartRevision(ref_tariff=t4.id, ref_role=ppRole["Supplementary Coverage - Terminal Illness"], description="Terminal Illness")

    w0 = Workflow(
        tsw_validfrom=ZonedDateTime(2014, 5, 30, 21, 0, 1, 1, tz"Africa/Porto-Novo"),
    )
    create_entity!(w0)
    create_component!(p1, pr1, w0)
    create_subcomponent!(p1, pp1, ppr1, w0)
    create_subcomponent!(p1, pp12, ppr12, w0)
    create_subcomponent!(p1, pp13, ppr13, w0)
    commit_workflow!(w0)

    p2 = Product()
    pr2 = ProductRevision(description="Life Risk Occupational")

    pp2 = ProductPart()
    ppr2 = ProductPartRevision(ref_tariff=t.id, ref_role=ppRole["Main Coverage - Life"], description="Main Coverage - Life")

    pp21 = ProductPart()
    ppr21 = ProductPartRevision(ref_tariff=t4.id, ref_role=ppRole["Profit participation"], description="Profit participation Life Risk")

    pp22 = ProductPart()
    ppr22 = ProductPartRevision(ref_tariff=t4.id, ref_role=ppRole["Supplementary Coverage - Occupational Disablity"], description="Occupational Disability")

    pp23 = ProductPart()
    ppr23 = ProductPartRevision(ref_tariff=t4.id, ref_role=ppRole["Profit participation"], description="Profit participation Occ.Disablity")

    w0 = Workflow(
        tsw_validfrom=ZonedDateTime(2014, 5, 30, 21, 0, 1, 1, tz"Africa/Porto-Novo"),
    )
    create_entity!(w0)
    create_component!(p2, pr2, w0)
    create_subcomponent!(p2, pp2, ppr2, w0)
    create_subcomponent!(p2, pp21, ppr21, w0)
    create_subcomponent!(p2, pp22, ppr22, w0)
    create_subcomponent!(p2, pp23, ppr23, w0)
    commit_workflow!(w0)


    # create Contract
    w1 = Workflow(
        tsw_validfrom=ZonedDateTime(2014, 5, 30, 21, 0, 1, 1, tz"Africa/Porto-Novo"),
    )

    create_entity!(w1)
    c = Contract()
    cr = ContractRevision(description="contract creation properties")
    create_component!(c, cr, w1)

    cpr = ContractPartnerRef(ref_super=c.id)
    cprr = ContractPartnerRefRevision(ref_partner=p.id, ref_role=cpRole["Policy Holder"], description="policiyholder ref properties")
    create_subcomponent!(c, cpr, cprr, w1)
    # pi 1
    cpi = ProductItem(ref_super=c.id)
    cpir = ProductItemRevision(position=1, ref_product=p.id, description="from contract creation")
    create_subcomponent!(c, cpi, cpir, w1)
    # pi 1 ti 1 
    pit = TariffItem(ref_super=cpi.id)
    pitr = TariffItemRevision(ref_tariff=t.id, ref_role=pitrRole["Main Coverage - Life"], description="Life Risk tariff parameters")
    create_subcomponent!(cpi, pit, pitr, w1)
    # pi 1 ti 1 p 1
    pitp = TariffItemPartnerRef(ref_super=pit.id)
    pitpr = TariffItemPartnerRefRevision(ref_partner=p.id, ref_role=piprRole["Insured Person"], description="partner 1 ref properties")
    create_subcomponent!(pit, pitp, pitpr, w1)

    # pi 1 ti 2 
    pit = TariffItem(ref_super=cpi.id)
    pitr = TariffItemRevision(ref_tariff=t4.id, ref_role=pitrRole["Profit participation"], description="Profit participation tariff parameters")
    create_subcomponent!(cpi, pit, pitr, w1)
    # pi 1 ti 2 p 1
    pitp = TariffItemPartnerRef(ref_super=pit.id)
    pitpr = TariffItemPartnerRefRevision(ref_partner=p.id, ref_role=piprRole["Insured Person"], description="partner 1 ref properties")
    create_subcomponent!(pit, pitp, pitpr, w1)

    commit_workflow!(w1)

    # end

    # update Contract yellow
    # @testset "UpdateContractYellow" begin

    cr1 = ContractRevision(ref_component=c.id, description="contract 1, 2nd mutation")
    w2 = Workflow(
        ref_history=w1.ref_history,
        tsw_validfrom=ZonedDateTime(2016, 5, 30, 21, 0, 1, 1, tz"Africa/Porto-Novo"),
    )
    update_entity!(w2)
    update_component!(cr, cr1, w2)
    commit_workflow!(w2)
    @test w2.ref_history == w1.ref_history

    # nd

    # update Contract red
    # @testset "UpdateContractRed" begin
    cr2 = ContractRevision(ref_component=c.id, description="contract 1, 3rd mutation retrospective")
    w3 = Workflow(
        ref_history=w2.ref_history,
        tsw_validfrom=ZonedDateTime(2015, 5, 30, 21, 0, 1, 1, tz"Africa/Porto-Novo"),
    )
    update_entity!(w3)
    update_component!(cr1, cr2, w3)
    commit_workflow!(w3)
    @test w3.ref_history == w2.ref_history

    # end of mutations
end

hforest = mkforest(DbId(3))
print_tree(hforest)

