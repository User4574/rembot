-module(bot).
-export([connect/0, loop/1]).

#include "botsettings.erl"

connect() ->
        {ok, Sock} = gen_tcp:connect("irc.freenode.net", 6667, [{packet, line}]),
        gen_tcp:send(Sock, "NICK " ++ ?nickname ++ "\r\n"),
        gen_tcp:send(Sock, "USER " ++ ?nickname ++ " blah blah :I am RemBot! &help me for more information.\r\n"),
	irc_send(Sock, "nickserv", "identify lblhack"),
	receive after 10000 -> ok end,
        loop(Sock).
        
loop(Sock) ->
        receive
                {tcp, Sock, Data} ->
                        parse_line(Sock, string:tokens(Data, ": \r\n")),
                        loop(Sock)
        end.

irc_send(Sock, To, Message) ->
        gen_tcp:send(Sock, "PRIVMSG " ++ To ++ " :" ++ Message ++ "\r\n").

#include "botutils.erl"
#include "botparse.erl"
