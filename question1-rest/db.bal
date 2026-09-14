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
// scheduleId is generated here, not supplied by the client, per the API contract's request body: { type, dueDate, description }
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
        updatedAsset.schedules = [...asset.schedules, newSchedule];
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

// NOTE for the team: the contract doesn't say where borrower/purpose/dueDate get stored,
// and Asset has no borrower fields in the agreed sample payload, so for now this only flips
// status. Flag with Person 2/3 whether we need to persist loan details on the asset.
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

// --- Institutions (separate resource per the "Manage institutions" mark item) ---

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

    function removeSchedule(string assetTag, string scheduleId) returns Asset? { 
        Asset? asset = getAsset(assetTag);
        if asset is () { 
            return ();
        } else {
            MaintenanceSchedule[] updatedSchedules = asset.schedules.filter(function (MaintenanceSchedule s) returns boolean {
                return s.scheduleId != scheduleId;
            });
            Asset updatedAsset = {
                assetTag: asset.assetTag,
                name: asset.name,
                description: asset.description,
                institution: asset.institution,
                site: asset.site,
                dateAcquired: asset.dateAcquired,
                lastMaintenanceDate: asset.lastMaintenanceDate,
                status: asset.status,
                components: asset.components,
                schedules: updatedSchedules,
                workOrders: asset.workOrders
            };
            _ = updateAsset(assetTag, updatedAsset);
            return updatedAsset;
               }
    
}

function addComponent(string assetTag, Component newComponent) returns Asset? { 
    Asset? asset = getAsset(assetTag); 
    if asset is () { 
        return (); 
    } else {
        Asset updatedAsset = {
            assetTag: asset.assetTag,
            name: asset.name,
            description: asset.description,
            institution: asset.institution,
            site: asset.site,
            dateAcquired: asset.dateAcquired,
            lastMaintenanceDate: asset.lastMaintenanceDate,
            status: asset.status,
            components: [...asset.components, newComponent],
            schedules: asset.schedules,
            workOrders: asset.workOrders
        };
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
        Asset updatedAsset = {
            assetTag: asset.assetTag,
            name: asset.name,
            description: asset.description,
            institution: asset.institution,
            site: asset.site,
            dateAcquired: asset.dateAcquired,
            lastMaintenanceDate: asset.lastMaintenanceDate,
            status: asset.status,
            components: updatedComponents,
            schedules: asset.schedules,
            workOrders: asset.workOrders
        };
        _ = updateAsset(assetTag, updatedAsset);
        return updatedAsset;
    }
}

function getOverdueSchedules() returns json[] {
    string today = time:utcToString(time:utcNow()).substring(0, 10); // Get current date in YYYY-MM-DD format
    json[] overdue = [];

    foreach Asset asset in getAllAssets() {
        foreach MaintenanceSchedule schedule in asset.schedules { 
            if schedule.dueDate < today { 
                overdue.push ({
                    assetTag: asset.assetTag,
                    assetName: asset.name,
                    scheduleId: schedule.scheduleId,
                    description: schedule.description,
                    dueDate: schedule.dueDate 
                });
            }
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
        Asset updatedAsset = {
            assetTag: asset.assetTag,
            name: asset.name,
            description: asset.description,
            institution: asset.institution,
            site: asset.site,
            dateAcquired: asset.dateAcquired,
            lastMaintenanceDate: asset.lastMaintenanceDate,
            status: asset.status,
            components: asset.components,
            schedules: asset.schedules,
            workOrders: [...asset.workOrders, newOrder]
        };
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
        Asset updatedAsset = {
            assetTag: asset.assetTag,
            name: asset.name,
            description: asset.description,
            institution: asset.institution,
            site: asset.site,
            dateAcquired: asset.dateAcquired,
            lastMaintenanceDate: asset.lastMaintenanceDate,
            status: asset.status,
            components: asset.components,
            schedules: asset.schedules,
            workOrders: updatedOrders
        };
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
        Asset updatedAsset = {
            assetTag: asset.assetTag,
            name: asset.name,
            description: asset.description,
            institution: asset.institution,
            site: asset.site,
            dateAcquired: asset.dateAcquired,
            lastMaintenanceDate: asset.lastMaintenanceDate,
            status: asset.status,
            components: asset.components,
            schedules: asset.schedules,
            workOrders: updateOrders
        };
        _ = updateAsset(assetTag, updatedAsset);
        return updatedAsset;
    }
}