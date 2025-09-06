document.addEventListener("DOMContentLoaded", () => {
  const headers = document.querySelectorAll(".sensibel");
  headers.forEach(header => {
    header.addEventListener("click", () => {
      header.textContent = "geheime Spalte";
    });
  });
});
