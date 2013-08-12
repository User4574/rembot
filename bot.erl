-module(bot).
-export([connect/0, loop/1]).

-define(nickname, "RemBot").
-define(channels, ["#cs-york", "##chemistry"]).
%-define(channels, ["##rembottest"]).


-define(confirmmessages, ["I cannot forget.", "Consider it done.", "I will remind them."]).
-define(banlist, ["dforsyth", "dforsyth_"]).

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

reminder(From, Channel, Who, Time, Message, Sock) ->
 receive
 after (Time * 1000) ->
  if
   From == Who ->
    irc_send(Sock, Channel, [Who] ++ ": You asked me to remind you to:" ++ [Message]);
   true ->
    irc_send(Sock, Channel, [Who] ++ ": " ++ [From] ++ " asked me to remind you to:" ++ [Message])
  end
 end.

reminder(From, Who, Time, Message, Sock) ->
 receive
 after (Time * 1000) ->
  if
   From == Who ->
    irc_send(Sock, Who, [Who] ++ ": You asked me to remind you to:" ++ [Message]);
   true->
    irc_send(Sock, Who, [Who] ++ ": " ++ [From] ++ " asked me to remind you to:" ++ [Message])
  end
 end.

confirm_message() ->
 random:seed(now()),
 X = random:uniform(65536),
 N = length(?confirmmessages),
 Y = (X rem N) + 1,
 lists:nth(Y, ?confirmmessages).

parse_user(User) ->
 [PUser, _] = string:tokens(User, "!"),
 PUser.

parse_time(Time) ->
 Timetuple = time_string_to_time_and_mod(Time),
 if
  Timetuple =/= {} ->
   {T, M} = Timetuple,
   if
    M == [] orelse M == "s" orelse M == "S" -> T;
    M == "m" orelse M == "M" -> T * 60;
    M == "h" orelse M == "H" -> T * 60 * 60;
    M == "d" orelse M == "D" -> T * 60 * 60 * 24;
    true -> -1
   end;
  true -> -1
 end.

time_string_to_time_and_mod(T) -> time_string_to_time_and_mod(T, [], []).
time_string_to_time_and_mod([], Ti, M) ->
 {Ts, []} = string:to_integer(Ti),
 if
  length(M) > 1 ->
   {};
  true ->
   {Ts, M}
 end;
time_string_to_time_and_mod([H|T], Ti, M) ->
 if
  (H < 58 andalso H > 47) ->
   time_string_to_time_and_mod(T, Ti ++ [H], M);
  (H==83 orelse H==115 orelse H==72 orelse H==104 orelse H==77 orelse H==109 orelse H==68 orelse H==100) ->
   if
    T == [] ->
     time_string_to_time_and_mod(T, Ti, M ++ [H]);
    true ->
     {}
   end;
  true -> {}
 end.

parse_msg(List) -> parse_msg(List, []).
parse_msg([], S) -> S;
parse_msg([H|T], S) -> parse_msg(T, S ++ " " ++ H).
parse_line(Sock, [_,"376"|_]) ->
 lists:foreach(fun(X) -> gen_tcp:send(Sock, "JOIN :" ++ X ++ "\r\n") end, ?channels);

parse_line(Sock, ["PING"|Rest]) ->
        gen_tcp:send(Sock, "PONG " ++ Rest ++ "\r\n");

parse_line(Sock, [_User, "PRIVMSG", ?nickname, "&quit", "doitnow" | _]) ->
 irc_send(Sock, _User, "Goodbye, World!"),
 gen_tcp:send(Sock, "QUIT\r\n"),
 gen_tcp:close(Sock),
 exit("remote stopped");

parse_line(Sock, [_User, "PRIVMSG", ?nickname, "&help" | _]) ->
 irc_send(Sock, parse_user(_User), "&remind <nick> <time> <msg> or &remind me <time> <msg>. <time> is of the form [0-9]+[shmd]? ({Seconds}, Hours, Minutes, Days).");

parse_line(Sock, [_User, "PRIVMSG", ?nickname, "&remind", Who, Time | Message]) ->
 ParsedTime = parse_time(Time),
 ParsedUser = parse_user(_User),
 [Hash|_] = Who,
 BannedUser = lists:member(ParsedUser, ?banlist),
 if
  ParsedTime =/= -1 ->
   if
    BannedUser ->
            irc_send(Sock, ParsedUser, "I cannot let you do that, " ++ ParsedUser ++ ". Access Denied.");
    Who == "me" ->
     spawn(fun() -> reminder(ParsedUser, ParsedUser, ParsedTime, parse_msg(Message), Sock) end),
            irc_send(Sock, ParsedUser, confirm_message());
    Hash == 35 ->
            irc_send(Sock, ParsedUser, "I cannot let you do that, " ++ ParsedUser ++ ".");
    true ->
     spawn(fun() -> reminder(ParsedUser, Who, ParsedTime, parse_msg(Message), Sock) end),
            irc_send(Sock, ParsedUser, confirm_message())
   end;
  true ->
          irc_send(Sock, ParsedUser, "Invalid time specifier.")
 end;

parse_line(Sock, [_User, "PRIVMSG", Channel, "&help" | _]) ->
 irc_send(Sock, Channel, "&remind <nick> <time> <msg> or &remind me <time> <msg>. <time> is of the form [0-9]+[shmd]? ({Seconds}, Hours, Minutes, Days).");

parse_line(Sock, [_User, "PRIVMSG", Channel, "&remind", Who, Time | Message]) ->
 ParsedTime = parse_time(Time),
 ParsedUser = parse_user(_User),
 BannedUser = lists:member(ParsedUser, ?banlist),
 if
  ParsedTime =/= -1 ->
   if
    BannedUser ->
            irc_send(Sock, Channel, "I cannot let you do that, " ++ ParsedUser ++ ". Access Denied.");
    Who == "me" ->
     spawn(fun() -> reminder(ParsedUser, Channel, ParsedUser, ParsedTime, parse_msg(Message), Sock) end),
            irc_send(Sock, Channel, confirm_message());
    true ->
     spawn(fun() -> reminder(ParsedUser, Channel, Who, ParsedTime, parse_msg(Message), Sock) end),
            irc_send(Sock, Channel, confirm_message())
   end;
  true ->
          irc_send(Sock, Channel, "Invalid time specifier.")
 end;

parse_line(_, _) -> 0.
