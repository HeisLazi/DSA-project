import ballerina/grpc;
import ballerina/protobuf;

public const string ACCOMMODATION_DESC = "0A136163636F6D6D6F646174696F6E2E70726F746F120D6163636F6D6D6F646174696F6E22C8010A1241646450726F70657274795265717565737412120A046E616D6518012001280952046E616D65121A0A086C6F636174696F6E18022001280952086C6F636174696F6E12230A0D70726F70657274795F74797065180320012809520C70726F70657274795479706512260A0F70726963655F7065725F6E69676874180420012801520D70726963655065724E6967687412350A0673746174757318052001280E321D2E6163636F6D6D6F646174696F6E2E50726F7065727479537461747573520673746174757322500A1341646450726F7065727479526573706F6E7365121F0A0B70726F70657274795F6964180120012809520A70726F7065727479496412180A076D65737361676518022001280952076D657373616765224E0A0B557365725265717565737412170A07757365725F6964180120012809520675736572496412120A046E616D6518022001280952046E616D6512120A04726F6C651803200128095204726F6C6522450A134372656174655573657273526573706F6E736512140A05636F756E741801200128055205636F756E7412180A076D65737361676518022001280952076D65737361676522AB010A1555706461746550726F706572747952657175657374121F0A0B70726F70657274795F6964180120012809520A70726F7065727479496412120A046E616D6518022001280952046E616D6512260A0F70726963655F7065725F6E69676874180320012801520D70726963655065724E6967687412350A0673746174757318042001280E321D2E6163636F6D6D6F646174696F6E2E50726F7065727479537461747573520673746174757322320A1655706461746550726F7065727479526573706F6E736512180A076D65737361676518012001280952076D65737361676522380A1552656D6F766550726F706572747952657175657374121F0A0B70726F70657274795F6964180120012809520A70726F7065727479496422DF010A0850726F7065727479121F0A0B70726F70657274795F6964180120012809520A70726F7065727479496412120A046E616D6518022001280952046E616D65121A0A086C6F636174696F6E18032001280952086C6F636174696F6E12230A0D70726F70657274795F74797065180420012809520C70726F70657274795479706512260A0F70726963655F7065725F6E69676874180520012801520D70726963655065724E6967687412350A0673746174757318062001280E321D2E6163636F6D6D6F646174696F6E2E50726F7065727479537461747573520673746174757322650A1653656172636850726F7065727479526573706F6E736512160A06737461747573180120012809520673746174757312330A0870726F706572747918022001280B32172E6163636F6D6D6F646174696F6E2E50726F7065727479520870726F706572747922470A0C50726F70657274794C69737412370A0A70726F7065727469657318012003280B32172E6163636F6D6D6F646174696F6E2E50726F7065727479520A70726F7065727469657322460A0B4C69737452657175657374121A0A086C6F636174696F6E18012001280952086C6F636174696F6E121B0A096D61785F707269636518022001280152086D6178507269636522300A0D53656172636852657175657374121F0A0B70726F70657274795F6964180120012809520A70726F706572747949642281010A0B426F6F6B52657175657374121F0A0B70726F70657274795F6964180120012809520A70726F7065727479496412190A0867756573745F696418022001280952076775657374496412190A08636865636B5F696E1803200128095207636865636B496E121B0A09636865636B5F6F75741804200128095208636865636B4F757422410A0C426F6F6B526573706F6E736512170A07636172745F6964180120012809520663617274496412180A076D65737361676518022001280952076D65737361676522290A0E436F6E6669726D5265717565737412170A07636172745F6964180120012809520663617274496422A6010A13426F6F6B696E67436F6E6669726D6174696F6E121D0A0A626F6F6B696E675F69641801200128095209626F6F6B696E674964121F0A0B70726F70657274795F6964180220012809520A70726F7065727479496412160A066E696768747318032001280552066E6967687473121D0A0A746F74616C5F636F73741804200128015209746F74616C436F737412180A076D65737361676518052001280952076D6573736167652A390A0E50726F7065727479537461747573120D0A09415641494C41424C451000120A0A06424F4F4B45441001120C0A08494E414354495645100232BC050A144163636F6D6D6F646174696F6E53657276696365124F0A0B6372656174655573657273121A2E6163636F6D6D6F646174696F6E2E55736572526571756573741A222E6163636F6D6D6F646174696F6E2E4372656174655573657273526573706F6E7365280112540A176C697374417661696C61626C6550726F70657274696573121A2E6163636F6D6D6F646174696F6E2E4C697374526571756573741A1B2E6163636F6D6D6F646174696F6E2E50726F70657274794C697374300112550A0E73656172636850726F7065727479121C2E6163636F6D6D6F646174696F6E2E536561726368526571756573741A252E6163636F6D6D6F646174696F6E2E53656172636850726F7065727479526573706F6E736512540A0B61646450726F706572747912212E6163636F6D6D6F646174696F6E2E41646450726F7065727479526571756573741A222E6163636F6D6D6F646174696F6E2E41646450726F7065727479526573706F6E7365125D0A0E75706461746550726F706572747912242E6163636F6D6D6F646174696F6E2E55706461746550726F7065727479526571756573741A252E6163636F6D6D6F646174696F6E2E55706461746550726F7065727479526573706F6E736512530A0E72656D6F766550726F706572747912242E6163636F6D6D6F646174696F6E2E52656D6F766550726F7065727479526571756573741A1B2E6163636F6D6D6F646174696F6E2E50726F70657274794C69737412470A0C626F6F6B50726F7065727479121A2E6163636F6D6D6F646174696F6E2E426F6F6B526571756573741A1B2E6163636F6D6D6F646174696F6E2E426F6F6B526573706F6E736512530A0E636F6E6669726D426F6F6B696E67121D2E6163636F6D6D6F646174696F6E2E436F6E6669726D526571756573741A222E6163636F6D6D6F646174696F6E2E426F6F6B696E67436F6E6669726D6174696F6E620670726F746F33";

