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
