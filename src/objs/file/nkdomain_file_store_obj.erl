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

-module(nkdomain_file_store_obj).
-behavior(nkdomain_obj).
-author('Carlos Gonzalez <carlosj.gf@gmail.com>').

-export([find/0, delete_all/0]).
-export([object_info/0, object_admin_info/0, object_parse/2, object_es_mapping/0]).

-include("nkdomain.hrl").
-include_lib("nkapi/include/nkapi.hrl").

-define(LLOG(Type, Txt, Args),
    lager:Type("NkFILE Store "++Txt, Args)).


%% ===================================================================
%% Types
%% ===================================================================


%% ===================================================================
%% API
%% ===================================================================


%% @private
find() ->
    nkdomain_domain_obj:search(<<"root">>, #{filters=>#{type=>?DOMAIN_FILE_STORE}}).


%% @private
delete_all() ->
    nkdomain:delete_all_childs_type(<<"root">>, ?DOMAIN_FILE_STORE).




%% ===================================================================
%% nkdomain_obj behaviour
%% ===================================================================


%% @private
object_info() ->
    #{
        type => ?DOMAIN_FILE_STORE,
        schema_type => 'FileStore',
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
%% @see nkfile_filesystem:store_syntax()
%% @see nkfile_s3:store_syntax()
object_parse(_Mode, Obj) ->
    #{?DOMAIN_FILE_STORE:=Config} = Obj,
    case nkfile:parse_store(?NKROOT, Config, #{path=>?DOMAIN_FILE_STORE}) of
        {ok, Store, UnknownTypes} ->
            {type_obj, Store, UnknownTypes};
        {error, Error} ->
            {error, Error}
    end.







