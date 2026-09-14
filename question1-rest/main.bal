import ballerina/http;

// port 9090 to match the client's default serviceUrl (http://localhost:9090/api); override with Config.toml if needed. Same port as AJ's 
configurable int servicePort = 9090;

listener http:Listener assetListener = new (servicePort);
