import ballerina/io;
//only file user sees, it reads keyboard input,
//calls api-client.bal to talk to the server, and calls views.bal to print the results


//prints a prompt then blocks the line till the user types a somehting and presses enter.
//returns what they typed
public function main() {
    io:println(repeatChar("=", 60));
    io:println(" Ministry Library & Resource Management - REST Client");
    io:println(" Connected to: " + serviceUrl);
    io:println(repeatChar("=", 60));

    boolean running = true;
    while running {
        printMainMenu();
        string choice = io:readln("Select an option: ").trim();
        if choice == "1" {
            globalViewMenu();
        } else if choice == "2" {
            campusViewMenu();
        } else if choice == "3" {
            loanBookMenu();
        } else if choice == "4" {
            overdueDashboardMenu();
        } else if choice == "5" {
            scheduleManagerMenu();
        } else if choice == "0" {
            running = false;
            io:println("Goodbye.");
        } else {
            io:println("Invalid option. Try again.");
        }
    }
}

function printMainMenu() {
    io:println("");
    io:println("MAIN MENU");
    io:println("1) Global View                -list every asset across the ministry");
    io:println("2) Campus View                -filter by institution / site");
    io:println("3) Loan / Book / Return an asset");
    io:println("4) Overdue Dashboard - assets past their due date");
    io:println("5) Schedule Manager  - add, update, or remove schedules");
    io:println("0) Exit");
}

// fetchAllAssets() returns either a list of assets or an error. The result
// is checked before using it so that errors are handled first. Once the error
// case is returned, Ballerina knows that result is an Asset[], allowing the
// program to safely use the asset list and display it without needing any
// type casting.
function globalViewMenu() {
    io:println("");
    io:println("-- Global View: All Assets --");
    Asset[] | error result = fetchAllAssets();
    if result is error {
        printApiError(result);
        return;
    }
    printAssetTable(result);
    io:println("Total: " + result.length().toString() + " assets(s)");
}

//Fetches and displays all overdue assets. If the API returns an
// error, it is handled and the function stops. If there are no overdue assets,
// a message is shown instead. Otherwise, each overdue asset is displayed with
// its overdue schedules listed underneath, followed by the total number of
// overdue assets.
function overdueDashboardMenu() {
    io:println("");
    io:println("-- Overdue Dashboard --");
    Asset[] | error result = fetchOverdueAssets();
    if result is error {
        printApiError(result);
        return;
    }
    if result.length() == 0 {
        io:println("Nothing overdue.");
        return;
    }
    foreach Asset a in result {
        printAssetSummary(a);
        foreach Schedule s in a.schedules {
            io:println("  [" + s.'type +"]  due " + s.dueDate + " - " + s.description);
        }
    }
    io:println("Total overdue:  " + result.length().toString());
}
// Prompts the user for optional institution and site filters. Blank
// inputs are treated as no filter rather than empty strings. The filters are
// converted to optional values before fetching the matching assets. The API
// result is then checked for errors before displaying the filtered assets and
// their total count.
function campusViewMenu() {
    io:println("");
    io:println("-- Campus View --");
    string institution = io:readln("Institution (blank for any): ").trim();
    string site = io:readln("Site/Campus (blank for any): ").trim();
    string? inst = institution == "" ? () : institution;
    string? st = site == "" ? () : site;

    Asset[]|error result = fetchAssetsFiltered(inst, st);
    if result is error{
        printApiError(result);
        return;
    }
    printAssetTable(result);
    io:println("Total: " + result.length().toString()  + " asset(s)");
}


//Provides a sub-menu for borrowing or returning an asset. For a
// loan, it collects the required borrower details, builds a LoanRequest, and
// sends it to the API. For a return, it sends the selected asset tag to the
// API. The result is checked for errors, and successful operations display
// the result. Invalid options simply return without making an API call.

    function loanBookMenu() {
    io:println("");
    io:println("-- Loan / Book / Return --");
    io:println("1) Loan or book an asset");
    io:println("2) Return an asset");
    io:println("0) Back");
    string choice = io:readln("Select an option: ").trim();

    if choice == "1" {
        string assetTag = io:readln("Asset tag: ").trim();
        string borrower = io:readln("Borrower / requester name: ").trim();
        string purpose = io:readln("Purpose (e.g. loan, meeting, lab session): ").trim();
        string due = io:readln("Due date (YYYY-MM-DD): ").trim();
        LoanRequest req = {borrowerName: borrower, purpose: purpose, dueDate: due};
        Asset|error result = loanAsset(assetTag, req);
        if result is error {
            printApiError(result);
            return;
        }
        io:println("Loaned/booked successfully:");
        printAssetDetail(result);
    } else if choice == "2" {
        string assetTag = io:readln("Asset tag to return: ").trim();
        Asset|error result = returnAsset(assetTag);
        if result is error {
            printApiError(result);
            return;
        }
        io:println("Returned successfully:");
        printAssetDetail(result);
    } else if choice != "0" {
        io:println("Invalid option.");
    }
}
}

//Provides a sub-menu for adding, updating, or removing an asset
// schedule. Each action collects the information it needs, builds the
// appropriate request when necessary, and sends it to the API. The shared
// handleAssetResult() helper is used to process the results consistently
// instead of repeating the same error-handling logic in each branch.
function scheduleManagerMenu() {
    io:println("");
    io:println("-- Schedule Manager --");
    io:println("1) Add a schedule");
    io:println("2) Update a schedule");
    io:println("3) Remove a schedule");
    io:println("0) Back");
    string choice = io:readln("Select an option: ").trim();
    if choice == "0" {
        return;
    }

    string assetTag = io:readln("Asset tag: ").trim();

    if choice == "1" {
        string t = io:readln("Type (MAINTENANCE/BOOKING/etc): ").trim();
        string due = io:readln("Due date (YYYY-MM-DD): ").trim();
        string desc = io:readln("Description: ").trim();
        ScheduleRequest req = {'type: t, dueDate: due, description: desc};
        handleAssetResult(addSchedule(assetTag, req));
    } else if choice == "2" {
        string scheduleId = io:readln("Schedule ID: ").trim();
        string t = io:readln("New type: ").trim();
        string due = io:readln("New due date (YYYY-MM-DD): ").trim();
        string desc = io:readln("New description: ").trim();
        ScheduleRequest req = {'type: t, dueDate: due, description: desc};
        handleAssetResult(updateSchedule(assetTag, scheduleId, req));
    } else if choice == "3" {
        string scheduleId = io:readln("Schedule ID: ").trim();
        handleAssetResult(removeSchedule(assetTag, scheduleId));
    } else {
        io:println("Invalid option.");
    }
}

function handleAssetResult(Asset|error result) {
    if result is error {
        printApiError(result);
        return;
    }
    io:println("Success. Updated asset:");
    printAssetDetail(result);
}