import ballerina/grpc;

listener grpc:Listener ep = new (9090);
int nextPropertyNum = 1;

@grpc:Descriptor {value: ACCOMMODATION_DESC}
service "AccommodationService" on ep {

    remote function searchProperty(SearchRequest value) returns SearchPropertyResponse|error {
    }

    remote function addProperty(AddPropertyRequest value) returns AddPropertyResponse|error {


         // mint a unique id: PROP-1, PROP-2, ... (brief: "system returns a unique property_id")
        string propId = "PROP-" + nextPropertyNum.toString();
        nextPropertyNum += 1;

        // build OUR internal record from the WIRE message (snake_case -> camelCase)
        InternalProperty prop = {
            propertyId: propId,
            name: value.name,
            location: value.location,
            propertyType: value.property_type,
            pricePerNight: value.price_per_night,
            status: value.status.toString(),
            hostId: "HOST-UNKNOWN"
        };

        // mutate shared state ONLY inside lock (concurrency requirement in the brief)
        lock {
            propertiesTable.add(prop);
        }

        // answer on the wire
        return {
            property_id: propId,
            message: "Property " + propId + " registered successfully"
        };

    }

    remote function updateProperty(UpdatePropertyRequest value) returns UpdatePropertyResponse|error {

        // shows error if property id comes up null
        InternalProperty? p = propertiesTable[value.property_id];
        if p is () {
            return error grpc:NotFoundError("no Poperty " + value.property_id);
        }

        // iwl i was so lost with this part i dead just had to ask ai to help cause
        // diff feilds come from diff files so to keep the function working i needed to have
        // my InternalProperty and normal Property diff plus use stuff from .proto and store.bal 🫩
        // but bassically this what i learnt new record needs data right and p has all of them but
        // uses the old the old fields , so the new fields are only property_id, name, status and price_per_night
        // so we get those from the value so if we have value use it if not use p in short
        // lock means only one thing can run this peice of code at a time
        lock {
            _ = propertiesTable.remove(value.property_id);
            propertiesTable.add({
                propertyId: value.property_id,
                name: value.name,
                status: value.status.toString(),
                pricePerNight: value.price_per_night,
                location: p.location,
                propertyType: p.propertyType,
                hostId: p.hostId
                });
        }

        return {
            message: "Property " + value.property_id + " updated succesfully"
        };


    }

    remote function removeProperty(RemovePropertyRequest value) returns PropertyList|error {
    }

    remote function bookProperty(BookRequest value) returns BookResponse|error {
    }

    remote function confirmBooking(ConfirmRequest value) returns BookingConfirmation|error {
    }

    remote function createUsers(stream<UserRequest, grpc:Error?> clientStream) returns CreateUsersResponse|error {
    }

    remote function listAvailableProperties(ListRequest value) returns stream<PropertyList, error?>|error {
    }
}

