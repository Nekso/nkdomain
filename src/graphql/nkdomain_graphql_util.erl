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

%% @doc
-module(nkdomain_graphql_util).
-author('Carlos Gonzalez <carlosj.gf@gmail.com>').

-export([object_execute/4, search/2, get_obj/1, get_type/1]).

-include("nkdomain.hrl").
-include("nkdomain_graphql.hrl").

%% ===================================================================
%% Public
%% ===================================================================


%% @doc GraphQL execute
-spec object_execute(binary(), nkdomain_graphql:object(), map(), map()) ->
    {ok, term()} | null | {error, term()} | obj_type_field.

object_execute(Field, {#obj_id_ext{}, Obj}, _Args, _Ctx) ->
    case Field of
        <<"aliases">> -> {ok, maps:get(aliases, Obj, [])};
        <<"createdBy">> -> nkdomain_graphql_util:get_obj(maps:get(created_by, Obj));
        <<"createdById">> -> {ok, maps:get(created_by, Obj)};
        <<"createdTime">> -> {ok, maps:get(created_time, Obj, null)};
        <<"description">> -> {ok, maps:get(description, Obj, null)};
        <<"destroyed">> -> {ok, maps:get(destroyed, Obj, false)};
        <<"destroyedCode">> -> {ok, maps:get(destroyed_code, Obj, null)};
        <<"destroyedReason">> -> {ok, maps:get(destroyed_reason, Obj, null)};
        <<"destroyedTime">> -> {ok, maps:get(destroyed_time, Obj, null)};
        <<"domain">> -> nkdomain_graphql_util:get_obj(maps:get(domain_id, Obj));
        <<"domainId">> -> {ok, maps:get(domain_id, Obj)};
        <<"enabled">> -> {ok, maps:get(enabled, Obj, true)};
        <<"expiresTime">> -> {ok, maps:get(expires_time, Obj, null)};
        <<"icon">> -> nkdomain_graphql_util:get_obj(maps:get(icon_id, Obj, null));
        <<"iconId">> -> {ok, maps:get(icon_id, Obj, null)};
        <<"id">> -> {ok, maps:get(obj_id, Obj)};
        <<"name">> -> {ok, maps:get(name, Obj, null)};
        <<"objId">> -> {ok, maps:get(obj_id, Obj)};
        <<"objName">> -> {ok, maps:get(obj_name, Obj)};
        <<"path">> -> {ok, maps:get(path, Obj)};
        <<"srvId">> -> {ok, maps:get(srv_id, Obj, null)};
        <<"subtypes">> -> {ok, maps:get(subtype, Obj, [])};
        <<"tags">> -> {ok, maps:get(tags, Obj, [])};
        <<"type">> -> nkdomain_graphql_util:get_type(Obj);
        <<"updatedBy">> -> nkdomain_graphql_util:get_obj(maps:get(updated_by, Obj, null));
        <<"updatedById">> -> {ok, maps:get(updated_by, Obj, null)};
        <<"updatedTime">> -> {ok, maps:get(updated_time, Obj, null)};
        <<"vsn">> -> {ok, maps:get(vsn, Obj, null)};
        _ -> obj_type_field
    end;

object_execute(Field, #search_results{}=SR, _, _) ->
    case Field of
        <<"objects">> ->
            {ok, [{ok, Obj} || Obj <- SR#search_results.objects]};
        <<"totalCount">> ->
            {ok, SR#search_results.total_count};
        <<"pageInfo">> ->
            {ok, SR#search_results.page_info};
        <<"cursor">> ->
            {ok, SR#search_results.cursor}
    end;

object_execute(Field, #page_info{}=PI, _, _) ->
    case Field of
        <<"hasNextPage">> ->
            {ok, PI#page_info.has_next_page};
        <<"hasPreviousPage">> ->
            {ok, PI#page_info.has_previous_page}
    end;

object_execute(_Field, _Obj, _Args, _Ctx) ->
    lager:error("Invalid execute at ~p: ~p, ~p", [?MODULE, _Field, _Obj]),
    error(invalid_execute).


% Search operations
% - All 'and' filters go together, all must be true
% - All 'not' filters go together, all must be false
% - All 'or' filters go together (even if several are used for a single field)
%   One or more of them must be true

-type search_opts() ::
    #{
        fields => #{
            binary() => atom()|binary()|list() | {norm, atom()|binary()|list()},
            {sort, binary()} => atom()|binary()|list()
        },
        filters => [#{Field::binary() => #{Op::binary() => Val::binary()}}]
    }.

-spec search(map(), search_opts()) ->
    {ok, #search_results{}} | {error, term()}.


%% @doc 
search(Params, Opts) ->
    Fields = get_obj_fields(Opts),
    #{
        <<"from">> := From,
        <<"size">> := Size,
        <<"filter">> := Filters,
        <<"sort">> := Sort
    } = Params,
    Filters2 = maps:get(filters, Opts, []) ++ Filters,
    Spec1 = case add_filters(Filters2, Fields, []) of
        [] ->
            #{};
        FilterList ->
            #{filter_list => FilterList}
    end,
    Spec2 = case add_sort(Sort, Fields, []) of
        [] ->
            Spec1;
        SortList ->
            Spec1#{sort => SortList}
    end,
    lager:error("Spec2: ~p", [Spec2]),
    case read_objs(From, Size, Spec2) of
        {ok, Total, Data2} ->
            Result = #search_results{
                objects = Data2,
                total_count = Total,
                page_info = #page_info{
                    has_next_page = false,
                    has_previous_page = false
                }
            },
            {ok, Result};
        {error, Error} ->
            {error, Error}
    end.


%% @private
get_obj(null) ->
    {ok, null};

get_obj(<<>>) ->
    get_obj(<<"root">>);

get_obj(ObjId) ->
    case nkdomain_lib:read(ObjId) of
        {ok, #obj_id_ext{}=ObjIdExt, Obj} ->
            {ok, {ObjIdExt, Obj}};
        {error, Error} ->
            {error, Error}
    end.


%% @private
get_type(#{type:=Type}) ->
    Module = nkdomain_reg:get_type_module(Type),
    case Module:object_info() of
        #{schema_type:=SchemaType} ->
            {ok, nklib_util:to_binary(SchemaType)};
        _ ->
            lager:error("NKLOG Unknown type ~p", [Type]),
            {error, unknown_type}
    end;

get_type(Obj) ->
    lager:error("NKLOG Unknown type ~p", [Obj]),
    {error, unknown_type}.



%% ===================================================================
%% Internal
%% ===================================================================


%% @private
add_sort([], _Fields, Acc) ->
    lists:reverse(Acc);

add_sort([#{}=Set|Rest], Fields, Acc) ->
    add_sort(maps:to_list(Set)++Rest, Fields, Acc);

add_sort([{_Field, null}|Rest], Fields, Acc) ->
    add_sort(Rest, Fields, Acc);

add_sort([{Field, #{<<"order">>:={enum, Order}}}|Rest], Fields, Acc) ->
    Order2 = case Order of
        <<"ASC">> -> <<"asc">>;
        <<"DESC">> -> <<"desc">>
    end,
    {ok, ObjField} = get_sort_field(Field, Fields),
    Acc2 = [<<Order2/binary, $:, ObjField/binary>>|Acc],
    add_sort(Rest, Fields, Acc2).



%% @private
add_filters([], _Fields, Acc) ->
    Acc;

add_filters([Filter|Rest], Fields, Acc) ->
    {Op, Spec} = do_add_filter(maps:to_list(Filter), 'and', Fields, []),
    add_filters(Rest, Fields, [{Op, Spec}|Acc]).


%% @private
do_add_filter([], Op, _Fields, Acc) ->
    {Op, Acc};

do_add_filter([{_Field, null}|Rest], Op, Fields, Acc) ->
    do_add_filter(Rest, Op, Fields, Acc);

do_add_filter([{<<"op">>, {enum, Type}}|Rest], _Op, Fields, Acc) ->
    Op2 = case Type of
        <<"AND">> -> 'and';
        <<"OR">> -> 'or';
        <<"NOT">> -> 'not'
    end,
    do_add_filter(Rest, Op2, Fields, Acc);

do_add_filter([{Field, Filter}|Rest], Op, Fields, Acc) ->
    Acc2 = do_add_filter2(Field, maps:to_list(Filter), Fields, Acc),
    do_add_filter(Rest, Op, Fields, Acc2).


%% @private
do_add_filter2(_Field, [], _Fields, Acc) ->
    Acc;

do_add_filter2(Field, [{_Op, null}|Rest], Fields, Acc) ->
    do_add_filter2(Field, Rest, Fields, Acc);

do_add_filter2(<<"type">>, [{<<"eq">>, {enum, Type}}|Rest], Fields, Acc) ->
    Mod = nkdomain_reg:get_schema_type_module(Type),
    true = Mod /= undefined,
    Type2 = nkdomain_reg:get_module_type(Mod),
    Acc2 = [{type, eq, Type2}|Acc],
    do_add_filter2(<<"type">>, Rest, Fields, Acc2);

do_add_filter2(<<"type">>, [{<<"values">>, Values}|Rest], Fields, Acc) ->
    Types = lists:map(
        fun({enum, Type}) ->
            Mod = nkdomain_reg:get_schema_type_module(Type),
            true = Mod /= undefined,
            nkdomain_reg:get_module_type(Mod)
        end,
        Values),
    Acc2 = [{type, values, Types}|Acc],
    do_add_filter2(<<"type">>, Rest, Fields, Acc2);

do_add_filter2(<<"type">>, [Op|_Rest], _Fields, _Acc) ->
    lager:warning("Module ~p: invalid operartion for 'type': ~p", [?MODULE, Op]),
    error(invalid_type_operation);

do_add_filter2(<<"path">>, [{<<"childsOf">>, Value}|Rest], Fields, Acc) ->
    Acc2 =  [{path, subdir, Value}|Acc],
    do_add_filter2(<<"path">>, Rest, Fields, Acc2);

do_add_filter2(Field, [{Op, Val}|Rest], Fields, Acc) ->
    Acc2 = case get_filter_field(Field, Fields) of
        {ok, Field2} when is_binary(Field2) ->
            do_add_filter_std(Field2, Op, Val, Acc);
        {norm, Field2} ->
            add_filter_norm(Field2, Op, Val, Acc)
    end,
    do_add_filter2(Field, Rest, Fields, Acc2).


%% @private
do_add_filter_std(Field, Op, Value, Acc)
    when Op == <<"eq">>; Op == <<"values">>; Op == <<"gt">>; Op == <<"gte">>;
         Op == <<"lt">>; Op == <<"lte">>; Op == <<"prefix">>; Op == <<"exists">> ->
    [{Field, binary_to_existing_atom(Op, latin1), Value}|Acc].


%% @private
add_filter_norm(Field, Op, Value, Acc) when Op==<<"eq">>; Op==<<"prefix">> ->
    Value2 = nkdomain_store_es_util:normalize(Value),
    [{Field, binary_to_existing_atom(Op, latin1), Value2}|Acc];

add_filter_norm(Field, <<"wordsAndPrefix">>, Value, Acc) ->
    case nkdomain_store_es_util:normalize_multi(Value) of
        [] ->
            Acc;
        [Word] ->
            [{Field, prefix, Word}|Acc];
        Words ->
            [Last|Full] = lists:reverse(Words),
            [{Field, prefix, Last}, {Field, values, Full} | Acc]
    end;

add_filter_norm(Field, <<"fuzzy">>, Value, Acc) ->
    case nkdomain_store_es_util:normalize_multi(Value) of
        [] ->
            Acc;
        [Word] ->
            [{Field, fuzzy, Word}|Acc];
        Words ->
            [{Field, fuzzy, W} || W <-Words] ++ Acc
    end.

%% @private
read_objs(From, Size, Spec) ->
    do_read_objs(From, Size, Spec, []).


%% @private
do_read_objs(Start, Size, Spec, Acc) ->
    case nkdomain:search(Spec#{from=>Start, size=>Size, fields=>[]}) of
        {ok, Total, [], _Meta} ->
            {ok, Total, lists:reverse(Acc)};
        {ok, Total, Data, _Meta} ->
            Acc2 = lists:foldl(
                fun(#{<<"obj_id">>:=ObjId}, FunAcc) ->
                    case nkdomain_lib:read(ObjId) of
                        {ok, ObjIdExt, Obj} ->
                            [{ObjIdExt, Obj}|FunAcc];
                        {error, Error} ->
                            lager:warning("could not read object ~s: ~p", [ObjId, Error]),
                            FunAcc
                    end
                end,
                Acc,
                Data),
            case length(Acc2) of
                Size ->
                    {ok, Total, lists:reverse(Acc2)};
                Records when Records > Size ->
                    {ok, Total, lists:sublist(lists:reverse(Acc2), Size)};
                _ ->
                    do_read_objs(Start+Size, Size, Spec, Acc2)
            end;
        {error, Error} ->
            {error, Error}
    end.

%% @private
get_obj_fields(Opts) ->
    Base = #{
        <<"createdById">> => <<"created_by">>,
        <<"createdTime">> => <<"created_time">>,
        <<"description">> => {norm, <<"description_norm">>},
        <<"destroyedCode">> => <<"destroyed_code">>,
        <<"destroyedReason">> => <<"destroyed_reason">>,
        <<"destroyedTime">> => <<"destroyed_time">>,
        <<"domainId">> => <<"domain_id">>,
        <<"expiresTime">> => <<"expires_time">>,
        <<"iconId">> => <<"icon_id">>,
        <<"name">> => {norm, <<"name_norm">>},
        <<"objId">> => <<"obj_id">>,
        <<"objName">> => <<"obj_name">>,
        <<"srvId">> => <<"srv_id">>,
        <<"subTypes">> => <<"subtypes">>,
        <<"updatedById">> => <<"updated_by">>,
        <<"updatedTime">> => <<"updated_time">>
    },
    Fields = maps:get(fields, Opts, #{}),
    maps:merge(Base, Fields).


%% @private
get_filter_field(Field, Fields) ->
    case maps:find(Field, Fields) of
        {ok, ObjField} when is_binary(ObjField) ->
            {ok, ObjField};
        {ok, ObjField} when is_atom(ObjField) ->
            {ok, to_bin(ObjField)};
        {ok, List} when is_list(List) ->
            {ok, nklib_util:bjoin(List, <<".">>)};
        {ok, {norm, ObjField}} when is_binary(ObjField) ->
            {norm, ObjField};
        {ok, {norm, ObjField}} when is_atom(ObjField) ->
            {norm, to_bin(ObjField)};
        {ok, {norm, List}} when is_list(List) ->
            {norm, nklib_util:bjoin(List, <<".">>)};
        error ->
            {ok, to_bin(Field)}
    end.


%% @private
get_sort_field(Field, Fields) ->
    case maps:find({sort, Field}, Fields) of
        {ok, ObjField} when is_binary(ObjField) ->
            {ok, ObjField};
        {ok, ObjField} when is_atom(ObjField) ->
            {ok, to_bin(ObjField)};
        {ok, List} when is_list(List) ->
            {ok, nklib_util:bjoin(List, <<".">>)};
        error ->
            {_, ObjField} = get_filter_field(Field, Fields),
            {ok, ObjField}
    end.


%% @private
to_bin(T) when is_binary(T)-> T;
to_bin(T) -> nklib_util:to_binary(T).

