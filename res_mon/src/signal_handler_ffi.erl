-module(signal_handler_ffi).
-export([wait_for_shutdown/0]).


wait_for_shutdown() ->
    erlang:unregister(erl_signal_server),
    erlang:register(erl_signal_server, self()),

    os:set_signal(sighup, handle),
    os:set_signal(sigquit, handle),
    os:set_signal(sigabrt, handle),
    os:set_signal(sigterm, handle),
    os:set_signal(sigalrm, handle),
    os:set_signal(sigstop, handle),
    os:set_signal(sigtstp, handle),

    receive
        {notify, sighup} -> ok;
        {notify, sigquit} -> ok;
        {notify, sigabrt} -> ok;
        {notify, sigterm} -> ok;
        {notify, sigalrm} -> ok;
        {notify, sigstop} -> ok;
        {notify, sigtstp} -> ok
    end.