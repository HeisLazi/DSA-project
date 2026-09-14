

public type Component record {
    string compId;
    string name;
    string description;
};


public type Task record {
    string taskId;
    string description;
    boolean done = false;
};


public type WorkOrder record {
    string orderId;
    string status;
    string description;
    Task[] tasks = [];
};


public type Schedule record {
    string scheduleId;
    string 'type;
    string dueDate;
    string description;
};

// the main resource
public type Asset record {
    string assetTag;
    string name;
    string description;
    string institution;
    string site;
    string status;
    string dateAcquired;
    Component[] components = [];
    Schedule[] schedules = [];
    WorkOrder[] workOrders = [];
};



public type LoanRequest record {
    string borrowerName;
    string purpose;
    string dueDate;
};

// the body used to send the add/update schedule to.
public type ScheduleRequest record {
    string 'type;
    string dueDate;
    string description;
};

public type ApiError record{
    string message;
};
