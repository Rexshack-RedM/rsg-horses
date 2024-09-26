CREATE TABLE `player_horses` (
	`id` INT(11) NOT NULL AUTO_INCREMENT,
	`citizenid` VARCHAR(50) NOT NULL COLLATE 'utf8mb4_general_ci',
	`stable` VARCHAR(50) NOT NULL COLLATE 'utf8mb4_general_ci',
	`horseid` VARCHAR(11) NOT NULL COLLATE 'utf8mb4_general_ci',
	`name` VARCHAR(255) NOT NULL COLLATE 'utf8mb4_general_ci',
	`horse` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_general_ci',
	`dirt` INT(11) NULL DEFAULT '0',
	`horsexp` INT(11) NULL DEFAULT '0',
	`components` LONGTEXT NULL DEFAULT NULL COLLATE 'utf8mb4_general_ci',
	`gender` VARCHAR(11) NOT NULL COLLATE 'utf8mb4_general_ci',
	`wild` VARCHAR(11) NULL DEFAULT NULL COLLATE 'utf8mb4_general_ci',
	`active` TINYINT(4) NULL DEFAULT '0',
	`born` INT(11) NOT NULL DEFAULT '0',
	PRIMARY KEY (`id`) USING BTREE,
	INDEX `Index 2` (`citizenid`) USING BTREE
)
COLLATE='utf8mb4_general_ci'
ENGINE=InnoDB
AUTO_INCREMENT=12
;
