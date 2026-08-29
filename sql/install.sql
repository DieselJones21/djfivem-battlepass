CREATE TABLE IF NOT EXISTS `djfivem_battlepass` (
    `identifier` VARCHAR(64)  NOT NULL,
    `season`     VARCHAR(32)  NOT NULL DEFAULT 'c1s1',
    `xp`         INT          NOT NULL DEFAULT 0,
    `claimed`    LONGTEXT     NOT NULL,
    `premium`    TINYINT(1)   NOT NULL DEFAULT 0,
    `updated_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`identifier`, `season`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
