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
				true ->     -1
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
