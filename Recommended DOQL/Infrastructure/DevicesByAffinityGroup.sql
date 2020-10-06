/* getting all view_deviceaffinity_v2 records for specific Affinity Group chart 
    2/28/2020
      Data records should support default Affinity Group Chart 
      Note: Will need to add &affinity_group_pk=<affinity group pk or id> to the Saved DOQL URL.
*/
WITH RECURSIVE 
  impact AS ( -- impact report
  SELECT da1.*
  FROM view_deviceaffinity_v2 AS da1, src
  WHERE da1.dependency_device_fk = src.primary_device_fk
        AND da1.effective_from <= src.effective_on
        AND (da1.effective_to IS NULL OR da1.effective_to > src.effective_on)
  UNION
  SELECT da2.*
  FROM view_deviceaffinity_v2 AS da2, impact AS dep, src
  WHERE da2.dependency_device_fk = dep.dependent_device_fk
        AND da2.effective_from <= src.effective_on
        AND (da2.effective_to IS NULL OR da2.effective_to > src.effective_on)
), 
  dependency AS ( -- dependency report
  SELECT da1.*
  FROM view_deviceaffinity_v2 AS da1, src
  WHERE da1.dependent_device_fk = src.primary_device_fk
        AND da1.effective_from <= src.effective_on
        AND (da1.effective_to IS NULL OR da1.effective_to > src.effective_on)
  UNION
  SELECT da2.*
  FROM view_deviceaffinity_v2 AS da2, dependency AS dep, src
  WHERE da2.dependent_device_fk = dep.dependency_device_fk
        AND da2.effective_from <= src.effective_on
        AND (da2.effective_to IS NULL OR da2.effective_to > src.effective_on)
), 
src AS (
    SELECT
      last_processed AS effective_on, -- we need only effective now records
      primary_device_fk,
      report_type_id
    FROM view_affinitygroup_v2
    WHERE affinitygroup_pk = {affinity_group_pk} -- specify Affinity Group pk
)
SELECT Distinct
  dependency.*
   FROM dependency, src
   WHERE src.report_type_id = 1
 UNION
SELECT Distinct
  impact.*
   FROM impact, src
   WHERE src.report_type_id = 0;