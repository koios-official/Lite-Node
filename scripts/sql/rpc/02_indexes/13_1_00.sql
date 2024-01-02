/* Indexes additional to vanila dbsync instance */
CREATE UNIQUE INDEX IF NOT EXISTS unique_col_txin ON public.collateral_tx_in USING btree (tx_in_id, tx_out_id, tx_out_index);
CREATE UNIQUE INDEX IF NOT EXISTS unique_col_txout ON public.collateral_tx_out USING btree (tx_id, index);
CREATE UNIQUE INDEX IF NOT EXISTS unique_epoch_param ON public.epoch_param USING btree (epoch_no, block_id);
CREATE UNIQUE INDEX IF NOT EXISTS unique_ma_tx_mint ON public.ma_tx_mint USING btree (ident, tx_id);
CREATE UNIQUE INDEX IF NOT EXISTS unique_ma_tx_out ON public.ma_tx_out USING btree (ident, tx_out_id DESC);
CREATE UNIQUE INDEX IF NOT EXISTS unique_param_proposal ON public.param_proposal USING btree (key, registered_tx_id);
CREATE UNIQUE INDEX IF NOT EXISTS unique_pot_transfer ON public.pot_transfer USING btree (tx_id, cert_index);
CREATE UNIQUE INDEX IF NOT EXISTS unique_redeemer ON public.redeemer USING btree (tx_id, purpose, index);
CREATE UNIQUE INDEX IF NOT EXISTS unique_ref_tx_in ON reference_tx_in USING btree (tx_in_id, tx_out_id, tx_out_index);
CREATE UNIQUE INDEX IF NOT EXISTS unique_tx_metadata ON public.tx_metadata USING btree (key, tx_id);
CREATE INDEX IF NOT EXISTS idx_ma_tx_out_ident ON ma_tx_out (ident) INCLUDE (tx_out_id, quantity);
CREATE INDEX IF NOT EXISTS idx_collateral_tx_in_tx_in_id ON collateral_tx_in (tx_in_id);
CREATE INDEX IF NOT EXISTS idx_reference_tx_in_tx_in_id ON reference_tx_in (tx_in_id);
