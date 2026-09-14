import ballerina/time; 
map<Asset> assets = {};

function addAsset(Asset asset) {
    assets[asset.assetTag] = asset;
}

function getAsset(string assetTag) returns Asset? {
    return assets[assetTag];
}

function getAllAssets() returns Asset[] {
    return assets.toArray();
} 

function assetExists(string assetTag) returns boolean {
    return assets.hasKey(assetTag);
} 

// this funciton checks for duplicates or missing assets before adding an asset to the system. 


function updateAsset(string assetTag, Asset updatedAsset) returns boolean{
    if (assetExists(assetTag)) {
        assets[assetTag] = updatedAsset;
        return true;
    }
    return false;
} 

// this function updates the asset information if it exists in the system.

function deleteAsset(string assetTag) {
_ = assets.remove(assetTag);

}
// this function deletes an asset from the system depending on the assetTag provided.

function filterAssets(string? status, string? institution, string? site) returns Asset[] {
    return getAllAssets().filter(function (Asset i) returns boolean {
        return (status is () || i.status == status)
            && (site is () || i.site == site) 
            && (institution is () || i.institution ==institution);
    });
}

int scheduleSeq = 0;
function nextScheduleId() returns string {
    scheduleSeq += 1;
    return string `SCH-${scheduleSeq}`;
}

function addSchedule(string assetTag, NewScheduleInput input) returns Asset? {
    Asset? asset = getAsset(assetTag);
    if asset is () {
        return ();
    } else {
        MaintenanceSchedule newSchedule = {
            scheduleId: nextScheduleId(),
            'type: input.'type,
            dueDate: input.dueDate,
            description: input.description
        };
        Asset updatedAsset = asset.clone();
        updatedAsset.schedules = [...updatedAsset.schedules, newSchedule];
        _ = updateAsset(assetTag, updatedAsset);
        return updatedAsset;
    }
}

function updateSchedule(string assetTag, string scheduleId, NewScheduleInput input) returns Asset? {
    Asset? asset = getAsset(assetTag);
    if asset is () {
        return ();
    }
    boolean exists = false;
    foreach MaintenanceSchedule s in asset.schedules {
        if s.scheduleId == scheduleId {
            exists = true;
        }
    }
    if !exists {
        return ();
    }
    MaintenanceSchedule[] updatedSchedules = asset.schedules.map(function(MaintenanceSchedule s) returns MaintenanceSchedule {
        if s.scheduleId == scheduleId {
            return {
                scheduleId: s.scheduleId,
                'type: input.'type,
                dueDate: input.dueDate,
                description: input.description
            };
        }
        return s;
    });
    Asset updatedAsset = asset.clone();
    updatedAsset.schedules = updatedSchedules;
    _ = updateAsset(assetTag, updatedAsset);
    return updatedAsset;
}

    function removeSchedule(string assetTag, string scheduleId) returns Asset? { 
        Asset? asset = getAsset(assetTag);
        if asset is () { 
            return ();
        } else {
            MaintenanceSchedule[] updatedSchedules = asset.schedules.filter(function (MaintenanceSchedule s) returns boolean {
                return s.scheduleId != scheduleId;
            });
            Asset updatedAsset = asset.clone();
            updatedAsset.schedules = updatedSchedules;
            _ = updateAsset(assetTag, updatedAsset);
            return updatedAsset;
               }
    
}

function addComponent(string assetTag, Component newComponent) returns Asset? { 
    Asset? asset = getAsset(assetTag); 
    if asset is () { 
        return (); 
    } else {
        Asset updatedAsset = asset.clone();
        updatedAsset.components = [...updatedAsset.components, newComponent];
        _ = updateAsset(assetTag, updatedAsset);
        return updatedAsset;
    }
}

function removeComponent(string assetTag, string compId) returns Asset? { 

    Asset? asset = getAsset(assetTag);
    if asset is () {
        return ();
    } else {
        Component[] updatedComponents = asset.components.filter(function (Component c) returns boolean {
            return c.compId != compId;
        });
        Asset updatedAsset = asset.clone();
        updatedAsset.components = updatedComponents;
        _ = updateAsset(assetTag, updatedAsset);
        return updatedAsset;
    }
}

