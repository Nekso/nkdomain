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

%% @doc GraphQL Type Callback
-module(nkdomain_graphql_type).
-author('Carlos Gonzalez <carlosj.gf@gmail.com>').

-include("nkdomain.hrl").

-export([execute/1]).


%% @doc Called when a abstract object is found (interface or union)
%% to find its type
%% Called from graphql_execute:514 (others from :778)

execute({#obj_id_ext{type=Type}, _Obj}) ->
    lager:debug("NKLOG Resolving type ~s", [Type]),
    case nkdomain_reg:get_type_module(Type) of
        undefined ->
            {error, unknown_type};
        Module ->
            case Module:object_info() of
                #{schema_type:=SchemaType} ->
                    lager:debug("NKLOG Resolved type ~s: ~s", [Type, SchemaType]),
                    {ok, SchemaType};
                _ ->
                    {error, unknown_type}
            end
    end;

execute(_Obj) ->
    lager:error("NKLOG Invalid type execute  ~p", [_Obj]),
    error(invalid_type).