-- Step 1: Drop the obsolete 'wild' column
ALTER TABLE `player_horses` 
  DROP COLUMN `wild`;

-- Step 2: Modify existing columns to match new types, lengths, and default values
ALTER TABLE `player_horses`
  MODIFY COLUMN `stable` VARCHAR(50) NOT NULL DEFAULT 'valentine',
  MODIFY COLUMN `horseid` VARCHAR(6) NOT NULL,
  MODIFY COLUMN `name` VARCHAR(50) NOT NULL,
  MODIFY COLUMN `horse` VARCHAR(100) NOT NULL,
  MODIFY COLUMN `gender` VARCHAR(10) NOT NULL DEFAULT 'male',
  MODIFY COLUMN `active` TINYINT(1) NOT NULL DEFAULT 0,
  MODIFY COLUMN `horsexp` INT(11) NOT NULL DEFAULT 0,
  MODIFY COLUMN `dirt` INT(11) NOT NULL DEFAULT 0,
  MODIFY COLUMN `components` LONGTEXT DEFAULT NULL;

-- Step 3: Add new columns
ALTER TABLE `player_horses`
  ADD COLUMN `coat` LONGTEXT DEFAULT NULL AFTER `components`,
  ADD COLUMN `age_seconds` INT(11) NOT NULL DEFAULT 0 AFTER `dirt`,
  ADD COLUMN `pregnant_until` INT(11) DEFAULT NULL AFTER `age_seconds`,
  ADD COLUMN `last_bred` INT(11) DEFAULT NULL AFTER `pregnant_until`,
  ADD COLUMN `stored_weapon` VARCHAR(100) DEFAULT NULL AFTER `last_bred`,
  ADD COLUMN `stored_weapon_name` VARCHAR(100) DEFAULT NULL AFTER `stored_weapon`,
  ADD COLUMN `stored_weapon_data` LONGTEXT DEFAULT NULL AFTER `stored_weapon_name`;

-- Step 4: Add new performance indexes
ALTER TABLE `player_horses`
  ADD KEY `idx_citizenid` (`citizenid`),
  ADD KEY `idx_horseid` (`horseid`),
  ADD KEY `idx_active` (`citizenid`, `active`);