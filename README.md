This is a little Erlang module for creating and parsing netstrings.

You can use it to create netstrings (as iolists):

3> netstring:encode(<<"abcd">>).
["4",58,<<"abcd">>,44]

4> netstring:encode("abcd").    
["4",58,"abcd",44]

And to decode netstrings, including partial netstrings. The netstring
must be in binary form:

6> netstring:decode(<<"4:abcd,">>).         
{<<"abcd">>,<<>>}

7> netstring:decode(<<"4:abcd,extra">>).
{<<"abcd">>,<<"extra">>}

8> NS0 = netstring:init().
{parse_state,start,0,<<>>}

10> {_, NS1} = netstring:decode(<<"4:">>, NS0).
{incomplete,{parse_state,body,4,<<>>}}

11> {_, NS2} = netstring:decode(<<"abcd,">>, NS1).
{<<"abcd">>,{parse_state,start,0,<<>>}}
