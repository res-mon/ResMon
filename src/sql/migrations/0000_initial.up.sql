CREATE TABLE IF NOT EXISTS
  "migration_script" (
    "version" INTEGER PRIMARY KEY,
    "identifier" TEXT NOT NULL   ,
    "up" TEXT NOT NULL           ,
    "down" TEXT NOT NULL
  );