-module(netstring_test).

-include_lib("eunit/include/eunit.hrl").


encode_empty_test() ->
    Enc = iolist_to_binary(netstring:encode([])),
    ?assertEqual(Enc, <<"0:,">>).

encode_single_char_test() ->
    Enc = iolist_to_binary(netstring:encode("a")),
    ?assertEqual(Enc, <<"1:a,">>).

encode_iolist_test() ->
    Enc = iolist_to_binary(netstring:encode([$a, [$b, $c]])),
    ?assertEqual(Enc, <<"3:abc,">>).

decode_empty_test() ->
    {Payload, Rest} = netstring:decode(<<"0:,">>),
    ?assertEqual(Payload, <<>>),
    ?assertEqual(Rest, <<>>).

decode_single_char_test() ->
    {Payload, Rest} = netstring:decode(<<"1:a,">>),
    ?assertEqual(Payload, <<"a">>),
    ?assertEqual(Rest, <<>>).

decode_multi_char_test() ->
    {Payload, Rest} = netstring:decode(<<"9:012345678,">>),
    ?assertEqual(Payload, <<"012345678">>),
    ?assertEqual(Rest, <<>>).

decode_two_digit_length_test() ->
    {Payload, Rest} = netstring:decode(<<"20:01234567890123456789,">>),
    ?assertEqual(Payload, <<"01234567890123456789">>),
    ?assertEqual(Rest, <<>>).

decode_empty_trailing_test() ->
    {Payload, Rest} = netstring:decode(<<"0:,rest">>),
    ?assertEqual(Payload, <<>>),
    ?assertEqual(Rest, <<"rest">>).

decode_incomplete_comma_test() ->
    Val = netstring:decode(<<"0:">>),
    ?assertEqual(Val, incomplete).

decode_incomplete_colon_test() ->
    Val = netstring:decode(<<"0">>),
    ?assertEqual(Val, incomplete).

decode_incomplete_empty_test() ->
    Val = netstring:decode(<<"">>),
    ?assertEqual(Val, incomplete).

decode_incomplete_not_enough_test() ->
    Val = netstring:decode(<<"2:a">>),
    ?assertEqual(Val, incomplete).

decode_error_not_a_digit_test() ->
    Val = netstring:decode(<<"a">>),
    ?assertEqual(Val, {error, not_a_digit}).

decode_error_not_a_digit2_test() ->
    Val = netstring:decode(<<"1a">>),
    ?assertEqual(Val, {error, not_a_digit}).

decode_error_no_colon_test() ->
    Val = netstring:decode(<<"01:a,">>),
    ?assertEqual(Val, {error, no_colon}).

decode_error_no_comma_test() ->
    Val = netstring:decode(<<"1:aa">>),
    ?assertEqual(Val, {error, no_comma}).

decode_with_state_test() ->
    S0 = netstring:init(),
    {incomplete, S1} = netstring:decode(<<"2">>, S0),
    2 = netstring:current_length(S1),
    {incomplete, S2} = netstring:decode(<<":">>, S1),
    {incomplete, S3} = netstring:decode(<<"a">>, S2),
    {incomplete, S4} = netstring:decode(<<"b">>, S3),
    {<<"ab">>, S5} = netstring:decode(<<",rest">>, S4),
    <<"rest">> = netstring:remaining(S5).
