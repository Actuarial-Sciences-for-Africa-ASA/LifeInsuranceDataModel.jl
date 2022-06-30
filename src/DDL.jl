module DDL
import SearchLight: AbstractModel, DbId, query, save!
import SearchLight.Migrations:
    create_table, column, columns, primary_key, add_index, drop_table, add_indices
import SearchLightPostgreSQL
import Base: @kwdef
import Intervals, Dates, TimeZones, BitemporalPostgres
using BitemporalPostgres, Intervals,
    Dates, SearchLight, SearchLight.Transactions, SearchLightPostgreSQL, TimeZones
export up, down

function createRevisionsTriggerAndConstraint(
    trigger::Symbol,
    constraint::Symbol,
    table::Symbol,
)
    SearchLight.query("""
                      CREATE TRIGGER $trigger
                      BEFORE INSERT OR UPDATE ON $table
                      FOR EACH ROW EXECUTE PROCEDURE f_versionrange();
                      """)
    SearchLight.query(
        """
        ALTER TABLE $table
        ADD CONSTRAINT $constraint EXCLUDE USING GIST (ref_component WITH =, ref_valid WITH &&)
        """,
    )
end

function up()
    BitemporalPostgres.up()
    create_table(:contracts) do
        [
            column(:id, :bigserial, "PRIMARY KEY")
            column(:ref_history, :bigint, "REFERENCES histories(id) ON DELETE CASCADE")
            column(:ref_version, :bigint, "REFERENCES versions(id) ON DELETE CASCADE")
        ]
    end

    create_table(:contractRevisions) do
        [
            column(:id, :bigserial, "PRIMARY KEY")
            column(:ref_component, :bigint, "REFERENCES contracts(id) ON DELETE CASCADE")
            column(:ref_validfrom, :bigint, "REFERENCES versions(id) ON DELETE CASCADE")
            column(:ref_invalidfrom, :bigint, "REFERENCES versions(id) ON DELETE CASCADE")
            column(:ref_valid, :int8range)
            column(:description, :string)
        ]
    end

    createRevisionsTriggerAndConstraint(
        :cr_versions_trig,
        :contractsversionrange,
        :contractRevisions,
    )

    create_table(:productItems) do
        [
            column(:id, :bigserial, "PRIMARY KEY")
            column(:ref_history, :bigint, "REFERENCES histories(id) ON DELETE CASCADE")
            column(:ref_version, :bigint, "REFERENCES versions(id) ON DELETE CASCADE")
            column(:ref_super, :bigint, "REFERENCES contracts(id) ON DELETE CASCADE")
        ]
    end

    create_table(:productItemRevisions) do
        [
            column(:id, :bigserial, "PRIMARY KEY")
            column(
                :ref_component,
                :bigint,
                "REFERENCES productitems(id) ON DELETE CASCADE",
            )
            column(:position, :bigint)
            column(:ref_validfrom, :bigint, "REFERENCES versions(id) ON DELETE CASCADE")
            column(:ref_invalidfrom, :bigint, "REFERENCES versions(id) ON DELETE CASCADE")
            column(:ref_valid, :int8range)
            column(:description, :string)
        ]
    end

    createRevisionsTriggerAndConstraint(
        :pi_versions_trig,
        :pi_versionrange,
        :productitemRevisions,
    )

    create_table(:partners) do
        [
            column(:id, :bigserial, "PRIMARY KEY")
            column(:ref_history, :bigint, "REFERENCES histories(id) ON DELETE CASCADE")
            column(:ref_version, :bigint, "REFERENCES versions(id) ON DELETE CASCADE")
        ]
    end

    create_table(:partnerRevisions) do
        [
            column(:id, :bigserial, "PRIMARY KEY")
            column(:ref_component, :bigint, "REFERENCES partners(id) ON DELETE CASCADE")
            column(:ref_validfrom, :bigint, "REFERENCES versions(id) ON DELETE CASCADE")
            column(:ref_invalidfrom, :bigint, "REFERENCES versions(id) ON DELETE CASCADE")
            column(:ref_valid, :int8range)
            column(:description, :string)
        ]
    end

    createRevisionsTriggerAndConstraint(
        :pr_versions_trig,
        :pr_versionrange,
        :partnerRevisions,
    )

    create_table(:contractPartnerRoles) do
        [
            column(:id, :bigserial, "PRIMARY KEY")
            column(:domain, :string)
            column(:value, :string)
        ]
    end


    create_table(:contractPartnerRefs) do
        [
            column(:id, :bigserial, "PRIMARY KEY")
            column(:ref_history, :bigint, "REFERENCES histories(id) ON DELETE CASCADE")
            column(:ref_version, :bigint, "REFERENCES versions(id) ON DELETE CASCADE")
            column(:ref_super, :bigint, "REFERENCES contracts(id) ON DELETE CASCADE")
        ]
    end

    create_table(:contractPartnerRefRevisions) do
        [
            column(:id, :bigserial, "PRIMARY KEY")
            column(
                :ref_component,
                :bigint,
                "REFERENCES contractPartnerRefs(id) ON DELETE CASCADE",
            )
            column(:ref_role, :bigint, "REFERENCES contractpartnerroles(id) ON DELETE CASCADE")
            column(:ref_validfrom, :bigint, "REFERENCES versions(id) ON DELETE CASCADE")
            column(:ref_invalidfrom, :bigint, "REFERENCES versions(id) ON DELETE CASCADE")
            column(:ref_valid, :int8range)
            column(:description, :string)
            column(:ref_partner, :bigint, "REFERENCES partners(id) ON DELETE CASCADE")
        ]
    end

    createRevisionsTriggerAndConstraint(
        :cprr_versions_trig,
        :cprr_versionrange,
        :contractPartnerRefRevisions,
    )

    create_table(:tariffs) do
        [
            column(:id, :bigserial, "PRIMARY KEY")
            column(:ref_history, :bigint, "REFERENCES histories(id) ON DELETE CASCADE")
            column(:ref_version, :bigint, "REFERENCES versions(id) ON DELETE CASCADE")
        ]
    end

    create_table(:tariffRevisions) do
        [
            column(:id, :bigserial, "PRIMARY KEY")
            column(:ref_component, :bigint, "REFERENCES tariffs(id) ON DELETE CASCADE")
            column(:ref_validfrom, :bigint, "REFERENCES versions(id) ON DELETE CASCADE")
            column(:ref_invalidfrom, :bigint, "REFERENCES versions(id) ON DELETE CASCADE")
            column(:ref_valid, :int8range)
            column(:description, :string)
        ]
    end

    createRevisionsTriggerAndConstraint(
        :tr_versions_trig,
        :tr_versionrange,
        :tariffRevisions,
    )

    create_table(:TariffItemRoles) do
        [
            column(:id, :bigserial, "PRIMARY KEY")
            column(:domain, :string)
            column(:value, :string)
        ]
    end

    create_table(:TariffItems) do
        [
            column(:id, :bigserial, "PRIMARY KEY")
            column(:ref_history, :bigint, "REFERENCES histories(id) ON DELETE CASCADE")
            column(:ref_version, :bigint, "REFERENCES versions(id) ON DELETE CASCADE")
            column(:ref_super, :bigint, "REFERENCES productitems(id) ON DELETE CASCADE")
        ]
    end

    create_table(:TariffItemRevisions) do
        [
            column(:id, :bigserial, "PRIMARY KEY")
            column(:ref_component, :bigint, "REFERENCES tariffitems(id) ON DELETE CASCADE",)
            column(:ref_role, :bigint, "REFERENCES tariffitemroles(id) ON DELETE CASCADE")
            column(:ref_validfrom, :bigint, "REFERENCES versions(id) ON DELETE CASCADE")
            column(:ref_invalidfrom, :bigint, "REFERENCES versions(id) ON DELETE CASCADE")
            column(:ref_valid, :int8range)
            column(:description, :string)
            column(:ref_tariff, :bigint, "REFERENCES tariffs(id) ON DELETE CASCADE")
        ]
    end

    createRevisionsTriggerAndConstraint(
        :pitrr_versions_trig,
        :pitrr_versionrange,
        :TariffItemRevisions,
    )

    create_table(:TariffItemPartnerRoles) do
        [
            column(:id, :bigserial, "PRIMARY KEY")
            column(:domain, :string)
            column(:value, :string)
        ]
    end

    create_table(:TariffItemPartnerRefs) do
        [
            column(:id, :bigserial, "PRIMARY KEY")
            column(:ref_history, :bigint, "REFERENCES histories(id) ON DELETE CASCADE")
            column(:ref_version, :bigint, "REFERENCES versions(id) ON DELETE CASCADE")
            column(:ref_super, :bigint, "REFERENCES tariffitems(id) ON DELETE CASCADE")
        ]
    end

    create_table(:TariffItemPartnerRefRevisions) do
        [
            column(:id, :bigserial, "PRIMARY KEY")
            column(
                :ref_component,
                :bigint,
                "REFERENCES tariffitems(id) ON DELETE CASCADE",
            )
            column(:ref_role, :bigint, "REFERENCES tariffitempartnerroles(id) ON DELETE CASCADE")
            column(:ref_validfrom, :bigint, "REFERENCES versions(id) ON DELETE CASCADE")
            column(:ref_invalidfrom, :bigint, "REFERENCES versions(id) ON DELETE CASCADE")
            column(:ref_valid, :int8range)
            column(:description, :string)
            column(:ref_partner, :bigint, "REFERENCES partners(id) ON DELETE CASCADE")
        ]
    end

    createRevisionsTriggerAndConstraint(
        :piprr_versions_trig,
        :piprr_versionrange,
        :TariffItemPartnerRefRevisions,
    )

end

function down()
    BitemporalPostgres.DDL.down()
    drop_table(:contractRevisions)
    drop_table(:contracts)
    drop_table(:contractProductItems)
    drop_table(:contractProductItemRevisions)
    drop_table(:contractPartnerRefRevisions)
    drop_table(:contractPartnerRefs)
    drop_table(:tariffitemRevisions)
    drop_table(:tariffItems)
    drop_table(:tariffItemPartnerRefRevisions)
    drop_table(:tariffItemPartnerRefs)
    drop_table(:partnerRevisions)
    drop_table(:partners)
    drop_table(:tariffRevisions)
    drop_table(:tariffs)

end
end
