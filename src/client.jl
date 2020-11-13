const ZOTERO = "https://api.zotero.org/"

struct ZoteroClient
    APIKey::String
    user_group_prefix::String
    user_groupID::String
end

function ZoteroClient(APIKey::String, userID::String, user::Bool=true)
    new(APIKey, userID, user ? "users" : "groups")
end

function ZoteroClient(path_to_ids::String=pwd())
    # TODO gives an information message for errors
    path_to_ids = isdir(path_to_ids) ? joinpath(path_to_ids, ".token") : path_to_ids
    return ZoteroClient(readlines(path_to_ids)...)
end

function base_url(client::ZoteroClient)
    return joinpath(ZOTERO, client.user_group_prefix, client.user_groupID)
end

function HTTP.request(client::ZoteroClient, verb::String, url::String, headers::Dict=Dict(), body::String=""; kwargs...)
    merge!(headers, Dict(
                    "Zotero-API-Version" => 3,
                    "Zotero-API-Key" => APIKey, 
                    )
                )
    response = HTTP.request(verb, joinpath(base_url(client), url), headers, body; kwargs...)
    return response.body
end

function request_json(client::ZoteroClient, verb::String, url::String, headers::Dict=Dict(), body::String=""; kwargs...)
    headers = merge(headers, Dict("Content-Type" => "application/json"))
    body = HTTP.request(client, verb, url, headers, body; kwargs...)
end