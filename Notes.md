Produces a representation of a hierarchical tree structure (connectby) and pivot tables (crosstab)
http://www.postgresql.org/docs/9.1/static/tablefunc.html

Another option for hierarchical trees:
http://www.postgresql.org/docs/9.1/static/ltree.html

Review our options for time and date functions (and ranges):
http://www.postgresql.org/docs/9.3/static/functions-datetime.html#FUNCTIONS-DATETIME-TRUNC

We can reach out and touch the FS (writing static json files?)
http://www.postgresql.org/docs/9.1/static/adminpack.html

This will be useful during development:
http://www.postgresql.org/docs/9.1/static/auto-explain.html

http://www.postgresql.org/docs/9.1/static/hstore.html

This will be awesome for global search:
http://www.postgresql.org/docs/9.1/static/dict-xsyn.html

What should go in front of our web socket servers?
https://github.com/observing/balancerbattle


NOTIFY/LISTEN will use 2 connections per node instance
Clients should be divided between node instance

https://github.com/observing/balancerbattle

The NOTIFY payload is limited to 8KiB as a string literal
NOTIFY/LISTEN should consume 2 connections per node thread
NOTIFY/LISTEN will consume all CPU if you let it (rather quickly)
NOTIFY/LISTEN can only queue 8GiB of payloads

Primus is a universal wrapper for real-time frameworks (client/server) with Android, iOS, C++ support as well. It provides plugins and middleware with support for the following engines:
	Engine.IO
	WebSockets
	Faye
	BrowserChannel
	SockJS
	Socket.IO

primus-spark-latency: adds a latency property to primus sparks server-side
primus-responder: client and server plugin that adds a request/response cycle to Primus
emit: adds client -> server and server -> client event emitting to Primus

substream: stream compatible connection multiplexer on top of the Primus connections; streams can be created without pre-defining them on the server or client

omega-supreme: broadcast messages to Primus via HTTP to all clients, a client or a collection of clients
metroplex: cluster multiple primus's together using redis
fortess-maximus: validates every incoming message on your Primus server as all user input should be seen as a potential security risk
mirage: Mirage generates and validates persistent session IDs.

primus-rooms: adds rooms capabilities to Primus (based on the rooms implementation of Socket.IO)
primus-multiplex: adds multiplexing capabilities to Primus.
primus-cluster: scale Primus across multiple servers or with node cluster

primus-redis-rooms: a Redis store for Primus and primus-rooms
primus-resource: Define resources with auto-bound methods that can be called remotely on top of Primus
hapi_primus_sessions: a hapi and primus plugin which extends primus' spark with a `getSession(cb)` method which returns the current hapi session object
primus-express-session: share a user session between Express and Primus
backbone.primus: bind primus.io events to backbone models and collections

Events as sent by PG:
	[view/table/partition]_[insert/delete/update]_[pk]
	RATING_INSERT_000001
	RATING_AGG_UPDATE_LEARN



https://github.com/primus/primus

CREATE TABLE person
  (
    id int PRIMARY KEY,
    first_name text,
    last_name text NOT NULL
  );

INSERT INTO person
  VALUES
    (1, 'John', 'Smith'),
    (2, 'Jane', 'Doe'),
    (3, NULL, 'Prince');

CREATE FUNCTION display_name(rec person)
  RETURNS text
  STABLE
  LANGUAGE SQL
  COST 5
AS $$
  SELECT
    CASE
      WHEN $1.first_name IS NULL THEN ''
      ELSE $1.first_name || ' '
    END || $1.last_name;
$$;

http://www.cs.ucr.edu/~tsotras/cs236/W15/tempDB-survey.pdf
http://db.cs.berkeley.edu/papers/ERL-M89-17.pdf