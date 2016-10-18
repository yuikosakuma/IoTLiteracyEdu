CREATE TABLE connectiontest(
  nodeid INTEGER PRIMARY KEY,
  xbeeaddr INTEGER,
  temperature NUMERIC,
  destinationid INTEGER,
  votedcounter INTEGER,
  name TEXT,
  lastupdate TIMESTAMP WITHOUT TIME ZONE,
  sendflag INTEGER,
  volume INTEGER
);

SELECT * FROM connectiontest;

CREATE TABLE flagtest(
  flagid INTEGER PRIMARY KEY,
  name TEXT,
  value INTEGER,
  angle INTEGER,
);

SELECT * FROM flagtest;