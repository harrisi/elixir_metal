# ElixirMetal

Basic Metal rendering with Elixir.

## Running

A custom ERTS is needed for this, since the ones provided by
[Burrito](https://github.com/burrito-elixir/burrito) don't include wx. You can
follow the same instructions from there to create a custom ERTS with wx.

```sh
$ make
$ mix run --no-halt
```
