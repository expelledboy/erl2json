#!/usr/bin/env bats

bats_require_minimum_version "1.5.0"

BIN=${PWD}/_build/default/bin/erl2json

setup() {
    bats_require_minimum_version "1.8.0"
    bats_load_library bats-support
    bats_load_library bats-assert

    DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
    PATH="$DIR/../_build/default/bin:$PATH"
    FIXTURE=$DIR/fixture/complex_erlang_object
}

@test "test setup" {
    assert which $BIN
    echo "Fixture: $FIXTURE"
    assert test -f ${FIXTURE}.txt
    assert test -f ${FIXTURE}.json
}

@test "pipe via stdin" {
    refute $BIN <<<"ok."
    assert $BIN <<<"ok"
}

@test "output is valid json" {
    # https://github.com/stedolan/jq/issues/1637
    refute bash -o pipefail -c "echo 'ok.' | $BIN | jq empty"
    assert bash -o pipefail -c "echo 'ok' | $BIN | jq empty"
}

@test "complex test fixture" {
    fixture=$(tr -d '[:space:]' <${FIXTURE}.json)

    run bash -o pipefail -c "cat ${FIXTURE}.txt | $BIN"
    assert_success
    assert_output "$fixture"

    assert bash -o pipefail -c "echo '$output' | jq empty"
    assert bash -o pipefail -c "echo '$output' | jq '.values[0][0].record' | grep -q 'record'"
}

@test "escape special characters" {
    run $BIN <<<'"\n"'
    assert_success
    assert_output '"\\n"'

    run bash -o pipefail -c "echo '\"\\n\"' | $BIN | jq empty"
    assert_success
}
