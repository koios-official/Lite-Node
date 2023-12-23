DROP VIEW IF EXISTS {{SCHEMA}}.asset_list;

CREATE VIEW {{SCHEMA}}.asset_list AS
SELECT
  ENCODE(ma.policy, 'hex') AS policy_id,
  ENCODE(ma.name, 'hex') AS asset_name,
  ma.fingerprint
FROM public.multi_asset AS ma
ORDER BY ma.policy, ma.name;

COMMENT ON VIEW {{SCHEMA}}.asset_list IS 'Get the list of all native assets';
