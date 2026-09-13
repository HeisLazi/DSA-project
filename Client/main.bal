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