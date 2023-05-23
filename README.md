# erl2json

> Parse Erlang terms as strings into a json, preserving its type

### Example

Imagine you have a file with the following content:

```erlang
{ok, [
    [1,2,3],
    [atoms, wrapped],
    {person, "John", 42},
    [{name, "Mary"}, {age, 32}],
    [true, false, undefined, null],
    <<"base64">>,
    <0.23.0>,
    {"a", "tuple"}
]}
```

```bash {cmd}
cat examples/readme.erl | erl2json
```

```json
{
  "type": "tuple",
  "record": "ok",
  "values": [
    [
      [ 1, 2, 3 ],
      [
        { "type": "atom", "value": "atoms" },
        { "type": "atom", "value": "wrapped" },
      ],
      { "type": "tuple", "record": "person", "values": [ "John", 42 ] },
      { "age": 32, "name": "Mary" },
      [
        { "type": "boolean", "value": true },
        { "type": "boolean", "value": false },
        { "type": "atom", "value": "undefined" },
        { "type": "atom", "value": "null" }
      ],
      { "type": "binary", "value": "YmFzZTY0" },
      { "type": "pid", "value": "<0.23.0>" },
      { "type": "tuple", "values": [ "a", "tuple" ] }
    ]
  ]
}
```

### Advanced JSON Transformation

The utility `jq` can be used to transform the json into anything you want.


```bash {cmd}
erl2json < examples/readme.erl | jq '.values[0] | {
  count: .[0],
  atoms: .[1] | map(.value),
  person: .[2].values | {
    name: .[0],
    age: .[1]
  },
}'
```

```json
{
  "count": [ 1, 2, 3 ],
  "atoms": [ "atoms", "wrapped" ],
  "person": { "name": "John", "age": 42 }
}
```

### Installation

Via nix flakes:

```bash {cmd}
# install it
nix profile install github:expelledboy/erl2json

# or run directly
cat examples/readme.erl | nix run github:expelledboy/erl2json
```

