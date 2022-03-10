# Synopsis

This repository is an Elixir learning exercise.

**Disclaimer : Do not use this code in production.**

## Subject of the exercise

The subject of this exercise is to play with esbuild and CLI application.

This CLI is used to manage the RSA and AES keys of a [CryptoStorage](https://github.com/odelbos/le-elixir-2-cryptostorage) server.

## Setup

As the config.json is not encrypted, we use it with a [securefs](https://github.com/netheril96/securefs) volume.

Create a `securefs` volume and clone this repository inside it then run :

```sh
mix deps.get
mix escript.build
```

This will produce a `./storage_manager` executable.

## Usage

```
-----------------------------------------------------
Usage
-----------------------------------------------------

Commands:

  list
      List all the entries from config file.

  add
      This command will add a new remote CryptoStorage server to the
      local configuration.
      It will generate an RSA keys pair for server comminication.
      It will generate an AES storage key used to setup the remote server.

      You must provide the following switches : --url, --name.

  setup
      This command will setup a remote CryptoStorage server
      It will call /setup on the remote server and send the storage key.

      You must provide the following switches : --name.

Samples:
  ./storage_manager list
  ./storage_manager add --url h.com/setup --name rpi1
  ./stroage_manager setup --name rpi1
```