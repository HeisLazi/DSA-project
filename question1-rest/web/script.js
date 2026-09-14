const API_URL = "http://localhost:9090/api";

const assetsBtn = document.getElementById("assetsBtn");
const addAssetBtn = document.getElementById("addAssetBtn");
const campusBtn = document.getElementById("campusBtn");
const overdueBtn = document.getElementById("overdueBtn");
const loanBtn = document.getElementById("loanBtn");
const scheduleBtn = document.getElementById("scheduleBtn");
const refreshBtn = document.getElementById("refreshBtn");

const pageTitle = document.getElementById("pageTitle");
const pageDescription = document.getElementById("pageDescription");
const contentArea = document.getElementById("contentArea");
const message = document.getElementById("message");

async function loadAssets() {
    pageTitle.textContent = "All Assets";
    pageDescription.textContent =
        "View resources across all institutions and campuses.";

    contentArea.innerHTML = "<p>Loading assets...</p>";

    try {
        const response = await fetch(`${API_URL}/assets`);

        if (!response.ok) {
            throw new Error("Failed to load assets.");
        }

        const assets = await response.json();

        displayAssets(assets);
    } catch (error) {
        contentArea.innerHTML = `<p>${error.message}</p>`;
    }
}

function displayAssets(assets) {

    if (assets.length === 0) {
        contentArea.innerHTML = "<p>No assets are currently registered.</p>";
        return;
    }

    let table = `
        <table class="asset-table">
            <thead>
                <tr>
                    <th>Asset Tag</th>
                    <th>Name</th>
                    <th>Institution</th>
                    <th>Site</th>
                    <th>Status</th>
                    <th>Date Acquired</th>
                </tr>
            </thead>
            <tbody>
    `;

    for (const asset of assets) {
        table += `
            <tr>
                <td>${asset.assetTag}</td>
                <td>${asset.name}</td>
                <td>${asset.institution}</td>
                <td>${asset.site}</td>
                <td>${asset.status}</td>
                <td>${asset.dateAcquired}</td>
            </tr>
        `;
    }

    table += `
            </tbody>
        </table>
    `;

    contentArea.innerHTML = table;
}

function showAddAssetForm() {
    pageTitle.textContent = "Add Asset";
    pageDescription.textContent =
        "Register a new resource in the system.";

    contentArea.innerHTML = `
        <form id="addAssetForm">
            <label for="assetTag">Asset Tag</label>
            <input type="text" id="assetTag" required>

            <label for="assetName">Name</label>
            <input type="text" id="assetName" required>

            <label for="description">Description</label>
            <input type="text" id="description" required>

            <label for="institution">Institution</label>
            <input type="text" id="institution" required>

            <label for="site">Site / Campus</label>
            <input type="text" id="site" required>

            <label for="dateAcquired">Date Acquired</label>
            <input type="date" id="dateAcquired" required>

            <label for="status">Status</label>
            <select id="status">
                <option value="AVAILABLE">AVAILABLE</option>
                <option value="LOANED_OUT">LOANED OUT</option>
                <option value="OCCUPIED">OCCUPIED</option>
                <option value="UNDER_MAINTENANCE">UNDER MAINTENANCE</option>
                <option value="DISPOSED">DISPOSED</option>
            </select>

            <button type="submit">Add Asset</button>
        </form>
    `;

    document
        .getElementById("addAssetForm")
        .addEventListener("submit", addAsset);
}

async function addAsset(event) {
    event.preventDefault();

    const newAsset = {
        assetTag: document.getElementById("assetTag").value,
        name: document.getElementById("assetName").value,
        description: document.getElementById("description").value,
        institution: document.getElementById("institution").value,
        site: document.getElementById("site").value,
        status: document.getElementById("status").value,
        dateAcquired: document.getElementById("dateAcquired").value,
        components: [],
        schedules: [],
        workOrders: []
    };

    try {
        const response = await fetch(`${API_URL}/assets`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify(newAsset)
        });

        if (!response.ok) {
            throw new Error("Failed to add asset.");
        }

        message.textContent = "Asset added successfully.";

        await loadAssets();

    } catch (error) {
        message.textContent = error.message;
    }
}

function showCampusView() {
    pageTitle.textContent = "Campus View";
    pageDescription.textContent =
        "Filter resources by institution and campus.";

    message.textContent = "";

    contentArea.innerHTML = `
        <form id="campusForm">
            <label for="campusInstitution">Institution</label>
            <input type="text" id="campusInstitution" required>

            <label for="campusSite">Site / Campus</label>
            <input type="text" id="campusSite">

            <button type="submit">Search</button>
        </form>

        <div id="campusResults"></div>
    `;

    document
        .getElementById("campusForm")
        .addEventListener("submit", filterCampusAssets);
}

async function filterCampusAssets(event) {
    event.preventDefault();

    const institution =
        document.getElementById("campusInstitution").value;

    const site =
        document.getElementById("campusSite").value;

    let url =
        `${API_URL}/assets?institution=${encodeURIComponent(institution)}`;

    if (site !== "") {
        url += `&site=${encodeURIComponent(site)}`;
    }

    try {
        const response = await fetch(url);

        if (!response.ok) {
            throw new Error("Failed to load campus assets.");
        }

        const assets = await response.json();

        displayAssets(assets);

    } catch (error) {
        contentArea.innerHTML = `<p>${error.message}</p>`;
    }
}

async function loadOverdueAssets() {
    pageTitle.textContent = "Overdue Maintenance";
    pageDescription.textContent =
        "View assets with maintenance schedules that are past their due date.";

    message.textContent = "";
    contentArea.innerHTML = "<p>Loading overdue items...</p>";

    try {
        const response = await fetch(`${API_URL}/assets/overdue`);

        if (!response.ok) {
            throw new Error("Failed to load overdue items.");
        }

        const overdueItems = await response.json();

        displayOverdueAssets(overdueItems);

    } catch (error) {
        contentArea.innerHTML = `<p>${error.message}</p>`;
    }
}

function displayOverdueAssets(overdueItems) {

    if (overdueItems.length === 0) {
        contentArea.innerHTML =
            "<p>There are currently no overdue maintenance schedules.</p>";
        return;
    }

    let table = `
        <table class="asset-table">
            <thead>
                <tr>
                    <th>Asset Tag</th>
                    <th>Asset Name</th>
                    <th>Schedule ID</th>
                    <th>Description</th>
                    <th>Due Date</th>
                </tr>
            </thead>
            <tbody>
    `;

    for (const item of overdueItems) {
        table += `
            <tr>
                <td>${item.assetTag}</td>
                <td>${item.assetName}</td>
                <td>${item.scheduleId}</td>
                <td>${item.description}</td>
                <td>${item.dueDate}</td>
            </tr>
        `;
    }

    table += `
            </tbody>
        </table>
    `;

    contentArea.innerHTML = table;
}

assetsBtn.addEventListener("click", loadAssets);
addAssetBtn.addEventListener("click", showAddAssetForm);
campusBtn.addEventListener("click", showCampusView);
overdueBtn.addEventListener("click", loadOverdueAssets);