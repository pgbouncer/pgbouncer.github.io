---
layout: default
title: PgBouncer features
---

# Features

-   Several levels of brutality when rotating connections:

     Session pooling
     :  Most polite method.  When a client connects, a server
        connection will be assigned to it for the whole duration it
        stays connected.  When the client disconnects, the server
        connection will be put back into pool.  This mode supports all
        PostgreSQL features.

     Transaction pooling
     :  A server connection is assigned to a client only during a
        transaction.  When PgBouncer notices that the transaction is
        over, the server will be put back into the pool.

        This mode breaks a few session-based features of PostgreSQL.
        You can use it only when the application cooperates by not
        using features that break.  See the table below for
        incompatible features.

     Statement pooling
     :  Most aggressive method.  This is transaction pooling with a
        twist: Multi-statement transactions are disallowed.  This is
        meant to enforce "autocommit" mode on the client, mostly
        targeted at PL/Proxy.

-   Low memory requirements (2 kB per connection by default).  This is
    because PgBouncer does not need to see full packets at once.

-   It is not tied to one backend server.  The destination databases
    can reside on different hosts.

-   Supports online reconfiguration for most settings.

-   Supports online restart/upgrade without dropping client connections.


## SQL feature map for pooling modes

The following table list various PostgreSQL features and whether they
are compatible with PgBouncer pooling modes.  Note that "transaction"
pooling breaks client expectations of the server _by design_ and can
be used only if the application cooperates by not using non-working
features.

|----------------------------------+-----------------+---------------------|
| Feature                          | Session pooling | Transaction pooling |
|----------------------------------+-----------------+---------------------|
| Startup parameters [^0]          | Yes             | Yes                 |
| SET/RESET                        | Yes             | Never               |
| LISTEN                           | Yes             | Never               |
| NOTIFY                           | Yes             | Yes                 |
| WITHOUT HOLD CURSOR              | Yes             | Yes                 |
| WITH HOLD CURSOR                 | Yes             | Never               |
| Protocol-level prepared plans    | Yes             | Yes [^1]            |
| PREPARE / DEALLOCATE             | Yes             | Never               |
| ON COMMIT DROP temp tables       | Yes             | Yes                 |
| PRESERVE/DELETE ROWS temp tables | Yes             | Never               |
| Cached plan reset                | Yes             | Yes                 |
| LOAD statement                   | Yes             | Never               |
| Session-level advisory locks     | Yes             | Never               |
|----------------------------------+-----------------+---------------------|

[^0]:
    Startup parameters are: `client_encoding`, `datestyle`, `timezone`,
    and `standard_conforming_strings`.  PgBouncer detects their
    changes and so it can guarantee they remain consistent for the
    client.

[^1]:
    You need to change
    [`max_prepared_statements`](/config.html#max_prepared_statements) to a
    non-zero value to enable this support.
