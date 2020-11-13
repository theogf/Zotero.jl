const ZOTERO = "https://api.zotero.org/"

struct ZoteroClient
    token::Ref{String}
end

function HTTP.request(client::ZoteroClient, verb::String, url::String, headers::Dict=Dict(), body::String=""; kwargs...)
    merge!(headers, Dict(
                    "Zotero-API-Version" => 3,
                    "Zotero-API-Key" => token(client), 
                    )
                )
    response = HTTP.request(verb, url, headers, body; kwargs...)
    return response.body
end