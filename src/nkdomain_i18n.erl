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

-module(nkdomain_i18n).
-behavior(nklib_i18n).

-export([i18n/0, reload/0]).



i18n() -> #{
    en => #{
        logout => "Logout",
        domain_refresh => "REFRESH",
        domain_show_subdomains => "Show subdomains",
        domain_real_time => "REAL TIME",

        domain_tree_overview => "Overview",
        domain_tree_overview_dashboard => "Dashboard",
        domain_tree_overview_domains => "Domains & Groups",
        domain_tree_overview_domains_all => "All Domains & Groups",
        domain_tree_overview_alerts => "Alerts",

        domain_tree_resources => "Resources",
        domain_tree_resources_user => "Users",
        domain_tree_resources_config => "Configurations",
        domain_tree_resources_file => "Files",
        'domain_tree_resources_mail.provider' => "eMail Providers",
        'domain_tree_resources_file.store' => <<"File Stores">>,

        domain_tree_sessions => "Sessions",
        domain_tree_sessions_session => "Login",
        domain_tree_sessions_token => "Tokens",
        'domain_tree_sessions_admin.session' => "Admin",

        domain_tree_networks => "Networks",
        domain_tree_services => "Services",

        domain_column_pos => "#",
        domain_column_domain => "DOMAIN",
        domain_column_path => "PATH",
        domain_column_name => "NAME",
        domain_column_firstname => "FIRSTNAME",
        domain_column_lastname => "LASTNAME",
        domain_column_email => "EMAIL",
        domain_column_created_by => "CREATED BY",
        domain_column_created_time => "CREATED DATE"
    },
    es => #{
        logout => "Salir",
        domain_refresh => "REFRESCAR",
        domain_show_subdomains => "Mostrar subdominios",
        domain_real_time => "TIEMPO REAL",

        domain_tree_overview => "General",
        domain_tree_overview_dashboard => <<"Información"/utf8>>,
        domain_tree_overview_domains => "Dominios & Grupos",
        domain_tree_overview_domains_all => "Todos los Dominios & Grupos",
        domain_tree_overview_alerts => "Alertas",

        domain_tree_resources => "Recursos",
        domain_tree_resources_user => "Usuarios",
        domain_tree_resources_config => "Configuraciones",
        domain_tree_resources_file => "Ficheros",
        'domain_tree_resources_mail.provider' => "Proveedores eMail",
        'domain_tree_resources_file.store' => <<"Stores de Ficheros">>,

        domain_tree_sessions => "Sesiones",
        domain_tree_sessions_session => "Login",
        domain_tree_sessions_token => "Tokens",
        'domain_tree_sessions_admin.session' => "Admin",

        domain_tree_networks => "Redes",
        domain_tree_services => "Servicios",

        domain_column_pos => "#",
        domain_column_domain => "DOMINIO",
        domain_column_path => "RUTA",
        domain_column_firstname => "NOMBRE",
        domain_column_lastname => "APELLIDOS",
        domain_column_email => "EMAIL",
        domain_column_created_by => "CREADO POR",
        domain_column_created_time => <<"FECHA CREACIÓN"/utf8>>
    }
}.


reload() ->
    ok = nklib_i18n:load(?MODULE).