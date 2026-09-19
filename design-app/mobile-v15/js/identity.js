document.addEventListener("click", (event) => {
  const button = event.target.closest("[data-replay]");
  if (!button) return;
  const object = button.closest("article").querySelector("object");
  object.data = `${object.data.split("?")[0]}?replay=${Date.now()}`;
});
