CREATE TABLE IF NOT EXISTS package_name
(
    id   INT GENERATED BY DEFAULT AS IDENTITY NOT NULL PRIMARY KEY,
    name TEXT                                 NOT NULL CHECK (NOT empty(name)) UNIQUE
);

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE package_name TO vmaas_sync;
GRANT SELECT ON TABLE package_name TO evaluator;
GRANT SELECT ON TABLE package_name TO listener;
GRANT SELECT ON TABLE package_name TO manager;

GRANT SELECT, USAGE ON SEQUENCE package_name_id_seq TO evaluator;
GRANT SELECT, USAGE ON SEQUENCE package_name_id_seq TO listener;
GRANT SELECT, USAGE ON SEQUENCE package_name_id_seq TO vmaas_sync;

CREATE TABLE IF NOT EXISTS strings
(
    id    BYTEA NOT NULL PRIMARY KEY,
    value TEXT  NOT NULL
);

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE strings TO vmaas_sync;
GRANT SELECT ON TABLE strings TO evaluator;
GRANT SELECT ON TABLE strings TO listener;
GRANT SELECT ON TABLE strings TO manager;

CREATE TABLE IF NOT EXISTS package
(
    id               INT GENERATED BY DEFAULT AS IDENTITY NOT NULL PRIMARY KEY,
    name_id          INT                                  NOT NULL REFERENCES package_name,
    evra             TEXT                                 NOT NULL CHECK (NOT empty(evra)),
    description_hash BYTEA                                NOT NULL REFERENCES strings (id),
    summary_hash     BYTEA                                NOT NULL REFERENCES strings (id),
    UNIQUE (name_id, evra)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE package TO vmaas_sync;
GRANT SELECT ON TABLE package TO evaluator;
GRANT SELECT ON TABLE package TO listener;
GRANT SELECT ON TABLE package TO manager;

GRANT SELECT, USAGE ON SEQUENCE package_id_seq TO evaluator;
GRANT SELECT, USAGE ON SEQUENCE package_id_seq TO listener;
GRANT SELECT, USAGE ON SEQUENCE package_id_seq TO vmaas_sync;

CREATE TABLE IF NOT EXISTS system_package
(
    system_id   INT NOT NULL REFERENCES system_platform,
    package_id  INT NOT NULL REFERENCES package,
    -- Use null to represent up-to-date packages
    update_data JSONB DEFAULT NULL,
    PRIMARY KEY (system_id, package_id)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE system_package TO evaluator;
GRANT SELECT ON TABLE system_package TO listener;
GRANT SELECT ON TABLE system_package TO manager;
GRANT SELECT ON TABLE system_package TO vmaas_sync;

ALTER TABLE system_platform
    DROP COLUMN IF EXISTS package_data;

