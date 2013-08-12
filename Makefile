bot.beam: bot.erl
	erlc bot.erl

bot.erl: botcore.erl botutils.erl botparse.erl botsettings.erl
	cpp botcore.erl | sed '/^#/d' > bot.erl

.PHONY: start
start: bot.beam
	erl -run bot connect
