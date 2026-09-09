-module(rudy).
-export([start/1, stop/0]).


init(Port) ->
Opt = [list, {active, false}, {reuseaddr, true}],
case gen_tcp:listen(Port, Opt) of
    {ok, Listen} -> 
        handler(Listen),
        gen_tcp:close(Listen),
        ok;
    {error, Error} ->
        error
end.

handler(Listen) ->
    case gen_tcp:accept(Listen) of
        {ok, Client} ->
            request(Client),
            handler(Listen);
        {error, Error} ->
            error
    end.

request(Client) ->
    %Recv = gen_tcp:recv(Client,0),
    Recv = read_request(Client, []),
    case Recv of
        {ok, Str} ->
            Request = http:parse_request(Str),
            Response = reply(Request),
            gen_tcp:send(Client,Response);
        {error, Error} ->
            io:format("rudy: error: ~w~n", [Error])
    end,
    gen_tcp:close(Client).

read_request(Client, A) ->
    case gen_tcp:recv(Client, 0) of
        {ok, Str} ->
            NextA = A ++ Str,
            case check_header_end(NextA) of
                true  -> {ok, NextA};
                false -> read_request(Client, NextA)
            end;
        {error, Error} ->
            {error, Error}
    end.

check_header_end([13,10,13,10|_]) -> true;
check_header_end([_|Rest]) -> check_header_end(Rest);
check_header_end([]) -> false.

reply({{get, URI, _}, _, _}) ->
    timer:sleep(40),
    http:ok("All good!").

% Stop and Start

start(Port) ->
    register(rudy, spawn(fun() -> init(Port) end)).
stop() ->
    exit(whereis(rudy), "time to die").
