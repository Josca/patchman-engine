\timing on

-- constants to drive number of items generateg
create table if not exists _const (
    key text primary key,
    val int
);

insert into _const values   
    ('accounts',   50),     -- 5000     -- number of rh_accounts
    ('systems',    7500),   -- 750000   -- number of systems(_platform)
    ('advisories', 320),    -- 32000    -- number of advisory_metadata
    ('adv_per_system', 10)  -- ??       -- should be system_advisories/systems
                            -- ^ counts in prod
    on conflict do nothing;

-- prepare some pseudorandom vmaas jsons
create table if not exists _json (
    id int primary key,
    data text,
    hash text
);
insert into _json values 
    (1, '{ "package_list": [ "kernel-2.6.32-696.20.1.el6.x86_64" ]}'),
    (2, '{ "package_list": [ "libsmbclient-4.6.2-12.el7_4.x86_64", "dconf-0.26.0-2.el7.x86_64", "texlive-mdwtools-doc-svn15878.1.05.4-38.el7.noarch", "python34-pyroute2-0.4.13-1.el7.noarch", "python-backports-ssl_match_hostname-3.4.0.2-4.el7.noarch", "ghc-aeson-0.6.2.1-3.el7.x86_64"]}'),
    (3, '{ "repository_list": [ "rhel-7-server-rpms" ], "releasever": "7Server", "basearch": "x86_64", "package_list": [ "libsmbclient-4.6.2-12.el7_4.x86_64", "dconf-0.26.0-2.el7.x86_64"]}')
    on conflict do nothing;
update _json set hash = encode(sha256(data::bytea), 'hex');



-- generate rh_accounts
-- duration: 250ms / 5000 accounts (on RDS)
alter sequence rh_account_id_seq restart with 1;
do $$
  declare
    cnt int :=0;
    wanted int;
    id int;
  begin
    --select count(*) into cnt from rh_account;
    select val into wanted from _const where key = 'accounts';
    while cnt < wanted loop
        id := nextval('rh_account_id_seq');
        insert into rh_account (id, name)
        values (id, 'RHACCOUNT-' || id );
        cnt := cnt + 1;
    end loop;
  end;
$$
;


-- generate systems
-- duration: 55s / 750k systems (on RDS)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
alter sequence system_platform_id_seq restart with 1;
do $$
  declare
    cnt int := 0;
    wanted int;
    gen_uuid uuid;
    rh_accounts int;
    rnd float;
    json_data text[];
    json_hash text[];
    json_rnd int;
    rnd_date1 timestamp with time zone;
    rnd_date2 timestamp with time zone;
  begin
    --select count(*) into cnt from system_platform;
    select val into wanted from _const where key = 'systems';
    select count(*) into rh_accounts from rh_account;
    json_data := array(select data from _json order by id);
    json_hash := array(select hash from _json order by id);
    while cnt < wanted loop
        gen_uuid := uuid_generate_v4();
        rnd := random();
        rnd_date1 := now() - make_interval(days => (rnd*30)::int);
        rnd_date2 := rnd_date1 + make_interval(days => (rnd*10)::int);
        insert into system_platform
            (inventory_id, display_name, rh_account_id, vmaas_json, json_checksum, first_reported, last_updated, unchanged_since, last_upload, packages_installed, packages_updatable)
        values
            (gen_uuid, gen_uuid, trunc(rnd*rh_accounts)+1, json_data[trunc(rnd*3)], json_hash[trunc(rnd*3)], rnd_date1, rnd_date2, rnd_date1, rnd_date2, trunc(rnd*1000), trunc(rnd*50))
        on conflict do nothing;
        cnt := cnt + 1;
    end loop;
  end;
$$
;

-- generate advisory_metadata
-- duration: 2s / 32k advisories (on RDS)
alter sequence advisory_metadata_id_seq restart with 1;
do $$
  declare
    cnt int := 0;
    wanted int;
    adv_type int;
    sev int;
    id int;
    rnd float;
    rnd_date1 timestamp with time zone;
    rnd_date2 timestamp with time zone;
  begin
    select val into wanted from _const where key = 'advisories';
    select count(*)-1 into adv_type from advisory_type;
    select count(*) into sev from advisory_severity;
    while cnt < wanted loop
        id := nextval('advisory_metadata_id_seq');
        rnd := random();
        rnd_date1 := now() - make_interval(days => (rnd*365)::int);
        rnd_date2 := rnd_date1 + make_interval(days => (rnd*100)::int);
        insert into advisory_metadata
            (id, name, description, synopsis, summary, solution, advisory_type_id, public_date, modified_date, url, severity_id, cve_list)
        values
            (id, 'ADV-2020-' || id, 'Decription of advisory ' || id, 'Synopsis of advisory ' || id,
                'Summary of advisory ' || id, 'Solution of advisory ' || id, trunc(rnd*adv_type)+1,
                rnd_date1, rnd_date2, 'http://errata.example.com/errata/' || id, trunc(rnd*sev)+1, NULL);
        cnt := cnt + 1;
    end loop;
  end;
$$
;

-- generate system_advisories
-- duration: 325s (05:25) / 7.5M system_advisories (a.k.a. 750k systems with 10 adv in avg) (on RDS) 
do $$
  declare
    cnt int := 0;
    wanted int;
    systems int;
    advs int;
    stat int;
    patched_pct float := 0.80;
    rnd float;
    rnd2 float;
    rnd_date1 timestamp with time zone;
    rnd_date2 timestamp with time zone;
  begin
    select (select val from _const where key = 'systems') * (select val from _const where key = 'adv_per_system')
      into wanted;
    select count(*) into systems from system_platform;
    select count(*) into advs from advisory_metadata;
    select count(*) into stat from status;
    while cnt < wanted loop
        rnd := random();
        rnd2 := random();
        rnd_date1 := now() - make_interval(days => (rnd*365)::int);
        rnd_date2 := rnd_date1 + make_interval(days => (rnd*100)::int);
        insert into system_advisories
            (system_id, advisory_id, first_reported, when_patched, status_id)
        values
            (trunc(systems*rnd)+1, trunc(advs*rnd2)+1, rnd_date1, case when random() < patched_pct then rnd_date2 else NULL end, trunc(stat*rnd))
        on conflict do nothing;
        cnt := cnt + 1;
    end loop;
  end;
$$
;
