
-- duration: about 20 s
CREATE TABLE table_to_delete AS
   SELECT 'veeeeeeery_long_string' || x AS col
   FROM generate_series(1,(10^7)::int) x; 

  
  
  /*
   * space after creating table and before delete command: 575 mb
   * space after delete command: nothing changes, the same 575 mb
   * space after truncate command: 0 
   * */ 
  SELECT *, pg_size_pretty(total_bytes) AS total,
                        pg_size_pretty(index_bytes) AS INDEX,
                        pg_size_pretty(toast_bytes) AS toast,
                        pg_size_pretty(table_bytes) AS TABLE
   FROM ( SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes
                   FROM (SELECT c.oid,nspname AS table_schema,
                                                   relname AS TABLE_NAME,
                                                  c.reltuples AS row_estimate,
                                                  pg_total_relation_size(c.oid) AS total_bytes,
                                                  pg_indexes_size(c.oid) AS index_bytes,
                                                  pg_total_relation_size(reltoastrelid) AS toast_bytes
                                  FROM pg_class c
                                  LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
                                  WHERE relkind = 'r'
                                  ) a
                        ) a
   WHERE table_name LIKE '%table_to_delete%';
   
  -- duration: 13-14 seconds
  DELETE FROM table_to_delete
               WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0; 
               -- removes 1/3 of all rows
              
                
   VACUUM FULL VERBOSE table_to_delete;
   
  
  -- duration: 1 s
  truncate table_to_delete;