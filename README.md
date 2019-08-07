# HTTP Proxy

**A proxy server. WIP**

## Dependencies
To run or build the code you must first run
```bash
$ mix deps.get
```

## Running
```bash
$ MIX_ENV=prod mix run --no-halt
```
will start the proxy server.

The http proxy server can be accessed at `127.0.0.1:4480`.

```

## Building
To create a release use:

```bash
$ mix release
```

To create a production release use:

```bash
$ MIX_ENV=prod mix release
```


