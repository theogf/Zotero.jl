const ZOTERO = "https://api.zotero.org/"

struct ZoteroClient
    token::String
    id::String
    prefix::String
    function ZoteroClient(token::String, id::String, is_user::Bool=true)
        new(token, id, is_user ? "users" : "groups")
    end
end



function ZoteroClient(;path::Union{Nothing,String}=nothing)
    isnothing(path) || DotEnv.config(;path)
    haskey(ENV, "ZOTERO_API_TOKEN") && haskey(ENV, "ZOTERO_USER_ID") || error("API token : \"ZOTERO_API_TOKEN\"
    and User ID : \"ZOTERO_USER_ID\" are missing from the `ENV` variable. You need to load them from a
    `.env` file (using `DotEnv` for example), set them manually or set the `path` keyword to the path of `.env` file containg them.")
    return ZoteroClient(ENV["ZOTERO_API_TOKEN"], ENV["ZOTERO_USER_ID"], get(ENV, "IS_ZOTERO_USER", "true") == "true")
end

function base_url(client::ZoteroClient)
    return joinpath(ZOTERO, client.prefix, client.id)
end

function HTTP.request(client::ZoteroClient, verb::String, url::String, headers::Dict=Dict(), body::String=""; kwargs...)
    merge!(headers, Dict(
                    "Zotero-API-Version" => 3,
                    "Zotero-API-Key" => client.token, 
                    )
                )
    response = HTTP.request(verb, joinpath(base_url(client), url), headers, body; kwargs...)
    return response.body
end

function request_json(client::ZoteroClient, verb::String, url::String, headers::Dict=Dict(), body::String=""; kwargs...)
    headers = merge(headers, Dict("Content-Type" => "application/json"))
    body = HTTP.request(client, verb, url, headers, body; kwargs...)
    return JSON3.read(String(body))
end