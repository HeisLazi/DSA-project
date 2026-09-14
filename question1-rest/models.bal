 public type Component record {|
    string compId;
    string name;
    string description;
|};

public type MaintenanceSchedule record {|
    string scheduleId;
    string 'type; // type is a reserved keyword in Ballerina, so we use 'type to avoid conflicts
    string dueDate;
    string description;
|};   

// body the client sends to create/update a schedule - scheduleId is generated server-side,
// not supplied by the client (the client only ever sends type/dueDate/description)
public type NewScheduleInput record {|
    string 'type;
    string dueDate;
    string description;
|};

public type WorkOrderTask record {|
    string taskId;
    string description;
   |};

public type WorkOrder record {|
    string orderId;
    string compId;
    string scheduleId; // to link work order to the specific component
    string status;
    WorkOrderTask[] tasks;
    string description;
|}; 

public type Asset record {|
    string status;
    string assetTag; 
    string name;
    string description;
    string institution;
    string site; 
    string dateAcquired; 
    string lastMaintenanceDate;
    Component[] components; // list of components associated with the asset
    MaintenanceSchedule[] schedules; // list of maintenance schedules for the asset
    WorkOrder[] workOrders; // list of work orders associated with the asset
|};

public type NewWorkOrderInput record {|
    string compId;   
    string scheduleId;   
    string description;   
|};

public type NewTaskInput record {|
    string description;
|};

// body for POST /assets/{assetTag}/loan
public type LoanRequest record {|
    string borrowerName;
    string purpose;
    string dueDate;
|};