class CreateCrossJurisdictionalFunctions < ActiveRecord::Migration
  def self.up
    execute "CREATE OR REPLACE FUNCTION sp_cross_jurisdiction_recipients (var_audience_id INT, var_from_jurisdiction_id INT, var_hacc_role_id INT) 
            RETURNS TABLE(id INT) AS $$
              WITH RECURSIVE aud_jurs(id, lft, rgt,aid) AS (
                  SELECT j.id, j.lft, j.rgt, $1
                  FROM jurisdictions j
                  WHERE j.id = $2
                UNION
                  SELECT j.id, j.lft, j.rgt, a.id
                  FROM audiences a
                  LEFT JOIN audiences_jurisdictions aj ON a.id = aj.audience_id  
                  JOIN jurisdictions j ON j.id = aj.jurisdiction_id
                UNION
                  SELECT j.id, j.lft, j.rgt, a.id
                  FROM audiences a
                  LEFT JOIN audiences_jurisdictions aj ON a.id = aj.audience_id
                  JOIN audiences_roles ar ON a.id = ar.audience_id
                  JOIN role_memberships rm ON ar.role_id = rm.role_id
                  JOIN jurisdictions j ON rm.jurisdiction_id = j.id
                  WHERE aj.jurisdiction_id IS NULL
                UNION
                  SELECT j.id, j.lft, j.rgt, au.audience_id
                  FROM audiences_users au
                  JOIN role_memberships rm ON au.user_id = rm.user_id
                  JOIN jurisdictions j ON rm.jurisdiction_id = j.id
                  LEFT JOIN (SELECT irm.user_id 
                             FROM role_memberships irm
                             WHERE irm.jurisdiction_id = $2) nrm ON rm.user_id = nrm.user_id             
                  WHERE nrm.user_id IS NULL
                UNION
                  SELECT aj.id, aj.lft, aj.rgt, asa.audience_id
                  FROM aud_jurs aj
                  JOIN audiences_sub_audiences asa ON aj.aid = asa.sub_audience_id
              ), jurs_and_pars(id, lft, rgt, count) AS (      
                SELECT DISTINCT p.id AS id, p.lft AS lft, p.rgt AS rgt, count(*) AS cnt
                FROM jurisdictions p
                JOIN aud_jurs js ON js.lft >= p.lft 
                                AND js.rgt <= p.rgt
                WHERE js.aid = $1
                GROUP BY p.id, p.name, p.lft, p.rgt
                ORDER BY cnt DESC, p.rgt ASC
              )
        
                SELECT DISTINCT u.id
                FROM jurs_and_pars j
                JOIN role_memberships rm ON j.id = rm.jurisdiction_id
                JOIN users u on rm.user_id = u.id
                WHERE j.lft >= (SELECT lft 
                  FROM jurs_and_pars
                  WHERE count > 1
                  LIMIT 1)
                AND rm.role_id = $3
                AND u.deleted_at is null
                ;
          $$ language sql;" 
  end

  def self.down
    execute "DROP FUNCTION IF EXISTS sp_audience_cross_jurisdictions(int, int)"
    execute "DROP FUNCTION IF EXISTS sp_cross_jurisdiction_recipients(int, int, int)"
  end
end