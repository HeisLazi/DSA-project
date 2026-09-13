import ballerina/io;

//api_client.bal turns menu actions into HTTP calls and hands back typed Ballerina values (Asser, Asset[], error)
//This file turns those values into readable terminal output. Nothing in here touches the network

//plain string building loops, nothing REST/Ballerina specific.

function padRight(string s, int width) returns string {
    string result = s;
    while result.length() < width {
        result = result + " ";
    }
    if result.length() > width {
        result = result.substring(0, width);
    }
    return result;
}

function repeatChar(string ch, int n) returns string {
    string result ="";
    int i = 0;
    while i < n {
        result = result + ch;
        i += 1;

    }
    return result;
}

//where error messages get shown to the user
function printApiError(error e) {
    io:println("Error:" + e.message());
}

function printAssetSummary(Asset a) {
    io:println(a.assetTag + " | " + a.name + " | " + a.institution + " | " + a.site + " | "  + a.status);
}

// Global view and campus view both print a table of whatever Asset[] they get back
//if asset length is 0 "print no assets found"
//otherwise print one header line , print a divider, print one padded row per asset

function printAssetTable(Asset[] assets) {
    if assets.length() == 0 {
        io:println(" (no assets found)");
        return;
    }
    io:println(padRight("ASSET TAG", 18) + padRight("NAME", 30) + padRight("INSTITUTION", 24)
    + padRight("SITE", 26)+ padRight("STATUS", 16));
     io:println(repeatChar("-", 114));
    foreach Asset a in assets{
    io:println(padRight(a.assetTag, 18) + padRight(a.name, 30) + padRight(a.institution, 24) 
    + padRight(a.site, 26) + padRight(a.status, 16));
    }

}
//Displays detailed information about an asset, including its basic
// details, schedules, and work orders. The schedules and work orders sections
// are only shown when the asset contains entries for them. This provides a
// complete detail view of the asset after a successful loan, return, or
// schedule change.
function printAssetDetail(Asset a) {
    io:println("Asset Tag: " + a.assetTag);
    io:println("Name: " + a.name);
    io:println("Description: " + a.description);
    io:println("Institution: " + a.institution);
    io:println("Site: "         + a.site);
    io:println("Status: " + a.status);
    io:println("Date Acquired: " + a.dateAcquired);

    if a.schedules.length() > 0 {
        io:println("Schedules:");
        foreach Schedule s in a.schedules {
               io:println("  [" + s.scheduleId + "] " + s.'type + " due " + s.dueDate + " - " + s.description);
        }
    }
    if a.workOrders.length() > 0 {
        io:println("Work Orders:");
        foreach WorkOrder w in a.workOrders {
            io:println("  [" + w.orderId + "] " + w.status + " - " + w.description);
        }
    }
}
