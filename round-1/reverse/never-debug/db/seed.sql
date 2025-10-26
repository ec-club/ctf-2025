CREATE TABLE IF NOT EXISTS messages (
  id SERIAL PRIMARY KEY,
  content TEXT NOT NULL
);

INSERT INTO messages (content) VALUES ('Is your cookie ready');
INSERT INTO messages (content) VALUES ('Lorem ipsum');
INSERT INTO messages (content) VALUES ('little big service.');
INSERT INTO messages (content) VALUES ('Pain challenge');

CREATE TABLE IF NOT EXISTS flags (
  id SERIAL PRIMARY KEY,
  flag_text TEXT NOT NULL
);

INSERT INTO flags (flag_text) VALUES ('If you see this, please create a ticket in Discord.');
