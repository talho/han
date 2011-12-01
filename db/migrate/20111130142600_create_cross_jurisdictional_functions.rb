class CreateCrossJurisdictionalFunctions < ActiveRecord::Migration
  def self.up
    execute "CREATE OR REPLACE FUNCTION sp_audience_cross_jurisdictions (var_audience_id INT, var_from_jurisdiction_id INT)
            RETURNS TABLE(id INT, lft INT, rgt INT) AS $$
            BEGIN
              RETURN QUERY  
                SELECT j.id, j.lft, j.rgt
                FROM jurisdictions j
                WHERE j.id = var_from_jurisdiction_id
              UNION
                SELECT j.id, j.lft, j.rgt
                FROM audiences a
                LEFT JOIN audiences_jurisdictions aj ON a.id = aj.audience_id  
                JOIN jurisdictions j ON j.id = aj.jurisdiction_id
                WHERE a.id = var_audience_id
              UNION
                SELECT j.id, j.lft, j.rgt
                FROM audiences a
                LEFT JOIN audiences_jurisdictions aj ON a.id = aj.audience_id
                JOIN audiences_roles ar ON a.id = ar.audience_id
                JOIN role_memberships rm ON ar.role_id = rm.role_id
                JOIN jurisdictions j ON rm.jurisdiction_id = j.id
                WHERE aj.jurisdiction_id IS NULL
                AND a.id = var_audience_id
              UNION
                SELECT j.id, j.lft, j.rgt
                FROM audiences_users au
                JOIN role_memberships rm ON au.user_id = rm.user_id
                JOIN jurisdictions j ON rm.jurisdiction_id = j.id
                LEFT JOIN (SELECT irm.user_id 
                           FROM role_memberships irm
                           WHERE irm.jurisdiction_id = var_from_jurisdiction_id) nrm ON rm.user_id = nrm.user_id             
                WHERE au.audience_id = var_audience_id
                AND nrm.user_id IS NULL
              UNION
                SELECT (sp.j).*
                FROM (SELECT sp_audience_cross_jurisdictions(asa.sub_audience_id, var_from_jurisdiction_id) as j
                      FROM audiences_sub_audiences asa 
                      WHERE asa.audience_id = var_audience_id) sp
              ;
            END
            $$ language 'plpgsql';"
            
    execute "CREATE OR REPLACE FUNCTION sp_cross_jurisdiction_recipients (var_audience_id INT, var_from_jurisdiction_id INT, var_hacc_role_id INT)
            RETURNS TABLE(id INT) AS $$
            BEGIN
              IF EXISTS(select * from pg_tables where tablename = 'tmp_jurisdictions' and tableowner = user)
                     THEN DROP TABLE IF EXISTS tmp_jurisdictions;
                    END IF;
                        
                    CREATE TEMPORARY TABLE tmp_jurisdictions(id INT, lft INT, rgt INT, count INT);
            
                    INSERT INTO tmp_jurisdictions
                    SELECT DISTINCT p.id AS id, p.lft AS lft, p.rgt AS rgt, count(*) AS cnt
                    FROM jurisdictions p
                    JOIN sp_audience_cross_jurisdictions(var_audience_id, var_from_jurisdiction_id) js ON js.lft >= p.lft 
                                    AND js.rgt <= p.rgt
                    GROUP BY p.id, p.name, p.lft, p.rgt
                    ORDER BY cnt DESC, p.rgt ASC;
            
                    RETURN QUERY
                    SELECT DISTINCT u.id
                    FROM tmp_jurisdictions j
                    JOIN role_memberships rm ON j.id = rm.jurisdiction_id
                    JOIN users u on rm.user_id = u.id
                    WHERE j.lft >= (SELECT lft 
                  FROM tmp_jurisdictions
                  LIMIT 1)
                AND rm.role_id = var_hacc_role_id
                AND u.deleted_at is null
                    ;
            END
            $$ language 'plpgsql';" 
  end

  def self.down
    execute "DROP FUNCTION IF EXISTS sp_audience_cross_jurisdictions(int, int)"
    execute "DROP FUNCTION IF EXISTS sp_cross_jurisdiction_recipients(int, int, int)"
  end
end