public isolated client class AccommodationServiceClient {
    *grpc:AbstractClientEndpoint;

    private final grpc:Client grpcClient;

    public isolated function init(string url, *grpc:ClientConfiguration config) returns grpc:Error? {
        self.grpcClient = check new (url, config);
        check self.grpcClient.initStub(self, ACCOMMODATION_DESC);
    }

    isolated remote function searchProperty(SearchRequest|ContextSearchRequest req) returns SearchPropertyResponse|grpc:Error {
        map<string|string[]> headers = {};
        SearchRequest message;
        if req is ContextSearchRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("accommodation.AccommodationService/searchProperty", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <SearchPropertyResponse>result;
    }

    isolated remote function searchPropertyContext(SearchRequest|ContextSearchRequest req) returns ContextSearchPropertyResponse|grpc:Error {
        map<string|string[]> headers = {};
        SearchRequest message;
        if req is ContextSearchRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("accommodation.AccommodationService/searchProperty", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <SearchPropertyResponse>result, headers: respHeaders};
    }

    isolated remote function addProperty(AddPropertyRequest|ContextAddPropertyRequest req) returns AddPropertyResponse|grpc:Error {
        map<string|string[]> headers = {};
        AddPropertyRequest message;
        if req is ContextAddPropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("accommodation.AccommodationService/addProperty", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <AddPropertyResponse>result;
    }

    isolated remote function addPropertyContext(AddPropertyRequest|ContextAddPropertyRequest req) returns ContextAddPropertyResponse|grpc:Error {
        map<string|string[]> headers = {};
        AddPropertyRequest message;
        if req is ContextAddPropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("accommodation.AccommodationService/addProperty", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <AddPropertyResponse>result, headers: respHeaders};
    }

    isolated remote function updateProperty(UpdatePropertyRequest|ContextUpdatePropertyRequest req) returns UpdatePropertyResponse|grpc:Error {
        map<string|string[]> headers = {};
        UpdatePropertyRequest message;
        if req is ContextUpdatePropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("accommodation.AccommodationService/updateProperty", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <UpdatePropertyResponse>result;
    }

    isolated remote function updatePropertyContext(UpdatePropertyRequest|ContextUpdatePropertyRequest req) returns ContextUpdatePropertyResponse|grpc:Error {
        map<string|string[]> headers = {};
        UpdatePropertyRequest message;
        if req is ContextUpdatePropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("accommodation.AccommodationService/updateProperty", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <UpdatePropertyResponse>result, headers: respHeaders};
    }

    isolated remote function removeProperty(RemovePropertyRequest|ContextRemovePropertyRequest req) returns PropertyList|grpc:Error {
        map<string|string[]> headers = {};
        RemovePropertyRequest message;
        if req is ContextRemovePropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("accommodation.AccommodationService/removeProperty", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <PropertyList>result;
    }

    isolated remote function removePropertyContext(RemovePropertyRequest|ContextRemovePropertyRequest req) returns ContextPropertyList|grpc:Error {
        map<string|string[]> headers = {};
        RemovePropertyRequest message;
        if req is ContextRemovePropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("accommodation.AccommodationService/removeProperty", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <PropertyList>result, headers: respHeaders};
    }

    isolated remote function bookProperty(BookRequest|ContextBookRequest req) returns BookResponse|grpc:Error {
        map<string|string[]> headers = {};
        BookRequest message;
        if req is ContextBookRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("accommodation.AccommodationService/bookProperty", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <BookResponse>result;
    }

    isolated remote function bookPropertyContext(BookRequest|ContextBookRequest req) returns ContextBookResponse|grpc:Error {
        map<string|string[]> headers = {};
        BookRequest message;
        if req is ContextBookRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("accommodation.AccommodationService/bookProperty", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <BookResponse>result, headers: respHeaders};
    }

    isolated remote function confirmBooking(ConfirmRequest|ContextConfirmRequest req) returns BookingConfirmation|grpc:Error {
        map<string|string[]> headers = {};
        ConfirmRequest message;
        if req is ContextConfirmRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("accommodation.AccommodationService/confirmBooking", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <BookingConfirmation>result;
    }

    isolated remote function confirmBookingContext(ConfirmRequest|ContextConfirmRequest req) returns ContextBookingConfirmation|grpc:Error {
        map<string|string[]> headers = {};
        ConfirmRequest message;
        if req is ContextConfirmRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("accommodation.AccommodationService/confirmBooking", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <BookingConfirmation>result, headers: respHeaders};
    }

    isolated remote function createUsers() returns CreateUsersStreamingClient|grpc:Error {
        grpc:StreamingClient sClient = check self.grpcClient->executeClientStreaming("accommodation.AccommodationService/createUsers");
        return new CreateUsersStreamingClient(sClient);
    }

    isolated remote function listAvailableProperties(ListRequest|ContextListRequest req) returns stream<PropertyList, grpc:Error?>|grpc:Error {
        map<string|string[]> headers = {};
        ListRequest message;
        if req is ContextListRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeServerStreaming("accommodation.AccommodationService/listAvailableProperties", message, headers);
        [stream<anydata, grpc:Error?>, map<string|string[]>] [result, _] = payload;
        PropertyListStream outputStream = new PropertyListStream(result);
        return new stream<PropertyList, grpc:Error?>(outputStream);
    }

    isolated remote function listAvailablePropertiesContext(ListRequest|ContextListRequest req) returns ContextPropertyListStream|grpc:Error {
        map<string|string[]> headers = {};
        ListRequest message;
        if req is ContextListRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeServerStreaming("accommodation.AccommodationService/listAvailableProperties", message, headers);
        [stream<anydata, grpc:Error?>, map<string|string[]>] [result, respHeaders] = payload;
        PropertyListStream outputStream = new PropertyListStream(result);
        return {content: new stream<PropertyList, grpc:Error?>(outputStream), headers: respHeaders};
    }
}

public isolated client class CreateUsersStreamingClient {
    private final grpc:StreamingClient sClient;

    isolated function init(grpc:StreamingClient sClient) {
        self.sClient = sClient;
    }

    isolated remote function sendUserRequest(UserRequest message) returns grpc:Error? {
        return self.sClient->send(message);
    }

    isolated remote function sendContextUserRequest(ContextUserRequest message) returns grpc:Error? {
        return self.sClient->send(message);
    }

    isolated remote function receiveCreateUsersResponse() returns CreateUsersResponse|grpc:Error? {
        var response = check self.sClient->receive();
        if response is () {
            return response;
        } else {
            [anydata, map<string|string[]>] [payload, _] = response;
            return <CreateUsersResponse>payload;
        }
    }

    isolated remote function receiveContextCreateUsersResponse() returns ContextCreateUsersResponse|grpc:Error? {
        var response = check self.sClient->receive();
        if response is () {
            return response;
        } else {
            [anydata, map<string|string[]>] [payload, headers] = response;
            return {content: <CreateUsersResponse>payload, headers: headers};
        }
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.sClient->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.sClient->complete();
    }
}

public class PropertyListStream {
    private stream<anydata, grpc:Error?> anydataStream;

    public isolated function init(stream<anydata, grpc:Error?> anydataStream) {
        self.anydataStream = anydataStream;
    }

    public isolated function next() returns record {|PropertyList value;|}|grpc:Error? {
        var streamValue = self.anydataStream.next();
        if streamValue is () {
            return streamValue;
        } else if streamValue is grpc:Error {
            return streamValue;
        } else {
            record {|PropertyList value;|} nextRecord = {value: <PropertyList>streamValue.value};
            return nextRecord;
        }
    }

    public isolated function close() returns grpc:Error? {
        return self.anydataStream.close();
    }
}

public isolated client class AccommodationServiceUpdatePropertyResponseCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendUpdatePropertyResponse(UpdatePropertyResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextUpdatePropertyResponse(ContextUpdatePropertyResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class AccommodationServiceCreateUsersResponseCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendCreateUsersResponse(CreateUsersResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextCreateUsersResponse(ContextCreateUsersResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class AccommodationServiceBookingConfirmationCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendBookingConfirmation(BookingConfirmation response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextBookingConfirmation(ContextBookingConfirmation response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class AccommodationServicePropertyListCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendPropertyList(PropertyList response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextPropertyList(ContextPropertyList response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class AccommodationServiceAddPropertyResponseCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendAddPropertyResponse(AddPropertyResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextAddPropertyResponse(ContextAddPropertyResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class AccommodationServiceBookResponseCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendBookResponse(BookResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextBookResponse(ContextBookResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class AccommodationServiceSearchPropertyResponseCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendSearchPropertyResponse(SearchPropertyResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextSearchPropertyResponse(ContextSearchPropertyResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public type ContextPropertyListStream record {|
    stream<PropertyList, error?> content;
    map<string|string[]> headers;
|};

public type ContextUserRequestStream record {|
    stream<UserRequest, error?> content;
    map<string|string[]> headers;
|};

public type ContextUpdatePropertyResponse record {|
    UpdatePropertyResponse content;
    map<string|string[]> headers;
|};

public type ContextSearchRequest record {|
    SearchRequest content;
    map<string|string[]> headers;
|};

public type ContextListRequest record {|
    ListRequest content;
    map<string|string[]> headers;
|};

public type ContextUpdatePropertyRequest record {|
    UpdatePropertyRequest content;
    map<string|string[]> headers;
|};

public type ContextSearchPropertyResponse record {|
    SearchPropertyResponse content;
    map<string|string[]> headers;
|};

public type ContextBookResponse record {|
    BookResponse content;
    map<string|string[]> headers;
|};

public type ContextPropertyList record {|
    PropertyList content;
    map<string|string[]> headers;
|};

public type ContextAddPropertyResponse record {|
    AddPropertyResponse content;
    map<string|string[]> headers;
|};

public type ContextRemovePropertyRequest record {|
    RemovePropertyRequest content;
    map<string|string[]> headers;
|};

public type ContextBookingConfirmation record {|
    BookingConfirmation content;
    map<string|string[]> headers;
|};

public type ContextBookRequest record {|
    BookRequest content;
    map<string|string[]> headers;
|};

public type ContextAddPropertyRequest record {|
    AddPropertyRequest content;
    map<string|string[]> headers;
|};

public type ContextCreateUsersResponse record {|
    CreateUsersResponse content;
    map<string|string[]> headers;
|};

public type ContextUserRequest record {|
    UserRequest content;
    map<string|string[]> headers;
|};

public type ContextConfirmRequest record {|
    ConfirmRequest content;
    map<string|string[]> headers;
|};

@protobuf:Descriptor {value: ACCOMMODATION_DESC}
public type UpdatePropertyResponse record {|
    string message = "";
|};

@protobuf:Descriptor {value: ACCOMMODATION_DESC}
public type SearchRequest record {|
    string property_id = "";
|};

@protobuf:Descriptor {value: ACCOMMODATION_DESC}
public type ListRequest record {|
    string location = "";
    float max_price = 0.0;
|};

@protobuf:Descriptor {value: ACCOMMODATION_DESC}
public type UpdatePropertyRequest record {|
    string property_id = "";
    string name = "";
    float price_per_night = 0.0;
    PropertyStatus status = AVAILABLE;
|};

@protobuf:Descriptor {value: ACCOMMODATION_DESC}
public type SearchPropertyResponse record {|
    string status = "";
    Property property = {};
|};

@protobuf:Descriptor {value: ACCOMMODATION_DESC}
public type BookResponse record {|
    string cart_id = "";
    string message = "";
|};

@protobuf:Descriptor {value: ACCOMMODATION_DESC}
public type PropertyList record {|
    Property[] properties = [];
|};

@protobuf:Descriptor {value: ACCOMMODATION_DESC}
public type AddPropertyResponse record {|
    string property_id = "";
    string message = "";
|};

@protobuf:Descriptor {value: ACCOMMODATION_DESC}
public type RemovePropertyRequest record {|
    string property_id = "";
|};

@protobuf:Descriptor {value: ACCOMMODATION_DESC}
public type BookingConfirmation record {|
    string booking_id = "";
    string property_id = "";
    int nights = 0;
    float total_cost = 0.0;
    string message = "";
|};

@protobuf:Descriptor {value: ACCOMMODATION_DESC}
public type BookRequest record {|
    string property_id = "";
    string guest_id = "";
    string check_in = "";
    string check_out = "";
|};

@protobuf:Descriptor {value: ACCOMMODATION_DESC}
public type AddPropertyRequest record {|
    string name = "";
    string location = "";
    string property_type = "";
    float price_per_night = 0.0;
    PropertyStatus status = AVAILABLE;
|};

@protobuf:Descriptor {value: ACCOMMODATION_DESC}
public type CreateUsersResponse record {|
    int count = 0;
    string message = "";
|};

@protobuf:Descriptor {value: ACCOMMODATION_DESC}
public type Property record {|
    string property_id = "";
    string name = "";
    string location = "";
    string property_type = "";
    float price_per_night = 0.0;
    PropertyStatus status = AVAILABLE;
|};

@protobuf:Descriptor {value: ACCOMMODATION_DESC}
public type UserRequest record {|
    string user_id = "";
    string name = "";
    string role = "";
|};

@protobuf:Descriptor {value: ACCOMMODATION_DESC}
public type ConfirmRequest record {|
    string cart_id = "";
|};

public enum PropertyStatus {
    AVAILABLE, BOOKED, INACTIVE
}

