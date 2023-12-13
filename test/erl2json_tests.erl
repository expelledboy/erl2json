-module(erl2json_tests).
-include_lib("eunit/include/eunit.hrl").
-define(module, erl2json).
-import(?module, [abstract_to_json/1]).
-import(?module, [encode/1]).
-import(?module, [pre_encode/1]).

%% --

pre_encode_test() ->
    ?assertEqual("{bit_string,[2,3,4]}", pre_encode("<<2,3,4>>")),
    ?assertEqual("{pid,\"<0.0.0>\"}", pre_encode("<0.0.0>")),
    ?assertEqual("{pid,\"<core1@alpha.local.1775.0>\"}", pre_encode("<core1@alpha.local.1775.0>")).

%% --

basic_types() ->
    % https://www.tutorialspoint.com/erlang/erlang_data_types.htm
    Ref = make_ref(),
    [
        % Type, Term, Parsed
        {pid, self(), pid_to_list(self())},
        {ref, Ref, ref_to_list(Ref)},
        {atom, symbol, "symbol"},
        {number, 12345, "12345"},
        {string, "text", <<"text">>}
    ].

basic_types_test_() ->
    [
        ?_assertEqual(
            {json, Type, Encoded},
            encode(Term)
        )
     || {Type, Term, Encoded} <- basic_types()
    ].

result_test_() ->
    lists:flatten([
        [
            ?_assertEqual({json, tuple, #{record => "ok", values => [{json, Type, Encoded}]}}, encode({ok, Term})),
            ?_assertEqual({json, tuple, #{record => "error", values => [{json, Type, Encoded}]}}, encode({error, Term}))
        ]
     || {Type, Term, Encoded} <- basic_types()
    ]).

string_list_test() ->
    ?assertEqual({json, string, <<"hello">>}, encode("hello")),
    ?assertEqual({json, string, <<"hello">>}, encode([104, 101, 108, 108, 111])).

% XXX: We have to assume an empty list is NOT a string, but a native list
empty_list_exception_test() ->
    ?assertEqual({json, array, []}, encode([])),
    ?assertEqual({json, array, []}, encode("")).

binary_test() ->
    ?assertEqual({json, binary, <<"aGVsbG8=">>}, encode(<<"hello">>)).

quoted_atom_test() ->
    ?assertEqual({json, atom, "hello world"}, encode('hello world')).

tuple_test() ->
    Encoded = [encode(1), encode(2), encode(3)],
    ?assertEqual({json, tuple, #{values => []}}, encode({})),
    ?assertEqual({json, tuple, #{values => Encoded}}, encode({1, 2, 3})),
    ?assertEqual({json, tuple, #{record => "class", values => Encoded}}, encode({class, 1, 2, 3})).

list_test() ->
    List = [1, 2, 3, 4, 5],
    ?assertEqual({json, array, []}, encode([])),
    ?assertEqual({json, array, [encode(X) || X <- List]}, encode(List)).

list_nested_test_() ->
    [
        ?_assertEqual(
            {json, array, [{json, Type, Encoded}]},
            encode([Term])
        )
     || {Type, Term, Encoded} <- basic_types()
    ].

map_test() ->
    ?assertEqual({json, object, #{}}, encode(#{})),
    ?assertEqual({json, object, #{"A" => {json, number, "1"}}}, encode(#{"A" => 1})).

map_encode_nested_test() ->
    ?assertEqual({json, object, #{"A" => {json, number, "1"}}}, encode(#{"A" => 1})),
    ?assertEqual({json, object, #{"A" => {json, object, #{"B" => {json, number, "1"}}}}}, encode(#{"A" => #{"B" => 1}})).

%% --

complex_test() ->
    {ok, Erl} = file:read_file("test/fixture/complex_erlang_object.txt"),
    {ok, Json} = file:read_file("test/fixture/complex_erlang_object.json"),
    NoWhitespace = fun(X) -> re:replace(X, "\\s+", "", [global, {return, list}]) end,
    ?assertEqual(NoWhitespace(Json), ?module:from_string(Erl)).
