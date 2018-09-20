---
layout: toc
title: PgBouncer FAQ
---

# PgBouncer FAQ

## How to connect to PgBouncer?

PgBouncer acts as Postgres server, so simply point your client to
PgBouncer port.

## How to load-balance queries between several servers?

PgBouncer does not have internal multi-host configuration.
It is possible via some external tools:

1.  DNS round-robin. Use several IPs behind one DNS name. PgBouncer does
    not look up DNS each time new connection is launched. Instead it
    caches all IPs and does round-robin internally. Note: if there is
    more than 8 IPs behind one name, the DNS backend must support EDNS0
    protocol. See README for details.

2.  Use a TCP connection load-balancer. Either
    [LVS](http://www.linuxvirtualserver.org/) or
    [HAProxy](http://www.haproxy.org/) seem to be good choices. On
    PgBouncer side it may be good idea to make `server_lifetime` smaller
    and also turn `server_round_robin` on - by default idle connections
    are reused by LIFO algorithm which may work not so well when
    load-balancing is needed.

## How to failover

PgBouncer does not have internal failover-host configuration nor detection.
It is possible via some external tools:

1. DNS reconfiguration - when ip behind DNS name is reconfigured, pgbouncer
   will reconnect to new server.  This behaviour can be tuned via 2
   config parameters - **dns_max_ttl** tunes lifetime for one hostname,
   and **dns_zone_check_period** tunes how often zone SOA will be
   queried for changes.  If zone SOA record has changed, pgbouncer
   will re-query all hostnames under that zone.

2. Write new host to config and let PgBouncer reload it - send SIGHUP
   or use RELOAD; command on console.  PgBouncer will detect changed
   host config and reconnect to new server.

## How to use SSL connections with PgBouncer?

Since version 1.7, PgBouncer has built-in support for TLS.  Just configure it.

[ Old answer for older PgBouncer versions. ]

Use [Stunnel](https://www.stunnel.org/). Since version 4.27 it supports
PostgreSQL protocol for both client and server side. It is activated by
setting `protocol=pgsql`.

Alternative is to use Stunnel on both sides of connection, then the
protocol support is not needed.

## How to use prepared statements with session pooling?

In session pooling mode, the reset query must clean old prepared
statements.  This can be achieved by `server_reset_query = DISCARD ALL;`
or at least to `DEALLOCATE ALL;`

## How to use prepared statements with transaction pooling?

To make prepared statements work in this mode would need PgBouncer to
keep track of them internally, which it does not do. So only way to keep
using PgBouncer in this mode is to disable prepared statements in the
client.

### Disabling prepared statements in JDBC

The proper way to do it for JDBC is adding `prepareThreshold=0`
parameter to connect string.

### Disabling prepared statements in PHP/PDO

To disable use of server-side prepared statements, the PDO attribute
`PDO::ATTR_EMULATE_PREPARES` must be set to `true`. Either at
connect-time:

    $db = new PDO("dsn", "user", "pass", array(PDO::ATTR_EMULATE_PREPARES => true));

or later:

    $db->setAttribute(PDO::ATTR_EMULATE_PREPARES, true);

## How to upgrade PgBouncer without dropping connections?

[ This cannot be done with TLS connections. ]

This is as easy as launching new PgBouncer process with `-R` switch and
same config:

    $ pgbouncer -R -d config.ini

The `-R` (reboot) switch makes new process connect to console of the old
process (dbname=pgbouncer) via unix socket and issue following commands:

    SUSPEND;
    SHOW FDS;
    SHUTDOWN;

After that if new one notices old one gone it resumes work with old
connections. The magic happens during `SHOW FDS` command which
transports actual file descriptors to new process.

If the takeover does not work for whatever reason, the new process can
be simply killed, old one notices this and resumes work.

## How to know which client is on which server connection?

Use SHOW CLIENTS and SHOW SERVERS views on console.

1.  Use `ptr` and `link` to map local client connection to server
    connection.

2.  Use `addr` and `port` of client connection to identify TCP
    connection from client.

3.  Use `local_addr` and `local_port` to identify TCP connection to
    server.

### Overview of important fields in SHOW CLIENTS

addr, port
: source address of client connection

local_addr, local_port
: local endpoint of client connection

ptr
: unique id for this connection

link
: unique id for server connection this client connection is currently linked to

### Overview of important fields in SHOW SERVERS

addr, port
: server address pgbouncer connects to

local_addr, local_port
: connections local endpoint

ptr
: unique id for this connection

link
: unique id for client connection this server connection is currently linked to

## Should PgBouncer be installed on webserver or database server?

It depends. Installing on webserver is good when short-connections are
used, then the connection setup latency is minimised - TCP requires
couple of packet roundtrips before connection is usable. Installing on
database server is good when there are many different hosts (eg.
webservers) connecting to it, then their connections can be optimised
together.

It is also possible to install PgBouncer on both webserver and database
servers. Only negative aspect of that is that each PgBouncer hop adds
small amount of latency to each query. So it’s probably best to simply
test whether the payoff is worth the cost.

## `SET search_path` may not work as expected

PgBouncer does not emulate the behaviour of session changing features such as `SET search_path` ([#73](https://github.com/pgbouncer/pgbouncer/pull/73#issuecomment-143957485)),
which means that adjusting this value has a knock-on effect for all clients connected to that database.

Due to [CVE-2018-1058](https://wiki.postgresql.org/wiki/A_Guide_to_CVE-2018-1058:_Protect_Your_Search_Path),
certain versions of `pg_dump` will set an empty `search_path` at runtime, which then breaks any other connections to the database until PgBouncer is restarted ([gitlab-ce #49089](https://gitlab.com/gitlab-org/gitlab-ce/issues/49089)).

If you're using `pg_dump` to backup your databases and are using an affected version mentioned above, you should avoid using `pg_dump` through PgBouncer.
