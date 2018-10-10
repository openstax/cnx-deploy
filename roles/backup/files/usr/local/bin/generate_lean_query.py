#!/usr/bin/env python3
import json
import sys
from urllib.request import urlopen


OPENSTAX_BOOKS_URL = "https://openstax.org/api/v2/pages/?type=books.Book&limit=1000&fields=title,cnx_id"

SQL_TEMPLATE = """\
BEGIN;
-- FIXME: in 20180816211433_dumpable-functions, but not in production yet
CREATE OR REPLACE FUNCTION
 short_ident_hash(uuid uuid, major integer, minor integer)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $$ select public.short_id(uuid) || '@' || concat_ws('.', major, minor) $$
;
-- A temporary table to store the results of our query, which will be used twice
CREATE TEMPORARY TABLE to_be_saved (module_ident INT);
WITH RECURSIVE ttt(nodeid, documentid, title, path) AS (
    -- Collections that are OpenStax maintained
    SELECT nodeid, documentid, title, ARRAY[nodeid] FROM trees AS t WHERE t.documentid = ANY(SELECT module_ident FROM modules WHERE uuid = ANY('{ids}'::UUID[]))
  UNION ALL
    -- Lookup all the Modules associated with these Collections
    SELECT t.nodeid, t.documentid, t.title, ttt.path || ARRAY[t.nodeid]
    FROM trees AS t JOIN ttt ON (t.parent_id = ttt.nodeid)
    WHERE NOT t.nodeid = ANY(ttt.path)
) INSERT INTO to_be_saved SELECT DISTINCT documentid FROM ttt WHERE documentid IS NOT NULL;
-- * list of things to save
select count(*) from modules where module_ident in (SELECT module_ident FROM to_be_saved);
--  count 
-- -------
--  47784
-- (1 row)
-- * list of things to save that have parentage
select count(*) from modules where module_ident in (SELECT module_ident FROM to_be_saved) and parent is not null;
--  count 
-- -------
--   3292
-- (1 row)
-- * list of things to save that will need to disconnect parentage
select count(*) from modules where module_ident in (SELECT module_ident FROM to_be_saved) and parent not in (SELECT module_ident FROM to_be_saved);
--  count 
-- -------
--   1177
-- (1 row)
-- * list of things to be removed
select count(*) from modules where module_ident not in (SELECT module_ident FROM to_be_saved);
--  count  
-- --------
--  344902
-- (1 row)
-- Disconnect to be saved modules parents from modules that will be removed
UPDATE modules SET parent = NULL WHERE module_ident IN (SELECT module_ident FROM to_be_saved) AND parent NOT IN (SELECT module_ident FROM to_be_saved);
-- UPDATE 1177
-- Delete the modules that are not OpenStax content
DELETE FROM modules WHERE module_ident NOT IN (SELECT module_ident FROM to_be_saved);
COMMIT;"""


def get_openstax_book_ids():
    try:
        resp = urlopen(OPENSTAX_BOOKS_URL)
    except Exception:
        sys.exit(1)
    # BBB Because the system only has Python 3.5 rather than Python >=3.7
    ##data = json.load(resp)
    data = json.loads(resp.read().decode('utf8'))

    return [x['cnx_id'] for x in data['items']]


def _format_as_pg_array(l):
    return '{' + ','.join(l) + '}'


def main():
    books = get_openstax_book_ids()
    # BBB Manually add "Introduction to Sociology [1e]"
    books.append('afe4332a-c97f-4fc4-be27-4e4d384a32d8')
    print(SQL_TEMPLATE.format(ids=_format_as_pg_array(books)))


if __name__ == '__main__':
    main()
