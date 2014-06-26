-module(simpleapp).
-behaviour(application).
-behaviour(supervisor).

-export([start/0, stop/0]).
-export([start/2, stop/1]).
-export([init/1]).

start() ->
    application:start(?MODULE).

stop() ->
    application:stop(?MODULE).

start(_Type, _Args) ->
    supervisor:start_link({local, simple}, ?MODULE, []).

stop(_State) ->
    ok.

init([]) ->
	Pools=[{name,{local,workers}},{worker_module,child},{size,5},{max_overflow,0}],
    {ok, {{one_for_one, 10, 10}, [
	{etsm, {ets_manager,start_link,[]}, permanent, 5000, worker,[ets_manager]},
	{inotify,{erlinotify,start_link,[]} ,permanent, 5000,worker,[erlinotify]},
	{child,{child, start_link,[]} ,permanent, 5000,worker,[child]},
	poolboy:child_spec(workers,Pools,worker)
	]}}.





