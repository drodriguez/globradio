/* SQLITESEQUENCE TABLE (SqlitePersistentObjects internal table) */
CREATE TABLE "SQLITESEQUENCE" ("name" TEXT, "seq" INTEGER);
CREATE INDEX "SQLITESEQUENCE_name" ON "SQLITESEQUENCE" ("name");

/* Table view items */
CREATE TABLE "directory_items" (
  "pk" INTEGER PRIMARY KEY,
  "parent" INTEGER,
  "position" INTEGER,
  "radio" TEXT
);
CREATE INDEX "directory_items_parent" ON "directory_items" ("parent");
CREATE INDEX "directory_items_parent_position" ON "directory_items" ("parent", "position");
INSERT INTO "SQLITESEQUENCE" ("name", "seq") VALUES ('directory_items', 0);

/* Radios */
CREATE TABLE "radios" (
  "pk" INTEGER PRIMARY KEY,
  "name" TEXT,
  "high_u_r_l" TEXT,
  "low_u_r_l" TEXT
);
INSERT INTO "SQLITESEQUENCE" ("name", "seq") VALUES ('radios', 0);

/* Radio groups */
CREATE TABLE "radio_groups" (
  "pk" INTEGER PRIMARY KEY,
  "name" TEXT
);
INSERT INTO "SQLITESEQUENCE" ("name", "seq") VALUES ('radio_groups', 0);

/* Favorites */
CREATE TABLE "favorites" (
  "pk" INTEGER PRIMARY KEY,
  "position" INTEGER,
  "last_used_at" TEXT,
  "radio" TEXT
);
CREATE INDEX "favorites_position" ON "favorites" ("position");
INSERT INTO "SQLITESEQUENCE" ("name", "seq") VALUES ('favorites', 0);

/* Version table */
CREATE TABLE "db_schema" (
  "version" INTEGER
);
INSERT INTO "db_schema" ("version") VALUES (1);
