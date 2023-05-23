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
cat example.erl | erl2json
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


```erlang
[{person, "Mary", 32},
 {person, "John", 42},
 {person, "Jane", 22}]
```

```bash {cmd}
erl2json < persons.erl | jq '.[] | select(.record == "person") | .values[0]'
```

```
"Mary"
"John"
"Jane"
```