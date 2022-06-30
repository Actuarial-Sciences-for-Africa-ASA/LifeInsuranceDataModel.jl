import Base: @kwdef
using Test
using InsuranceContractsController
using BitemporalPostgres
using SearchLight
using SearchLightPostgreSQL
using TimeZones
using ToStruct
using JSON
using HTTP

if (haskey(ENV, "GENIE_ENV") && ENV["GENIE_ENV"] == "dev")
    run(```sudo -u postgres psql -f sqlsnippets/droptables.sql```)
end


@testset "CreateContract" begin

    SearchLight.Configuration.load() |> SearchLight.connect
    SearchLight.Migrations.create_migrations_table()
    SearchLight.Migrations.up()

    contractpartnerroles = map(["Policy Holder" "Premium Payer"]) do val
        save!(ContractPartnerRole(value=val))
    end
    tariffitempartnerroles = map(["Insured Person" "2nd Insured Person"]) do val
        save!(TariffItemPartnerRole(value=val))
    end
    tariffitemtariffroles = map(["Main Coverage - Life" "Supplementary Coverage - Occupational Disablity" "Supplementary Coverage - Terminal Illness" "Profit participation"]) do val
        save!(TariffItemRole(value=val))
    end

    cpRole = Dict{String,Int64}()
    map(find(InsuranceContractsController.ContractPartnerRole)) do entry
        cpRole[entry.value] = entry.id.value
    end
    piprRole = Dict{String,Int64}()
    map(find(InsuranceContractsController.TariffItemPartnerRole)) do entry
        piprRole[entry.value] = entry.id.value
    end
    pitrRole = Dict{String,Int64}()
    map(find(InsuranceContractsController.TariffItemRole)) do entry
        pitrRole[entry.value] = entry.id.value
    end

    # create Partner
    p = InsuranceContractsController.Partner()
    pr = InsuranceContractsController.PartnerRevision(description="Partner 1")
    w = Workflow(
        tsw_validfrom=ZonedDateTime(2014, 5, 30, 21, 0, 1, 1, tz"Africa/Porto-Novo"),
    )
    create_entity!(w)
    create_component!(p, pr, w)
    commit_workflow!(w)

    # create Tariffs
    t = InsuranceContractsController.Tariff()
    tr = InsuranceContractsController.TariffRevision(description="Life Risk Insurance")
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
    cpir = ProductItemRevision(position=1, description="from contract creation")
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

hforest = mkforest(DbId(3), MaxDate, ZonedDateTime(1900, 1, 1, 0, 0, 0, 0, tz"UTC"), MaxDate)
print_tree(hforest)

