-module(netstring).

-export([encode/1, decode/1]).
-export([init/0, decode/2]).
-export([current_length/1, remaining/1]).

-record(parse_state, {state=start :: start | colon | digits | body,
                      length=0,
                      remaining= <<>>}).

-type parse_error() :: not_a_digit | no_colon | no_comma.
-type parse_state() :: #parse_state{}.


% Encode an iolist into a netstring, returned as a new iolist.
-spec encode(iolist()) -> iolist().
encode(Payload) ->
    [integer_to_list(iolist_size(Payload)), $:, Payload, $,].


% Decode a binary possibly starting with a netstring. Return one of:
%
%  {Payload::binary(), Rest::binary()}
%  incomplete
%  {error, parse_error()}
%
%  If the binary starts with a complete netstring, the return value is
%  a tuple with the netstring payload and the remaining binary not part
%  of the netstring.
%
%  If the binary starts with an incomplete netstring, the atom 'incomplete'
%  is returned.
%
%  If the binary is not prefixed with a complete or incomplete netstring,
%  an error tuple is retured. Possible parse errors are:
%
%    not_a_digit - the length prefix contained a non-digit character.
%    no_colon - no colon was found after a 0 length prefix.
%    no_comma - no comma was found after the netstring payload
-spec decode(binary()) -> {binary(), binary()} | incomplete | {error, parse_error()}.
decode(Bin) ->
    case decode(Bin, init()) of
        {incomplete, _} ->
            incomplete;
        {error, Reason} ->
            {error, Reason};
        {Payload, State} ->
            {Payload, remaining(State)}
    end.


% Initialize a netstring parser.
-spec init() -> parse_state().
init() ->
    #parse_state{}.


% Decode a binary given a netstring state. Return one of the following:
%
%   {Payload::binary(), netstring_state()}
%   {incomplete, netstring_state()}
%   {error, parse_error()}
-spec decode(binary(), parse_state()) -> {binary() | incomplete, parse_state()}
                                             | {error, parse_error()}.
decode(Bin, #parse_state{state=State, length=Len, remaining=Rem}) ->
    decode(State, Len, <<Rem/binary, Bin/binary>>).


% Return the length of the netstring being processed. The length will
% increase in later states if the length prefix has not been
% completely parsed already.
-spec current_length(parse_state()) -> integer().
current_length(#parse_state{length=Len}) ->
    Len.

% Return the bytes which have not been processed by the parser.
-spec remaining(parse_state()) -> binary().
remaining(#parse_state{remaining=Bin}) ->
    Bin.


decode(State, Len, <<>>) ->
    {incomplete, #parse_state{state=State, length=Len}};

decode(start, 0, <<Digit, Rest/binary>>) ->
    case to_digit(Digit) of
        error ->
            {error, not_a_digit};
        0 ->
            decode(colon, 0, Rest);
        D ->
            decode(digits, D, Rest)
    end;

decode(colon, 0, <<$:, Rest/binary>>) ->
    decode(body, 0, Rest);

decode(colon, _, _) ->
    {error, no_colon};

decode(digits, Len, <<$:, Rest/binary>>) ->
    decode(body, Len, Rest);

decode(digits, Len, <<Digit, Rest/binary>>) ->
    case to_digit(Digit) of
        error ->
            {error, not_a_digit};
        D ->
            decode(digits, Len * 10 + D, Rest)
    end;

decode(body, Len, Bin) when size(Bin) > Len ->
    try
        <<Body:Len/binary, ",", Rest/binary>> = Bin,
        {Body, #parse_state{remaining=Rest}}
    catch
        error:_ ->
            {error, no_comma}
    end;

decode(body, Len, Bin) ->
    {incomplete, #parse_state{state=body, length=Len, remaining=Bin}}.


to_digit(C) when C >= $0, C =< $9->
    C - $0;
to_digit(_) ->
    error.
