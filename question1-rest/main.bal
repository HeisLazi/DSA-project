import ballerina/http;

// port 9090 under /api to match the client's default serviceUrl (http://localhost:9090/api)
configurable int servicePort = 9090;

listener http:Listener assetListener = new (servicePort);
