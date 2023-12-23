CREATE OR REPLACE FUNCTION {{SCHEMA}}.asset_txo_cache_update()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  IF (
    SELECT COUNT(pid) > 1
    FROM pg_stat_activity
    WHERE state = 'active'
      AND query ILIKE '%{{SCHEMA}}.asset_txo_cache_update%'
      AND datname = (SELECT current_database())
  ) THEN
    RAISE EXCEPTION 'Previous asset_txo_cache_update query still running but should have completed! Exiting...';
  END IF;

  CREATE TEMP TABLE tmp_ma AS (
    SELECT ma1.id
    FROM {{SCHEMA}}.asset_cache_control AS acc1
      LEFT JOIN multi_asset AS ma1 ON ma1.policy = acc1.policy
      LEFT JOIN {{SCHEMA}}.asset_tx_out_cache AS atoc1 ON ma1.id = atoc1.ma_id
    WHERE atoc1.ma_id IS NULL
  );

  WITH
    ma_filtered AS
      (
        (SELECT
          mto.tx_out_id,
          mto.quantity,
          mto.ident
        FROM {{SCHEMA}}.asset_cache_control AS acc
          LEFT JOIN multi_asset AS ma ON ma.policy = acc.policy
          LEFT JOIN ma_tx_out AS mto ON mto.ident = ma.id
        WHERE ma.id IN
          (SELECT id FROM tmp_ma)
        )
        UNION ALL
        (
          SELECT
            mto.tx_out_id,
            mto.quantity,
            mto.ident
          FROM {{SCHEMA}}.asset_cache_control AS acc
            LEFT JOIN multi_asset AS ma ON ma.policy = acc.policy
            LEFT JOIN ma_tx_out AS mto ON mto.ident = ma.id
          WHERE mto.tx_out_id > (SELECT COALESCE(MAX(atoc.txo_id),0) FROM {{SCHEMA}}.asset_tx_out_cache AS atoc)
        )
      )
  INSERT INTO {{SCHEMA}}.asset_tx_out_cache
    SELECT
      mf.ident,
      mf.tx_out_id,
      mf.quantity
    FROM ma_filtered AS mf
      LEFT JOIN tx_out AS txo ON mf.tx_out_id = txo.id
    WHERE txo.consumed_by_tx_in_id IS NULL AND txo.id < (SELECT MAX(id) from tx_out)
  ;

  DELETE FROM {{SCHEMA}}.asset_tx_out_cache WHERE txo_id IN
    (SELECT atoc.txo_id
      FROM {{SCHEMA}}.asset_tx_out_cache AS atoc
        LEFT JOIN tx_out AS txo ON atoc.txo_id = txo.id
        WHERE txo.consumed_by_tx_in_id IS NOT NULL
          OR txo.id IS NULL);
  DROP TABLE tmp_ma;

END;
$$;
