%% Written by expelledboy 🙈

-module(erl2json).
-spec main(list()) -> ok.
-export([main/1, from_string/1]).

-ifdef(TEST).
-spec encode(term()) -> {json, atom(), list() | binary()}.
-spec is_proplist(term()) -> boolean().
-spec abstract_to_json(term()) -> string().
-export([encode/1, is_proplist/1, abstract_to_json/1, pre_encode/1]).
-endif.

%% --

encode({json, _, _} = Encoded) ->
    Encoded;
encode({pid, PreEncoded}) ->
    {json, pid, PreEncoded};
encode({bit_string, PreEncoded}) ->
    {json, bit_string, PreEncoded};
% wrapped terms
encode(Value) when is_boolean(Value) ->
    {json, boolean, atom_to_list(Value)};
encode(Value) when is_atom(Value) ->
    {json, atom, atom_to_list(Value)};
encode(Value) when is_number(Value) ->
    {json, number, format("~p", [Value])};
encode(Value) when is_pid(Value) ->
    {json, pid, pid_to_list(Value)};
encode(Value) when is_reference(Value) ->
    {json, ref, ref_to_list(Value)};
encode(Value) when is_port(Value) ->
    {json, port, erlang:port_to_list(Value)};
encode(Value) when is_function(Value) ->
    %% XXX don't know how to get details about the function
    {json, function, "#Function"};
% binary => base64(binary)
encode(Value) when is_binary(Value) ->
    {json, binary, base64:encode(Value)};
