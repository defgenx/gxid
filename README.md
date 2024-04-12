# gxid

![CI](https://github.com/defgenx/gxid/workflows/test/badge.svg?branch=master)
[![Package Version](https://img.shields.io/hexpm/v/gxid)](https://hex.pm/packages/gxid)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gxid/)

A Gleam implementation of xid

## Quick start

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam shell # Run an Erlang shell
```

## Installation

This package can be added to your Gleam project:

```sh
gleam add gxid
```

and its documentation can be found at <https://hexdocs.pm/gxid>.

## Usage

### Generate a new XID

```gleam
import gxid.{type XID}

let assert Ok(channel) = gxid.start()

let xid: XID = gxid.generate(channel)
let str_xid = xid
              |> gxid.string()
```

### From an existing XID

```gleam
import gxid.{type XID}

let xid: XID = gxid.parse("h8a8u4o00de6hq6tsc00")
let str_xid = xid
              |> gxid.string()
```

## About XID

Xid uses the Mongo Object ID algorithm to generate globally unique ids with a different serialization (base64) to make
it shorter when transported as a string:
https://docs.mongodb.org/manual/reference/object-id/

- 4-byte value representing the seconds since the Unix epoch,
- 3-byte machine identifier,
- 2-byte process id, and
- 3-byte counter, starting with a random value.

The binary representation of the id is compatible with Mongo 12 bytes Object IDs.
The string representation is using base32 hex (w/o padding) for better space efficiency
when stored in that form (20 bytes). The hex variant of base32 is used to retain the
sortable property of the id.

Xid doesn't use base64 because case sensitivity and the 2 non alphanum chars may be an
issue when transported as a string between various systems. Base36 wasn't retained either
because 1/ it's not standard 2/ the resulting size is not predictable (not bit aligned)
and 3/ it would not remain sortable. To validate a base32 `xid`, expect a 20 chars long,
all lowercase sequence of `a` to `v` letters and `0` to `9` numbers (`[0-9a-v]{20}`).

UUIDs are 16 bytes (128 bits) and 36 chars as string representation. Twitter Snowflake
ids are 8 bytes (64 bits) but require machine/data-center configuration and/or central
generator servers. xid stands in between with 12 bytes (96 bits) and a more compact
URL-safe string representation (20 chars). No configuration or central generator server
is required so it can be used directly in server's code.

| Name        | Binary Size | String Size    | Features
|-------------|-------------|----------------|----------------
| [UUID]      | 16 bytes    | 36 chars       | configuration free, not sortable
| [shortuuid] | 16 bytes    | 22 chars       | configuration free, not sortable
| [Snowflake] | 8 bytes     | up to 20 chars | needs machine/DC configuration, needs central server, sortable
| [MongoID]   | 12 bytes    | 24 chars       | configuration free, sortable
| xid         | 12 bytes    | 20 chars       | configuration free, sortable

[UUID]: https://en.wikipedia.org/wiki/Universally_unique_identifier

[shortuuid]: https://github.com/stochastic-technologies/shortuuid

[Snowflake]: https://blog.twitter.com/2010/announcing-snowflake

[MongoID]: https://docs.mongodb.org/manual/reference/object-id/

References:

- http://www.slideshare.net/davegardnerisme/unique-id-generation-in-distributed-systems
- https://en.wikipedia.org/wiki/Universally_unique_identifier
- https://blog.twitter.com/2010/announcing-snowflake
- Go port by [Olivier Poitrey](https://github.com/rs): https://github.com/rs/xid
- Python port by [Graham Abbott](https://github.com/graham): https://github.com/graham/python_xid
- Scala port by [Egor Kolotaev](https://github.com/kolotaev): https://github.com/kolotaev/ride
- Rust port by [Jérôme Renard](https://github.com/jeromer/): https://github.com/jeromer/libxid
- Ruby port by [Valar](https://github.com/valarpirai/): https://github.com/valarpirai/ruby_xid
- Java port by [0xShamil](https://github.com/0xShamil/): https://github.com/0xShamil/java-xid
- Dart port by [Peter Bwire](https://github.com/pitabwire): https://pub.dev/packages/xid
- PostgreSQL port by [Rasmus Holm](https://github.com/crholm): https://github.com/modfin/pg-xid
- Swift port by [Uditha Atukorala](https://github.com/uditha-atukorala): https://github.com/uditha-atukorala/swift-xid
- C++ port by [Uditha Atukorala](https://github.com/uditha-atukorala): https://github.com/uditha-atukorala/libxid


