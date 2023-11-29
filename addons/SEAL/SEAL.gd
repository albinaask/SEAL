extends Node

var logger := LogStream.new("Settings")


var setting_singletons := [] :
	set(val):
		logger.err("can't set this variable since it is read-only")
