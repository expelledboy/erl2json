#!/usr/bin/env bats

bats_require_minimum_version "1.5.0"

BIN=erl2json

setup() {
    DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
    PATH="$DIR/../_build/default/bin:$PATH"
    FIXTURE=$DIR/fixture/complex_erlang_object
}

@test "test setup" {
    which $BIN
    echo "Fixture: $FIXTURE"
    test -f ${FIXTURE}.txt
    test -f ${FIXTURE}.json
}

@test "pipe via stdin" {
    eval "echo '{ok,[]}' | $BIN"
    [ $? -eq 0 ]
}

@test "output is valid json" {
    # https://github.com/stedolan/jq/issues/1637
    echo '{person, "John", "Doe" 42}}' | $BIN | jq empty
    [ $? -eq 0 ]
}

@test "complex test fixture" {
    result=$(cat ${FIXTURE}.txt | $BIN)
    no_whitespace=$(tr -d '[:space:]' <${FIXTURE}.json)

    echo "$result" | jq empty
    [ $? -eq 0 ]

    echo "$result" | jq '.values[0][0].record' | grep -q 'record'
    [ $? -eq 0 ]

    [ "$result" == "$no_whitespace" ]
}

@test "error on invalid input" {
    run ! bash -c "echo '{]}' | $BIN"
    [ "$output" == "Error Parsing Erlang: syntax error before: ']'" ]
}
