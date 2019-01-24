%% -------------------------------------------------------------------
%%
%% Copyright (c) 2017 Carlos Gonzalez Florido.  All Rights Reserved.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------

%% @doc Node Object

-module(nkdomain_node_obj).
-behavior(nkdomain_obj).
-author('Carlos Gonzalez <carlosj.gf@gmail.com>').

-include("nkdomain.hrl").

-export([create/0]).
-export([object_info/0, object_admin_info/0, object_parse/2]).
-export([object_api_syntax/2, object_api_cmd/2, object_send_event/2]).
-export([object_execute/5, object_schema/1, object_query/3, object_mutation/3]).
-export_type([events/0]).

-define(LLOG(Type, Txt, Args),
    lager:Type("NkDOMAIN Node "++Txt, Args)).


%% ===================================================================
%% Types
%% ===================================================================


-type events() ::
    {}.


%% ===================================================================
%% API
%% ===================================================================


%% @doc
-spec create() ->
    {ok, NodeId::nkdomain:obj_id(), pid()} | {error, term()}.

create() ->
    Obj = #{
        type => ?DOMAIN_NODE,
        obj_name => nkdomain_node:get_node_obj_name(),
        domain_id => <<"root">>,
        created_by => <<"admin">>
    },
    case nkdomain_obj_make:create(Obj) of
        {ok, #obj_id_ext{obj_id=NodeId, pid=Pid}, _Unknown} ->
            {ok, NodeId, Pid};
        {error, Error} ->
            {error, Error}
    end.



%% ===================================================================
%% nkdomain_obj behaviour
%% ===================================================================


%% @private
object_info() ->
    #{
        type => ?DOMAIN_NODE,
        schema_type => 'Server',
        permanent => true
    }.


%% @doc
object_admin_info() ->
    #{
        class => session,
        weight => 100,
        type_view_mod => nkdomain_node_obj_type_view 
%%        tree_id => <<"domain_tree_sessions_node">>
    }.


%% @doc
object_schema(Type) ->
    nkdomain_node_obj_schema:object_schema(Type).


%% @doc
object_execute(Field, ObjIdExt, #{?DOMAIN_USER:=User}, Args, _Ctx) ->
    nkdomain_node_obj_schema:object_execute(Field, ObjIdExt, User, Args).


%% @doc
object_query(QueryName, Params, Ctx) ->
    nkdomain_node_obj_schema:object_query(QueryName, Params, Ctx).


%% @doc
object_mutation(MutationName, Params, Ctx) ->
    nkdomain_node_obj_schema:object_mutation(MutationName, Params, Ctx).


% @private
object_parse(_Mode, _Map) ->
    #{}.


% @private
object_api_syntax(Cmd, Syntax) ->
    nkdomain_node_obj_syntax:syntax(Cmd, Syntax).


%% @private
object_send_event(Event, State) ->
    nkdomain_node_obj_events:event(Event, State).


%% @private
object_api_cmd(Cmd, Req) ->
    nkdomain_node_obj_cmd:cmd(Cmd, Req).





%% ===================================================================
%% Internal
%% ===================================================================