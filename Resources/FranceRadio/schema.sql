# SQLITESEQUENCE TABLE (SqlitePersistentObjects internal table)
CREATE TABLE "SQLITESEQUENCE" ("name" TEXT, "seq" INTEGER);
CREATE INDEX "SQLITESEQUENCE_name" ON "SQLITESEQUENCE" ("name");

# Table view items
CREATE TABLE "table_view_items" (
  "pk" INTEGER PRIMARY KEY,
  "parent" INTEGER,
  "position" INTEGER,
  "group" TEXT,
  "radio_group" TEXT,
  "radio" TEXT
);
CREATE INDEX "table_view_items_parent" ON "table_view_items" ("parent");
CREATE INDEX "table_view_items_parent_position" ON "table_view_items" ("parent", "position");
INSERT INTO "SQLITESEQUENCE" ("name", "seq") VALUES ('table_view_items', 0);

# Radios
CREATE TABLE "radios" (
  "pk" INTEGER PRIMARY KEY,
  "name" TEXT,
  "high_u_r_l" TEXT,
  "low_u_r_l" TEXT
);
INSERT INTO "SQLITESEQUENCE" ("name", "seq") VALUES ('radios', 0);

# Radio groups
CREATE TABLE "radio_groups" (
  "pk" INTEGER PRIMARY KEY,
  "group_name" TEXT,
  "selected" TEXT
);
INSERT INTO "SQLITESEQUENCE" ("name", "seq") VALUES ('radio_groups', 0);

# Version table
CREATE TABLE "db_schema" (
  "version" INTEGER
);
INSERT INTO "db_schema" ("version") VALUES (1);
