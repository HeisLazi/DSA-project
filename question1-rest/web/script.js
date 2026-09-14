const API_URL = "http://localhost:9090";

const assetsBtn = document.getElementById("assetsBtn");
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

assetsBtn.addEventListener("click", loadAssets);