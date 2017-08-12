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

%% @doc Config Object

-module(nkdomain_mail_provider_obj).
-behavior(nkdomain_obj).
-author('Carlos Gonzalez <carlosj.gf@gmail.com>').

-export([find/1, delete_all/1]).
-export([object_info/0, object_admin_info/0, object_parse/3, object_es_mapping/0]).

-include("nkdomain.hrl").
-include_lib("nkmail/include/nkmail.hrl").
-include_lib("nkapi/include/nkapi.hrl").

-define(LLOG(Type, Txt, Args),
    lager:Type("NkMAIL Provider "++Txt, Args)).


%% ===================================================================
%% Types
%% ===================================================================


%% ===================================================================
%% API
%% ===================================================================


%% @private
find(SrvId) ->
    nkdomain_domain_obj:search(SrvId, <<"root">>, #{filters=>#{type=>?DOMAIN_MAIL_PROVIDER}}).


%% @private
delete_all(SrvId) ->
    nkdomain:delete_all_childs_type(SrvId, <<"root">>, ?DOMAIN_MAIL_PROVIDER).




%% ===================================================================
%% nkdomain_obj behaviour
%% ===================================================================


%% @private
object_info() ->
    #{
        type => ?DOMAIN_MAIL_PROVIDER,
        subtype => [?DOMAIN_CONFIG]
    }.


%% @doc
object_admin_info() ->
    #{
        class => resource,
        weight => 9000
    }.


%% @private
object_es_mapping() ->
    not_indexed.


%% @private
object_parse(SrvId, _Mode, Obj) ->
    #{?DOMAIN_MAIL_PROVIDER:=Config} = Obj,
    case nkmail:parse_provider(SrvId, Config, #{path=>?DOMAIN_MAIL_PROVIDER}) of
        {ok, Provider, UnknownFields} ->
            {type_obj, Provider, UnknownFields};
        {error, Error} ->
            {error, Error}
    end.




