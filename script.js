const pages = document.querySelectorAll(".page");
const navButtons = document.querySelectorAll(".nav-button");
const pageButtons = document.querySelectorAll("[data-page]");
const goButtons = document.querySelectorAll("[data-go]");

function goToPage(pageName) {
    pages.forEach((page) => {
        page.classList.toggle("active", page.id === pageName);
    });

    navButtons.forEach((button) => {
        button.classList.toggle("active", button.dataset.page === pageName);
    });

    history.replaceState(null, "", `#${pageName}`);
    window.scrollTo({ top: 0, behavior: "smooth" });
}

pageButtons.forEach((button) => {
    button.addEventListener("click", () => {
        goToPage(button.dataset.page);
    });
});

goButtons.forEach((button) => {
    button.addEventListener("click", () => {
        goToPage(button.dataset.go);
    });
});

const validPages = ["home", "projects", "about"];
const hash = window.location.hash.replace("#", "");

if (validPages.includes(hash)) {
    goToPage(hash);
} else {
    goToPage("home");
}
