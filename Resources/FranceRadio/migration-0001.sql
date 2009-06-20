BEGIN TRANSACTION;

/* radios table */
INSERT INTO "radios" ("pk", "name", "high_u_r_l", "low_u_r_l") VALUES (48, 'France Bleu Ile-de-France', 'http://www.tv-radio.com/station/france_bleu_ile-de-france_mp3/france_bleu_ile-de-france_mp3-128k.m3u', 'http://www.tv-radio.com/station/france_bleu_ile-de-france_mp3/france_bleu_ile-de-france_mp3-32k.m3u');
INSERT INTO "radios" ("pk", "name", "high_u_r_l", "low_u_r_l") VALUES (49, 'France Culture Chemins de la Connaissance', 'http://www.tv-radio.com/station/les_chemins_de_la_connaissance_mp3/les_chemins_de_la_connaissance_mp3-128k.m3u', 'http://www.tv-radio.com/station/les_chemins_de_la_connaissance_mp3/les_chemins_de_la_connaissance_mp3-128k.m3u');
INSERT INTO "radios" ("pk", "name", "high_u_r_l", "low_u_r_l") VALUES (50, 'France Culture Sentiers de la Création', 'http://www.tv-radio.com/station/les_sentiers_de_la_creation_mp3/les_sentiers_de_la_creation_mp3-128k.m3u', 'http://www.tv-radio.com/station/les_sentiers_de_la_creation_mp3/les_sentiers_de_la_creation_mp3-128k.m3u');
INSERT INTO "radios" ("pk", "name", "high_u_r_l", "low_u_r_l") VALUES (51, 'France Inter Grandes Ondes', 'http://www.tv-radio.com/station/franceintergrandesondes-mp3/franceintergrandesondes-mp3-32k.m3u', 'http://www.tv-radio.com/station/franceintergrandesondes-mp3/franceintergrandesondes-mp3-32k.m3u');
UPDATE "SQLITESEQUENCE" SET "seq" = 51 WHERE "name" = 'radios';

/* radio_groups table */
INSERT INTO "radio_groups" ("pk", "group_name") VALUES (2, 'France Inter');
INSERT INTO "radio_groups" ("pk", "group_name") VALUES (3, 'France Culture');
UPDATE "SQLITESEQUENCE" SET "seq" = 3 WHERE "name" = 'radio_groups';

/* table_view_items */
UPDATE "table_view_items" SET "group" = '1', "radio_group" = 'FRRadioGroup-2', "radio" = NULL WHERE "pk" = 1;
UPDATE "table_view_items" SET "group" = '1', "radio_group" = 'FRRadioGroup-3', "radio" = NULL WHERE "pk" = 3;
INSERT INTO "table_view_items" ("pk", "parent", "position", "radio") VALUES (49, 1, 1, 'FRRadio-1');
INSERT INTO "table_view_items" ("pk", "parent", "position", "radio") VALUES (50, 1, 2, 'FRRadio-51');
INSERT INTO "table_view_items" ("pk", "parent", "position", "radio") VALUES (51, 3, 1, 'FRRadio-3');
INSERT INTO "table_view_items" ("pk", "parent", "position", "radio") VALUES (52, 3, 2, 'FRRadio-49');
INSERT INTO "table_view_items" ("pk", "parent", "position", "radio") VALUES (52, 3, 2, 'FRRadio-50');
UPDATE "SQLITESEQUENCE" SET "seq" = 48 WHERE "name" = 'table_view_items';

UPDATE "db_schema" SET "version" = 2;

COMMIT TRANSACTION;