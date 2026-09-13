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
    io:print("-- Global View: All Assets --");
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
    io:prntln("");
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
    io.println("Total overdue:  " + result.length().toString());
}

