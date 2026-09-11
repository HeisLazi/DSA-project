import ballerina/grpc;

listener grpc:Listener ep = new (9090);

@grpc:Descriptor {value: ACCOMMODATION_DESC}
service "AccommodationService" on ep {

    remote function searchProperty(SearchRequest value) returns SearchPropertyResponse|error {
    }

    remote function addProperty(AddPropertyRequest value) returns AddPropertyResponse|error {
    }

    remote function updateProperty(UpdatePropertyRequest value) returns UpdatePropertyResponse|error {
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

