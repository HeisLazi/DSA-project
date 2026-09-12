import ballerina/grpc;

listener grpc:Listener ep = new (9090);
// declared the unique id we use later on in InternalProperty
int nextPropertyNum = 1;

// idk but i was told we neeed this  cause it attaches .proto schema
@grpc:Descriptor {value: ACCOMMODATION_DESC}

// we bind AccommodationService name to the ep so rpcs are reachanble on port 9090
// under this service name
service "AccommodationService" on ep {

    remote function searchProperty(SearchRequest value) returns SearchPropertyResponse|error {
        InternalProperty? p = propertiesTable[value.property_id];
        if p is () {
            return {status: "NOT AVAILABLE"};
        } else {
            return {
                // dont set status cause default is alr available and if changed to booked or smth
                // the property wont be hardcoded and will just follow what is set by the host in the updateProperty rpc
                status: p.status,
                // pb.bal has property as a nested field so all the other stuff come inside it
                property: {
                    property_id: p.propertyId,
                    name: p.name,
                    location: p.location,
                    property_type: p.propertyType,
                    price_per_night: p.pricePerNight,
                    // from enum back to string opposite of doing .toString() in store.bal
                    status: <PropertyStatus>p.status
                }
            };
        }
    }


    remote function addProperty(AddPropertyRequest value) returns AddPropertyResponse|error {

         // made a unique id cause doc says "system returns a unique property_id"
        string propId = "PROP-" + nextPropertyNum.toString();
        nextPropertyNum += 1;

        // used the wire message (wire message is the stuff from the generated pb.bal file )
        // to build our internal record this doesnt leave the server btw
        // thats why its InternalProperty and not Property
        InternalProperty prop = {
            propertyId: propId,
            name: value.name,
            location: value.location,
            propertyType: value.property_type,
            pricePerNight: value.price_per_night,
            status: value.status.toString(),
            hostId: "HOST-UNKNOWN"
        };

        // lock means only one thing can run this peice of code at a time
        lock {
            propertiesTable.add(prop);
        }

        // we now gotta convert it back to wire cause this is what actually get sent to the client
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
        // diff feilds come from diff files so to keep the function working so like i needed to have
        // stuff from .proto and store.bal 🫩
        // but bassically this what i learnt new record need data right, and p has all of them but
        // p uses the old data we want to update, so to update it we take the new fields
        // those new fields being property_id, name, status and price_per_night
        // so we get those from the value keyword so if we have (value.whatever) if not we use p
        lock {
            _ = propertiesTable.remove(value.property_id);
            propertiesTable.add({
                propertyId: value.property_id,
                name: value.name,
                // updating enum to string cause store.bal uses string for status
                status: value.status.toString(),
                pricePerNight: value.price_per_night,
                location: p.location,
                propertyType: p.propertyType,
                hostId: p.hostId
                });
        }

        // in the generated pb.bal UpdatePropertyResponse only has message cause this a server response
        // so its alr unique to the client who made it
        return {
            message: "Property " + value.property_id + " updated succesfully"
        };


    }

    remote function removeProperty(RemovePropertyRequest value) returns PropertyList|error {

        // reused from above to throw error if property id comes up null
        InternalProperty? p = propertiesTable[value.property_id];
        if p is () {
            return error grpc:NotFoundError("no Poperty " + value.property_id);
        }

            // this lock just to remove properties
            lock {
                _ = propertiesTable.remove(value.property_id);
            }

            // this lock is to actually loop the removal and then respond with the
            // new full list of properties in that region hence location is the comparison
            // fought with ts for the whole day bruh "im tired grandpa 🫩"
            // knowing which id to use and what variable casing is killing me
            // but left is the wire message and right (pb.bal)  is the internal record so that how case works
            lock {
                Property[] properties = [];

                foreach InternalProperty i in propertiesTable{
                    if i.location ==  p.location {
                        Property pub = {
                            property_id: i.propertyId,
                            name: i.name,
                            location: i.location,
                            property_type: i.propertyType,
                            price_per_night: i.pricePerNight,
                            status: <PropertyStatus>i.status
                        };
                        properties.push(pub);
                    }
                }
                return {
                    properties: properties
                };
            }
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

