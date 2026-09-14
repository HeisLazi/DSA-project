const API_URL = "http://localhost:9090/api";

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

        console.log(assets);
    } catch (error) {
        contentArea.innerHTML = `<p>${error.message}</p>`;
    }
}

assetsBtn.addEventListener("click", loadAssets);