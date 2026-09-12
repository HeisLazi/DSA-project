import ballerina/http;
import ballerina/url;

configurable string serviceUrl = "http://localhost:9090/api";

final http:Client apiClient = check new (serviceUrl, timeout = 5);

function fetchAllAssets() returns Asset[]|error {
    http:Response resp = check apiClient->get("/assets");
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
    http:Response resp = check apiClient->get("/assets" + query);
    return parseAssetArray(resp);
}

function fetchOverdueAssets() returns Asset[]|error {
    http:Response resp = check apiClient->get("/assets/overdue");
    return parseAssetArray(resp);
}

function loanAsset(string assetTag, LoanRequest req) returns Asset|error {
    http:Response resp = check apiClient->post("/assets/" + assetTag + "/loan", req.toJson());
    return parseAsset(resp);
}

function returnAsset(string assetTag) returns Asset|error {
    http:Response resp = check apiClient->post("/assets/" + assetTag + "/return", {});
    return parseAsset(resp);
}

function addSchedule(string assetTag, ScheduleRequest req) returns Asset|error {
    http:Response resp = check apiClient->post("/assets/" + assetTag + "/schedules", req.toJson());
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

function parseAsset(http:Response resp) returns Asset|error {
    check ensureOk(resp);
    json payload = check resp.getJsonPayload();
    Asset asset = check payload.cloneWithType(Asset);
    return asset;
}

function parseAssetArray(http:Response resp) returns Asset[]|error {
    check ensureOk(resp);
    json payload = check resp.getJsonPayload();
    Asset[] assets = check payload.cloneWithType(AssetArray);
    return assets;
}

type AssetArray Asset[];

function ensureOk(http:Response resp) returns error? {
    int code = resp.statusCode;
    if code >= 200 && code < 300 {
        return;
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
