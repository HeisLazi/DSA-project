import ballerina/http;

// every non-2xx response returns { "message": "..." } per the API contract
function notFound(string message) returns http:NotFound {
    return {body: {message: message}};
}

service /api/assets on assetListener {
    // everything inside service /api/assets on assetListener handles requests to paths starting with /api/assets.
    // resource funcion handles the HTTP method (GET, POST, etc.), the word after is the path segment.

    resource function post .(@http:Payload Asset newAsset) returns Asset {
        addAsset(newAsset);
        return newAsset;
    }

    resource function get .(string? status, string? institution, string? site) returns Asset[] {
        return filterAssets(status, institution, site);
    }

    resource function get overdue() returns json[] {
        return getOverdueSchedules();
    }

    resource function get [string assetTag]() returns Asset|http:NotFound {
        Asset? asset = getAsset(assetTag);
        if asset is Asset {
            return asset;
        }
        return notFound("Asset not found: " + assetTag);
    }

    resource function put [string assetTag](@http:Payload Asset updatedAsset) returns Asset|http:NotFound {
        boolean success = updateAsset(assetTag, updatedAsset);
        if success {
            return updatedAsset;
        }
        return notFound("Asset not found: " + assetTag);
    }

    resource function delete [string assetTag]() returns http:Ok|http:NotFound {
        if !assetExists(assetTag) {
            return notFound("Asset not found: " + assetTag);
        }
        deleteAsset(assetTag);
        return http:OK;
    }

    // loan or book an asset - status flips to LOANED_OUT (see note in db.bal:loanAsset)
    resource function post [string assetTag]/loan(@http:Payload LoanRequest loanReq) returns Asset|http:NotFound {
        Asset? updated = loanAsset(assetTag, loanReq);
        if updated is Asset {
            return updated;
        }
        return notFound("Asset not found: " + assetTag);
    }

    // "return" is a reserved word in Ballerina, escaped as 'return - the path segment is still "return"
    resource function post [string assetTag]/'return() returns Asset|http:NotFound {
        Asset? updated = returnAsset(assetTag);
        if updated is Asset {
            return updated;
        }
        return notFound("Asset not found: " + assetTag);
    }

    resource function post [string assetTag]/schedules(@http:Payload NewScheduleInput input) returns Asset|http:NotFound {
        Asset? updated = addSchedule(assetTag, input);
        if updated is Asset {
            return updated;
        }
        return notFound("Asset not found: " + assetTag);
    }

    resource function put [string assetTag]/schedules/[string scheduleId](@http:Payload NewScheduleInput input) returns Asset|http:NotFound {
        Asset? updated = updateSchedule(assetTag, scheduleId, input);
        if updated is Asset {
            return updated;
        }
        return notFound("Asset or schedule not found");
    }

    resource function delete [string assetTag]/schedules/[string scheduleId]() returns Asset|http:NotFound {
        Asset? updated = removeSchedule(assetTag, scheduleId);
        if updated is Asset {
            return updated;
        }
        return notFound("Asset not found: " + assetTag);
    }

    resource function post [string assetTag]/components(@http:Payload Component newComponent) returns Asset|http:NotFound {
        Asset? updated = addComponent(assetTag, newComponent);
        if updated is Asset {
            return updated;
        }
        return notFound("Asset not found: " + assetTag);
    }

    resource function delete [string assetTag]/components/[string componentId]() returns Asset|http:NotFound {
        Asset? updated = removeComponent(assetTag, componentId);
        if updated is Asset {
            return updated;
        }
        return notFound("Asset not found: " + assetTag);
    }

    resource function post [string assetTag]/workorders(@http:Payload NewWorkOrderInput input) returns Asset|http:NotFound {
        Asset? updated = openWorkOrder(assetTag, input.compId, input.scheduleId, input.description);
        if updated is Asset {
            return updated;
        }
        return notFound("Asset not found: " + assetTag);
    }

    resource function patch [string assetTag]/workorders/[string orderId]() returns Asset|http:NotFound {
        Asset? updated = closeWorkOrder(assetTag, orderId);
        if updated is Asset {
            return updated;
        }
        return notFound("Asset or work order not found");
    }

    resource function post [string assetTag]/workorders/[string orderId]/tasks(@http:Payload NewTaskInput input) returns Asset|http:NotFound {
        Asset? updated = addTaskToWorkOrder(assetTag, orderId, input.description);
        if updated is Asset {
            return updated;
        }
        return notFound("Asset or work order not found");
    }
}

// separate resource per the contract's "Manage institutions" mark item - not called by the CLI client
service /api/institutions on assetListener {

    resource function get .() returns Institution[] {
        return getAllInstitutions();
    }

    resource function post .(@http:Payload Institution newInstitution) returns Institution {
        addInstitution(newInstitution);
        return newInstitution;
    }

    resource function delete [string name]() returns http:Ok|http:NotFound {
        if removeInstitution(name) {
            return http:OK;
        }
        return notFound("Institution not found: " + name);
    }
}