% assuming {atom,...} is always a record
encode(Tuple) when is_tuple(Tuple), is_atom(element(1, Tuple)) ->
    Type = atom_to_list(element(1, Tuple)),
    [_ | Values] = tuple_to_list(Tuple),
    case Values of
        [] ->
            {json, tuple, #{record => Type}};
        _ ->
            EncodedValues = [encode(Value) || Value <- Values],
            {json, tuple, #{record => Type, values => EncodedValues}}
    end;
% otherwise just make is a list of values
encode(Tuple) when is_tuple(Tuple) ->
    EncodedValues = [encode(Value) || Value <- tuple_to_list(Tuple)],
    {json, tuple, #{values => EncodedValues}};
%% treat an empty list as a list
%% XXX: list are a special case, since they can be strings, so its ambiguous
encode([]) ->
    {json, array, []};
encode(List) when is_list(List) ->
    case io_lib:printable_list(List) of
        true ->
            case unicode:characters_to_binary(List) of
                % error or incomplete
                {_, _, _} ->
                    {json, string, List};
                Binary ->
                    {json, string, Binary}
            end;
        false ->
            case is_proplist(List) of
                true ->
                    % put it in a map
                    encode(maps:from_list(List));
                false ->
                    % just a list 🥳
                    {json, array, [encode(Value) || Value <- List]}
            end
    end;
%% here be magic, so I split it out
encode(Map) when is_map(Map) ->
    JsonMap = encode_nested(Map),
    {json, object, JsonMap};
encode(Unhandled) ->
    throw({?MODULE, unhanded_term_encoding, Unhandled}).

encode_nested(Map) when is_map(Map) ->
    MapEncode = fun(Key, Value, Acc) ->
        case is_map(Value) of
            true -> maps:put(Key, {json, object, encode_nested(Value)}, Acc);
            false -> maps:put(Key, encode(Value), Acc)
        end
    end,
    maps:fold(MapEncode, #{}, Map).

%% --

% https://www.erlang.org/doc/reference_manual/data_types#escape-sequences

escape(List) when is_list(List) ->
    escape(<<>>, list_to_binary(List));
escape(Binary) when is_binary(Binary) ->
    escape(<<>>, Binary).

escape(Acc, <<>>) ->
    Acc;
escape(Acc, Binary) ->
    case Binary of
        <<"\b", Rest/binary>> -> escape(<<Acc/binary, "\\\\b">>, Rest);
        <<"\e", Rest/binary>> -> escape(<<Acc/binary, "\\\\e">>, Rest);
        <<"\f", Rest/binary>> -> escape(<<Acc/binary, "\\\\f">>, Rest);
        <<"\n", Rest/binary>> -> escape(<<Acc/binary, "\\\\n">>, Rest);
        <<"\r", Rest/binary>> -> escape(<<Acc/binary, "\\\\r">>, Rest);
        <<"\s", Rest/binary>> -> escape(<<Acc/binary, "\\\\s">>, Rest);
        <<"\t", Rest/binary>> -> escape(<<Acc/binary, "\\\\t">>, Rest);
        <<"\v", Rest/binary>> -> escape(<<Acc/binary, "\\\\v">>, Rest);
        <<Char, Rest/binary>> -> escape(<<Acc/binary, Char>>, Rest)
    end.

%% --

abstract_to_json({json, Type, Value}) ->
    case Type of
        atom -> wrap("atom", format("\"~s\"", [Value]));
        boolean -> wrap("boolean", Value);
        number -> Value;
        pid -> wrap("pid", format("\"~s\"", [Value]));
        ref -> wrap("ref", Value);
        port -> wrap("port", Value);
        function -> Value;
        binary -> wrap("binary", format("\"~s\"", [Value]));
        bit_string -> wrap("bit_string", format("~p", [Value]));
        string -> format("\"~s\"", [escape(Value)]);
        ok -> wrap("ok", Value);
        error -> wrap("error", Value);
        tuple -> tuple_to_json(Value);
        array -> array_to_json(Value);
        object -> map_to_json(Value)
    end.

wrap(Key, Value) ->
    format("{\"type\":\"~s\",\"value\":~s}", [Key, Value]).

map_to_json(JsonMap) ->
    Values = [format("\"~s\":~s,", [Key, abstract_to_json(Value)]) || {Key, Value} <- maps:to_list(JsonMap)],
    String = format([$\{ | Values], []),
    [_Comma | Json] = lists:reverse(String),
    list_to_binary(lists:reverse(Json) ++ [$\}]).

array_to_json(List) ->
    ValuesBinary = [lists:join($,, [abstract_to_json(Value) || Value <- List])],
    list_to_binary(format("[~s]", [ValuesBinary])).

tuple_to_json(Tuple) ->
    Values = maps:get(values, Tuple),
    case maps:get(record, Tuple, undefined) of
        undefined ->
            format("{\"type\":\"tuple\",\"values\":~s}", [array_to_json(Values)]);
        Record ->
            format("{\"type\":\"tuple\",\"record\":\"~s\",\"values\":~s}", [Record, array_to_json(Values)])
    end.

%% --

from_string(Str) when is_binary(Str) ->
    from_string(binary_to_list(Str));
from_string(Str) when is_list(Str) ->
    abstract_to_json(
        encode(
            eval_erl(pre_encode(Str))
        )
    ).

%% --

main(_Args) ->
    try
        stdout(from_string(read_stdin("")))
    catch
        error:{badmatch, {error, {_, erl_parse, Error}}} ->
            io:format(standard_error, "Error Parsing Erlang: ~s~n", [Error]),
            halt(1)
    end.

read_stdin(IO) ->
    case io:get_line("") of
        eof -> IO;
        Line -> read_stdin(IO ++ Line)
    end.

stdout(IO) ->
    io:format(IO),
    init:stop().

%% --

pre_encode(Str) ->
    Replacements = [
        {bit_string, "<<([0-9 ,]*)>>", "{bit_string,[\\1]}"},
        {pid, "(<[0-9]+\.[0-9]+\.[0-9]+>)", "{pid,\"\\1\"}"},
        {r26_pid, "(<.*@.*\.[0-9]+\.[0-9]+>)", "{pid,\"\\1\"}"}
    ],
    lists:foldl(
        fun({_, Pattern, Replacement}, Acc) ->
            re:replace(Acc, Pattern, Replacement, [{return, list}, global])
        end,
        Str,
        Replacements
    ).

%% --

is_reserved(K) ->
    lists:member(K, [
        'after',
        'and',
        'andalso',
        'band',
        'begin',
        'bnot',
        'bor',
        'bsl',
        'bsr',
        'bxor',
        'case',
        'catch',
        'cond',
        'div',
        'end',
        'fun',
        'if',
        'let',
        'maybe',
        'not',
        'of',
        'or',
        'orelse',
        'receive',
        'rem',
        'try',
        'when',
        'xor'
    ]).
unreserve(Form = {Reserved, LineNr}) when is_atom(Reserved) ->
    case is_reserved(Reserved) of
        true ->
            {'atom', LineNr, Reserved};
        false ->
            Form
    end;
unreserve(Form = {_F, _LineNr}) ->
    Form;
unreserve({Type, Value, _LineNr}) ->
    {Type, Value, _LineNr}.

%% --

eval_erl(Expression) when is_list(Expression) ->
    {ok, Tokens, _} = erl_scan:string(format("~s.", [Expression])),
    UnreservedTokens = [unreserve(T) || T <- Tokens],
    {ok, Parsed} = erl_parse:parse_exprs(UnreservedTokens),
    {value, Result, _} = erl_eval:exprs(Parsed, []),
    Result.

%% --

is_proplist([]) -> true;
is_proplist([{K, _} | L]) when is_atom(K) -> is_proplist(L);
is_proplist(_) -> false.

format(Template, Args) -> lists:flatten(io_lib:format(Template, Args)).
