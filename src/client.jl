const ZOTERO = "https://api.zotero.org/"

struct ZoteroClient
    APIKey::String
    user_groupID::String
    user_group_prefix::String
end

function ZoteroClient(APIKey::String, userID::String, user::Bool=true)
    new(APIKey, userID, user ? "users" : "groups")
end

function ZoteroClient(path_to_ids::String=pwd())
    # TODO gives an information message for errors
    haskey(ENV, "ZOTERO_API") && haskey(ENV, "ZOTERO_USER") || error("API token
    and User ID are missing from the `ENV` variable. You need to load them from a
    `.env` file (using `DotEnv` for example) or set them manually.")
    return ZoteroClient(ENV["ZOTERO_TOKEN"], ENV["ZOTERO_USER"], get(ENV, "IS_ZOTERO_USER", true))
end

function base_url(client::ZoteroClient)
    return joinpath(ZOTERO, client.user_group_prefix, client.user_groupID)
end

function HTTP.request(client::ZoteroClient, verb::String, url::String, headers::Dict=Dict(), body::String=""; kwargs...)
    merge!(headers, Dict(
                    "Zotero-API-Version" => 3,
                    "Zotero-API-Key" => client.APIKey, 
                    )
                )
    response = HTTP.request(verb, joinpath(base_url(client), url), headers, body; kwargs...)
    return response.body
end

function request_json(client::ZoteroClient, verb::String, url::String, headers::Dict=Dict(), body::String=""; kwargs...)
    headers = merge(headers, Dict("Content-Type" => "application/json"))
    body = HTTP.request(client, verb, url, headers, body; kwargs...)
    return JSON.parse(String(body))
end