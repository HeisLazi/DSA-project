
import ballerina/io;
import ballerina/grpc;

// generated client connects as soon as its made
AccommodationServiceClient clientEp = check new ("http://localhost:9090");

public function main() returns error? {

    // -> is a remote call cause we sending bytes over the network.
    // addProperty alr gives us the id we need for the other rpcs
        AddPropertyResponse added = check clientEp->addProperty(
        {
            name: "Shandumballa Mansion",
            location: "Shandumballa",
            property_type: "Mansion",
            price_per_night: 10000.0,
            status: AVAILABLE
        }
    );
        io:println(added.message);

        SearchPropertyResponse found = check clientEp->searchProperty({
            property_id: added.property_id
        });
        io:println("Search status: " + found.status);

        // server streaming is a lil weird cause the stream gives us PropertyList and not Property directly
        // but its ok cause its a filtered list anyways (the repeated field in the wrapper)
        stream<PropertyList, grpc:Error?> available = check clientEp->listAvailableProperties({
            location: "Shandumballa",
            max_price: 10000.0
        });
        record {| PropertyList value; |}|grpc:Error? availableBatch = available.next();
        if availableBatch is record {| PropertyList value; |} {
            // PropertyList is the wrapper and the actual properties are inside its repeated field
            io:println("Available properties: " + availableBatch.value.properties.length().toString());
        }

        // bookProperty doesnt confirm it straight away puts the request in the cart first
        BookResponse booked = check clientEp->bookProperty({
            property_id: added.property_id,
            guest_id: "GUEST-1",
            check_in: "2026-10-01",
            check_out: "2026-10-05"
        });
        io:println(booked.message);

        //cart_id is from bookProperty we just reusing it again here fr
        BookingConfirmation confirmed = check clientEp->confirmBooking({
            cart_id: booked.cart_id
        });
        io:println(confirmed.message);
        io:println("Total cost: " + confirmed.total_cost.toString());

        // updateProperty uses the property_id from addProperty and changes the Shandumballa Mansion price
        UpdatePropertyResponse updated = check clientEp->updateProperty({
            property_id: added.property_id,
            name: "Shandumballa Mansion",
            price_per_night: 8000.0,
            status: AVAILABLE
        });
        io:println(updated.message);

        // createUsers is different from the other rpcs cause we open the stream and send users one by one
        CreateUsersStreamingClient users = check clientEp->createUsers();
        check users->sendUserRequest({
            user_id: "GUEST-1",
            name: "Mr. GetRich",
            role: "GUEST"
        });

        // ts been frying me bruh 😭
        check users->sendUserRequest({
            user_id: "HOST-1",
            name: "Mr. GetRicher",
            role: "HOST"
        });

        // complete tells the server there are no more users so it can send the final response back
        check users->complete();
        CreateUsersResponse|grpc:Error? usersCreated = users->receiveCreateUsersResponse();
        if usersCreated is CreateUsersResponse {
            io:println(usersCreated.message);
        }

        // removeProperty comes last cause after this the mansion is gone from the server table
        PropertyList remaining = check clientEp->removeProperty({
            property_id: added.property_id
        });
        io:println("Properties remaining in that location: " + remaining.properties.length().toString());
}

