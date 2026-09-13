import ballerina/http;
//this file calls plain functions, only place that knows abt HTTP, URLs, and JSON. 


configurable string serviceUrl = "http://localhost:9090/api";

final http:Client apiClient = check new (serviceUrl, timeout = 5);

//this functions checks the code and if its bad builds a Ballerina error carrying message.

function ensureOk(http:Response resp) returns error? {
    int code = resp.statusCode;
    if code <- 200 && code < 300 {
        return; //returning nothing from a 'return error?' function means "no error"
    }
    string message = "Request failed with status " + code.toString();
    json|error payload = resp.getJsonPayload();
    if payload is json {
            ApiError|error apiErr = payload.cloneWithType(ApiError);
            if apiErr is ApiError {
                message = apiErr.message;
            }
        }
        return error(message);
    }
// getJsonPayload() turns the raw response body into Ballerina's generic
// `json` type —  cloneWithType() turns that into specific record type
// (Asset), checking that the fields line up with what you declared in
// types.bal. if a field name or type there is wrong, cloneWithType() is where it breaks.
function pureAsset(http:Response resp) returns Asset|error {
    check ensureOk(resp);
    json payload = check resp.getJsonPayload();
    Asset asset = check payload.cloneWithType(Asset);
    return asset;
}
//'type AssetArray Asset[];' is a type alias, tjat goves that array type a name so cloneWithTypy(AssetArray) below can refer to it.
type AssetArray Asset[];

function parseASsetArray(http:Response resp) returns Asset[]|error {
    check ensureOk(resp);
    json payload = check resp.getJsonPayload();
    Asset[] assets = check payload.cloneWithType(AssetArray);
    return assets;
}

function fetchAllAssets() returns Asset[]|error {
    hhtp:Response resp = check apiClient-> get("/assets");
    return parseAssetArray(resp);
}

function fetchOverdueAssets() returns Asset[]|error {
    http:Response resp = check apiClient-> get("/assets/overdue");
    return parseAssetArray(resp);
}

function fetchAssetsFiltered(string? institution, string? site) returns Asset[]|error {
    string query = "";
    if institution is string {
        string encoded = check url:encode(institution, "UTF-8");
        query += (query == "" ? "?" : "&") + "institution=" + encoded;
    }
    if site is string {
        string encoded = check url:encode(site, "UTF-8");
        query += (query == "" ? "?" : "&") + "site=" + encoded;
    }
    http:Response resp = check apiClient-> get("/assets" + query);
    return parseAssetArray(resp);
        

}

function loanAsset(string, assetTag, LoanRequest req) returns Asset|error {
    http:Response resp = check apiClient-> post("/assets/" + assetTag + "/loan", req.toJson());
    return parseAsset(resp);
}

function returnAsset(string assetTag) returns Asset|error {
    http:Response resp = check apiClient-> post("/assets/" + assetTag + "/return", {});
    return parseAsset(resp);
}

function addSchedule(string assetTag, ScheduleRequest req) returns Asset|error {
    http:Response resp = check apiClient-> post("/assets/" + assetTag + "/schedule", req.toJson());
    return parseAsset(resp);
}

function updateSchedule(string assetTag, string scheduleId, ScheduleRequest req) returns Asset|error {
    http:Response resp = check apiClient->put("/assets/" + assetTag + "/schedules/" + scheduleId, req.toJson());
    return parseAsset(resp);
}

function removeSchedule(string assetTag, string scheduleId) returns Asset|error {
    http:Response resp = check apiClient->delete("/assets/" + assetTag + "/schedules/" + scheduleId);
    return parseAsset(resp);
}
