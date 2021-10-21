WITH panels AS (
    SELECT
        asset.asset_pk panel_pk,
        asset.name panel_name
    FROM
        view_asset_v1 asset
    WHERE
        asset.assettype_fk = 15
),
powerunits AS (
    SELECT
        pdu.pdu_pk powerunit_pk,
        pdu.name powerunit_name,
        pducff."Panel" powerunit_panel
    FROM
        view_pdu_v1 pdu
    JOIN
        view_pdu_custom_fields_flat_v1 pducff ON pducff.pdu_fk = pdu.pdu_pk
)
SELECT
    panel_pk,
    panel_name,
    powerunit_pk,
    powerunit_name
FROM
    panels
    JOIN powerunits ON panel_name = powerunit_panel