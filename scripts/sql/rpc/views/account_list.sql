DROP VIEW IF EXISTS {{SCHEMA}}.account_list;

CREATE VIEW {{SCHEMA}}.account_list AS
SELECT stake_address.view AS id
FROM stake_address;

COMMENT ON VIEW {{SCHEMA}}.account_list IS 'Get a list of all accounts';
