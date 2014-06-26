-module(child).

-behaviour(gen_server).

-export([start_link/1, start_link/0,stop/1]).
-export([init/1, handle_call/3, handle_cast/2,
handle_info/2, code_change/3, terminate/2]).
 
-record(state, {name="", dir=""}).
-define(DELAY, 10500).
 
start_link() ->
	gen_server:start_link(?MODULE, [], []).
start_link(Args) ->
	gen_server:start_link(?MODULE, Args, []).

init({Dir,_Type,close_write,_Coockie,Name}) ->
	error_logger:info_report("starting "++Name++" watch"),
	{ok, #state{name=Name,dir=Dir}, ?DELAY};
init({_Dir,_Type,OP,_Coockie,Name}) -> 
	error_logger:info_report("ignoring operation " ++io_lib:format("~p",[OP])++" on "++Name),
	{ignore};
	
init(worker) -> {ok,#state{name=worker}};
init([]) -> 
%(simple,{test,{io,format,["test child",[]]},temporary,brutal_kill, worker, [io]}).
	Callback = fun ({File,_Type,_OP,_Coockie,Name}=A) -> 
				case supervisor:start_child(simple, {File++Name, {child,start_link,[A]}, temporary, brutal_kill, worker, [child]}) of
					{ok,_} -> ok;
					{error,{already_started,P} } -> error_logger:info_report("casting message to "++io_lib:format("~p",[P])),
													gen_server:cast(P,A);
					_ -> ok
				end end,
	erlinotify:watch("/tmp/",Callback),
	{ok,#state{}}.
 
stop(Role) -> gen_server:call(Role, stop).

 
handle_call({process,F},_From,#state{name=worker}=S ) ->
	error_logger:info_report("this worker is going to process "++F),
	{reply,ok, S};
handle_call(_Message, _From, S) ->
	{noreply, S}.
handle_cast(M, S) ->
	error_logger:info_report("got cast "++io_lib:format("~p",[M])++", while File is "++S#state.name),
	{noreply, S, ?DELAY}.

handle_info(timeout,State) -> 
	error_logger:info_report("starting "++State#state.name++" processing"),
	poolboy:transaction(workers, fun(Worker) -> gen_server:call(Worker,{process,State#state.dir++State#state.name}) end),
	{stop,shutdown,State}.

code_change(_,_,_) -> ok.
terminate(_,_) -> ok.
