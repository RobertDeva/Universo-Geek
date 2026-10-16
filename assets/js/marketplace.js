/* Filtros locales del catálogo. No simula disponibilidad ni procesa pagos. */
(() => {
  const list = document.querySelector("#service-list");
  const search = document.querySelector("#service-search");
  const category = document.querySelector("#service-category-filter");
  const sort = document.querySelector("#service-sort");
  const reset = document.querySelector("#service-filters-reset");
  const count = document.querySelector("#service-results-count");
  const noResults = document.querySelector("#service-no-results");
  if (!list || !search || !category || !sort || !reset || !count || !noResults) return;

  const normalize = value => String(value || "").normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLocaleLowerCase("es");
  const getCards = () => Array.from(list.querySelectorAll(".service-card"));
  // Incorpora categorías nuevas sin asumir que el catálogo usa una lista cerrada.
  const syncCategories = () => {
    const selected = category.value;
    const existing = new Set(Array.from(category.options).map(option => option.value));
    const values = [...new Set(getCards().map(card => card.dataset.category).filter(Boolean))].sort((a, b) => normalize(a).localeCompare(normalize(b), "es"));
    values.forEach(value => {
      if (existing.has(value)) return;
      const option = document.createElement("option");
      option.value = value;
      option.textContent = value;
      category.append(option);
    });
    category.value = selected;
  };

  const render = () => {
    const query = normalize(search.value.trim());
    const selectedCategory = category.value;
    const cards = getCards();
    const filtered = cards.filter(card => {
      const matchesQuery = !query || normalize([card.dataset.title, card.dataset.description, card.dataset.category].join(" ")).includes(query);
      return matchesQuery && (!selectedCategory || card.dataset.category === selectedCategory);
    });
    filtered.sort((a, b) => {
      if (sort.value === "price-asc") return Number(a.dataset.price) - Number(b.dataset.price);
      if (sort.value === "price-desc") return Number(b.dataset.price) - Number(a.dataset.price);
      if (sort.value === "title") return normalize(a.dataset.title).localeCompare(normalize(b.dataset.title), "es");
      return String(b.dataset.created).localeCompare(String(a.dataset.created));
    });
    const visible = new Set(filtered);
    cards.forEach(card => { card.hidden = !visible.has(card); });
    filtered.forEach(card => list.append(card));
    const shown = filtered.length;
    count.textContent = shown === cards.length
      ? `${shown} ${shown === 1 ? "servicio disponible" : "servicios disponibles"}`
      : `${shown} de ${cards.length} servicios`;
    noResults.hidden = shown !== 0 || cards.length === 0;
  };
  [search, category, sort].forEach(control => control.addEventListener("input", render));
  category.addEventListener("change", render);
  sort.addEventListener("change", render);
  reset.addEventListener("click", () => {
    search.value = "";
    category.value = "";
    sort.value = "newest";
    render();
    search.focus();
  });
  window.addEventListener("ug:services-loaded", () => { syncCategories(); render(); });
  render();
})();
