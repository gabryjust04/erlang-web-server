-module(test).
-export([bench/2,multi_bench/3]).


multi_bench(Host,Port,N) ->
    spawn(fun() -> 
        Result = bench(Host,Port) ,
        io:format("Result: ~p~n", [Result])
        end),
    if N == 1->
        ok;
    true ->
        multi_bench(Host,Port,N-1)
    end.




bench(Host, Port) ->
    Start = erlang:system_time(micro_seconds),
    run(10000, Host, Port),
    Finish = erlang:system_time(micro_seconds),
    Finish - Start.


run(N, Host, Port) ->
    if
    N == 0 ->
    ok;
    true ->
    request(Host, Port),
    run(N-1, Host, Port)
    end.


request(Host, Port) ->
    Opt = [list, {active, false}, {reuseaddr, true}],
    {ok, Server} = gen_tcp:connect(Host, Port, Opt),
    gen_tcp:send(Server, http:get("foo")),
    Recv = gen_tcp:recv(Server, 0),
    case Recv of
    {ok, _} ->
    ok;
    {error, Error} ->
    io:format("test: error: ~w~n", [Error])
    end,
    gen_tcp:close(Server).