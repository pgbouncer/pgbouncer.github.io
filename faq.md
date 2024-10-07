---
layout: toc
title: PgBouncer FAQ
---

# PgBouncer FAQ

## How to connect to PgBouncer?

PgBouncer acts as a Postgres server, so simply point your client to the
PgBouncer port.

## How to load-balance queries between several servers?

PgBouncer does not have an internal multi-host configuration.
It is possible via external tools:

1.  DNS round-robin. Use several IPs behind one DNS name. PgBouncer does
    not look up DNS each time a new connection is launched. Instead, it
    caches all IPs and does round-robin internally. Note: if there are
    more than 8 IPs behind one name, the DNS backend must support the EDNS0
    protocol. See README for details.

2.  Use a TCP connection load-balancer. Either
    [LVS](http://www.linuxvirtualserver.org/) or
    [HAProxy](http://www.haproxy.org/) seem to be good choices. On the
    PgBouncer side it may be a good idea to make `server_lifetime` smaller
    and also turn `server_round_robin` on: by default, idle connections
    are reused by a LIFO algorithm, which may work not so well when
    load-balancing is needed.

## How to failover

PgBouncer does not have internal failover-host configuration nor detection.
It is possible with external tools:

1. DNS reconfiguration: When the IP address behind a DNS name is
   reconfigured, PgBouncer will reconnect to the new server.  This
   behaviour can be tuned by two configuration parameters:
   `dns_max_ttl` tunes the lifetime for one host name, and
   `dns_zone_check_period` tunes how often a zone SOA will be queried
   for changes.  If a zone SOA record has changed, PgBouncer will
   re-query all host names under that zone.

2. Write a new host to the configuration and let PgBouncer reload it:
   send SIGHUP or use the `RELOAD` command on the console.  PgBouncer
   will detect a changed host configuration and reconnect to the new
   server.

3. Use the `RECONNECT` command.  This is meant for situations where
   neither of the two options above are applicable, for example when
   you use the aforementioned HAProxy to route connections downstream
   from PgBouncer.  `RECONNECT` simply causes all server connections
   to be reopened.  So run that after that other component has changed
   its connection routing information.

## How to use prepared statements with session pooling?

In session pooling mode, the reset query must clean old prepared
statements.  This can be achieved by `server_reset_query = DISCARD ALL;`
or at least to `DEALLOCATE ALL;`

## How to use prepared statements with transaction pooling?

Since version 1.21.0 PgBouncer can track prepared statements in transaction
pooling mode and make sure they get prepared on-the-fly on the linked server
connection. To enable this feature, `max_prepared_statements` needs to be
set to a non-zero value. See the [docs for
`max_prepared_statements`](/config.html#max_prepared_statements)
for more details.

Due to the way PHP/PDO uses prepared statements ([#991]) the prepared statement
support in PgBouncer 1.21.0 does not work for PHP/PDO. So for PHP/PDO and
PgBouncer versions before 1.21.0 the only work-around is to disable prepared
statements in the client side.

[#991]: https://github.com/pgbouncer/pgbouncer/issues/991

### Disabling prepared statements in JDBC

The proper way to do it for JDBC is adding the `prepareThreshold=0`
parameter to the connection string.

### Disabling prepared statements in PHP/PDO

To disable use of server-side prepared statements, the PDO attribute
`PDO::PGSQL_ATTR_DISABLE_PREPARES` must be set to `true`. Either at
connect-time:

    $db = new PDO("dsn", "user", "pass", array(PDO::PGSQL_ATTR_DISABLE_PREPARES => true));

or later:

    $db->setAttribute(PDO::PGSQL_ATTR_DISABLE_PREPARES, true);

Prior to PHP 5.6, you have to replace `PDO::PGSQL_ATTR_DISABLE_PREPARES` by `PDO::ATTR_EMULATE_PREPARES`.

If you are using Doctrine/DBAL its already done for you.

## How to upgrade PgBouncer without dropping connections?

**DEPRECATED: Instead of this option use a rolling restart with multiple
pgbouncer processes listening on the same port using so_reuseport instead**

This is as easy as launching a new PgBouncer process with the `-R`
switch and the same configuration:

    $ pgbouncer -R -d config.ini

The `-R` (reboot) switch makes the new process connect to the console
of the old process (dbname=pgbouncer) via the Unix socket and issue
the following commands:

    SUSPEND;
    SHOW FDS;
    SHUTDOWN;

After that, if the new one notices that the old one is gone, it
resumes work with the old connections. The magic happens during the
`SHOW FDS` command which transports the actual file descriptors to new
process.

If the takeover does not work for whatever reason, the new process can
be simply killed. The old one notices this and resumes work.

## How to know which client is on which server connection?

Use the `SHOW CLIENTS` and `SHOW SERVERS` commands on the console.

1.  Use `ptr` and `link` to map local client connection to server
    connection.

2.  Use `addr` and `port` of client connection to identify TCP
    connection from client.

3.  Use `local_addr` and `local_port` to identify TCP connection to
    server.

## Should PgBouncer be installed on the web server or database server?

It depends.

Installing PgBouncer on the web server is good when short-lived
connections are used.  Then the connection setup latency is
minimised. (TCP requires a couple of packet roundtrips before a
connection is usable.) Installing PgBouncer on the database server is
good when there are many different hosts (e.g., web servers) connecting
to it. Then their connections can be optimised together.

It is also possible to install PgBouncer on both web server and database
server. One negative aspect of that is that each PgBouncer hop adds a
small amount of latency to each query.

In the end, you will need to test which model works best for your
performance needs.  You should also consider how installing PgBouncer
will affect the failover of your applications in the event of a web
server vs. database server going away.
