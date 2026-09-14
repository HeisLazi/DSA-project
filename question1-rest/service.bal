import ballerina/http;

service /api/assets on assetListener {
     // example: resource function get test() returns string {
     //   return "Hello, World!";
     // everything inside service /assets on assetListener handles requests to paths starting with /assets. 
     // resource funcion handles the GET request, the word after resource function is the HTTP method (GET, POST, etc.) and the word after is the path segment. 

resource function post .(@http:Payload Asset newAsset) returns Asset {
    addAsset(newAsset);
    return newAsset;
 }

 resource function get .(string? status, string? institution, string? site) returns Asset[] {
    return filterAssets(status, institution, site);
 }

 resource function get [string assetTag]() returns Asset|http:NotFound {
    Asset? asset = getAsset(assetTag);
    if (asset is Asset) {
        return asset;
    } else {
        return http:NOT_FOUND;
    }
 }

 resource function put [string assetTag](@http:Payload Asset updatedAsset) returns Asset|http:NotFound {
    boolean success = updateAsset(assetTag, updatedAsset); 
    if (success) {
          return updatedAsset;
     } else {
          return http:NOT_FOUND;
     }
 }
 resource function get overdue() returns json[]{
    return getOverdueSchedules();
 }

 // loan or book an asset
 resource function post [string assetTag]/loan(@http:Payload LoanRequest loanReq) returns Asset|http:NotFound {
    Asset? updated = loanAsset(assetTag, loanReq);
    if updated is Asset {
        return updated;
    }
    return http:NOT_FOUND;
 }

 // "return" is a reserved word in Ballerina, escaped as 'return - the path segment is still "return"
 resource function post [string assetTag]/'return() returns Asset|http:NotFound {
    Asset? updated = returnAsset(assetTag);
    if updated is Asset {
        return updated;
    }
    return http:NOT_FOUND;
 }

 resource function delete [string assetTag]() returns http:Ok|http:NotFound { 
    if !assetExists(assetTag) {
        return http:NOT_FOUND;
    } else {
        deleteAsset(assetTag);
        return http:OK;
    }
   }

   resource function post[string assetTag]/schedules(@http:Payload MaintenanceSchedule newSchedule) returns Asset|http:NotFound {
    Asset? updated = addSchedule(assetTag, newSchedule);
    if updated is Asset { 
        return updated; 
    } else {
        return http:NOT_FOUND;
    }
    }

resource function delete [string assetTag]/schedules/[string scheduleId]() returns Asset|http:NotFound {
    Asset? updated = removeSchedule(assetTag, scheduleId);
    if updated is Asset {
        return updated;
    }
    return http:NOT_FOUND;
}

resource function post [string assetTag]/components(@http:Payload Component newComponent) returns Asset|http:NotFound {
    Asset? updated = addComponent(assetTag, newComponent);
    if updated is Asset {
        return updated;
    } else {
        return http:NOT_FOUND;
    }
}

resource function delete [string assetTag]/components/[string componentId]() returns Asset|http:NotFound {
    Asset? updated = removeComponent(assetTag, componentId);
    if updated is Asset {
        return updated;
    } else {
        return http:NOT_FOUND;
    }
}

resource function post [string assetTag]/workorders(@http:Payload NewWorkOrderInput input) returns Asset|http:NotFound {
    Asset? updated = openWorkOrder(assetTag, input.compId, input.scheduleId, input.description);
    if updated is Asset {
        return updated;
    } else {
        return http:NOT_FOUND;
    }
}

resource function patch [string assetTag]/workorders/[string orderId]() returns Asset|http:NotFound {
    Asset? updated = closeWorkOrder(assetTag, orderId);
    if updated is Asset {
        return updated;
    } else {
        return http:NOT_FOUND;
    }
}
resource function post [string assetTag]/workorders/[string orderId]/tasks(@http:Payload NewTaskInput input) returns Asset|http:NotFound {
    Asset? updated = addTaskToWorkOrder(assetTag, orderId, input.description);
    if updated is Asset {
        return updated;
    } else {
        return http:NOT_FOUND;
    }
}
}