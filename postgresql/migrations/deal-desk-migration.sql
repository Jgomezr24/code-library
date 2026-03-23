-- 1. Add the temporary bridge column
ALTER TABLE deal_desk ADD COLUMN pre_implementation_id INTEGER;

-- 2. Verify number of pre-implementations to migrate
SELECT COUNT(*) FROM pre_implementations;

BEGIN;

-- 3. Insert + capture the mapping
WITH inserted AS (
  INSERT INTO deal_desk (company_id, sow_creation_date, discovery_call_date, pre_implementation_id)
  SELECT company_id
       , sow_creation_date
       , initial_dc_date
       , id
  FROM pre_implementations
  ORDER BY id
  RETURNING id AS deal_desk_id, pre_implementation_id
)
-- 4. Back-fill deal_desk_id into pre_implementations
UPDATE pre_implementations pi
SET deal_desk_id = inserted.deal_desk_id
FROM inserted
WHERE pi.id = inserted.pre_implementation_id;

COMMIT;

-- 5. Verify
SELECT COUNT(*) FROM pre_implementations WHERE deal_desk_id IS NULL; -- Should be 0

-- 6. Drop the temp column
ALTER TABLE deal_desk DROP COLUMN pre_implementation_id;