// contract note: loan/booking should flip status to LOANED_OUT or OCCUPIED depending on
// asset type, but there's currently no field distinguishing physical loans from bookings,
// so this always sets LOANED_OUT for now - flagged for the team to confirm.
function loanAsset(string assetTag, LoanRequest req) returns Asset? {
    Asset? asset = getAsset(assetTag);
    if asset is () {
        return ();
    }
    Asset updatedAsset = asset.clone();
    updatedAsset.status = "LOANED_OUT";
    updatedAsset.borrowerName = req.borrowerName;
    updatedAsset.purpose = req.purpose;
    updatedAsset.loanDueDate = req.dueDate;
    _ = updateAsset(assetTag, updatedAsset);
    return updatedAsset;
}

function returnAsset(string assetTag) returns Asset? {
    Asset? asset = getAsset(assetTag);
    if asset is () {
        return ();
    }
    Asset updatedAsset = asset.clone();
    updatedAsset.status = "AVAILABLE";
    updatedAsset.borrowerName = ();
    updatedAsset.purpose = ();
    updatedAsset.loanDueDate = ();
    _ = updateAsset(assetTag, updatedAsset);
    return updatedAsset;
}

// contract says GET /assets/overdue returns 200 Asset[] - this used to return a flat list
// of schedule summaries instead, which broke the client's Asset[] parsing. Fixed to return
// the full Asset objects that have at least one overdue schedule.
function getOverdueSchedules() returns Asset[] {
    string today = time:utcToString(time:utcNow()).substring(0, 10); // Get current date in YYYY-MM-DD format
    Asset[] overdue = [];

    foreach Asset asset in getAllAssets() {
        boolean hasOverdue = false;
        foreach MaintenanceSchedule schedule in asset.schedules {
            if schedule.dueDate < today {
                hasOverdue = true;
            }
        }
        if hasOverdue {
            overdue.push(asset);
        }
    }
    return overdue;
}

int workOrderSeq = 0;
function nextWorkOrderId() returns string {
    workOrderSeq += 1;
    return string `WO-${workOrderSeq}`; 
} // everytime you open a work order you assign it a unique ID then gives the next ID its own number so no two work orders have the same ID. Two IDs cant be mixeed up. 

function openWorkOrder(string assetTag, string compId, string scheduleId, string description) returns Asset? {
    Asset? asset = getAsset(assetTag);
    if asset is () {
        return ();
    } else {
        WorkOrder newOrder = {
            orderId: nextWorkOrderId(),
            compId: compId,
            scheduleId: scheduleId,
            status: "OPEN",
            description: description,
            tasks: []
        };
        Asset updatedAsset = asset.clone();
        updatedAsset.workOrders = [...updatedAsset.workOrders, newOrder];
        _ = updateAsset(assetTag, updatedAsset);
        return updatedAsset;
    }
}


function closeWorkOrder(string assetTag, string orderId) returns Asset? {
    Asset? asset = getAsset(assetTag);
    if asset is () { 
        return ();
    } else { 
        WorkOrder[] updatedOrders = asset.workOrders.map(function(WorkOrder wo) returns WorkOrder {
    if wo.orderId == orderId {
        wo.status = "CLOSED";
    }
    return wo;
});
        Asset updatedAsset = asset.clone();
        updatedAsset.workOrders = updatedOrders;
        _ = updateAsset(assetTag, updatedAsset);
        return updatedAsset;
    }
}

int taskIdSeq = 0;

function nextTaskId() returns string {
    taskIdSeq += 1;
    return string `TASK-${taskIdSeq}`;
} 

function addTaskToWorkOrder(string assetTag, string orderId, string description) returns Asset? {
    Asset? asset = getAsset(assetTag);
    if asset is () {
        return ();
    } else {
        WorkOrder[] updateOrders = asset.workOrders.map(function(WorkOrder wo) returns WorkOrder {
            if wo.orderId == orderId { 
                WorkOrderTask newTask = {
                    taskId: nextTaskId(),
                    description: description
                };
                wo.tasks.push(newTask);
            }
            return wo;
        });
        Asset updatedAsset = asset.clone(); 
        updatedAsset.workOrders = updateOrders;
        _ = updateAsset(assetTag, updatedAsset);
        return updatedAsset;
    }
}
//Institutions

map<Institution> institutions = {};

function addInstitution(Institution institution) { 
    institutions[institution.name] = institution;
}

function getAllInstitutions() returns Institution[] {
    return institutions.toArray();
}

function institutionExists(string name) returns boolean {
    return institutions.hasKey(name);
}

function removeInstitution(string name) returns boolean {
    if institutionExists(name) {
        _ = institutions.remove(name);
        return true;
    }
    return false;
}
