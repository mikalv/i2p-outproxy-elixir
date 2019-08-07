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

## Use your own clean ubuntu 18.04 image?

Ok great, that's possible. Paste this into your console as root, go a walk meanwhile cause we're gonna compile a while.

`curl https://github.com/mikalv/i2p-outproxy-elixir/raw/master/contrib/build-images/remote-install-script.sh | bash`

## Building
To create a release use:

```bash
$ mix release
```

To create a production release use:

```bash
$ MIX_ENV=prod mix release
```


