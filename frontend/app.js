(function () {
  const inputBaseUrl = document.getElementById("apiBaseUrl");
  const btnHealth = document.getElementById("btnHealth");
  const btnAudiencias = document.getElementById("btnAudiencias");
  const output = document.getElementById("output");
  const statusEl = document.getElementById("status");

  // Si existe API_BASE_URL en config.js, usarlo como valor por defecto
  if (typeof API_BASE_URL === "string" && API_BASE_URL.length > 0) {
    inputBaseUrl.value = API_BASE_URL;
  }

  function setStatus(msg, type) {
    statusEl.textContent = msg || "";
    statusEl.className = "status " + (type || "");
  }

  function setOutput(data) {
    if (!data) {
      output.textContent = "";
      return;
    }
    try {
      output.textContent = typeof data === "string"
        ? data
        : JSON.stringify(data, null, 2);
    } catch (e) {
      output.textContent = String(data);
    }
  }

  function getBaseUrl() {
    return inputBaseUrl.value.trim();
  }

  async function callEndpoint(path, options = {}) {
    const base = getBaseUrl();
    if (!base) {
      setStatus("Por favor ingresa la URL base de la API.", "error");
      return;
    }

    const url = base.replace(/\/+$/, "") + path;

    setStatus(`Llamando a ${url} ...`, "");
    setOutput("");

    try {
      const resp = await fetch(url, {
        method: options.method || "GET",
        headers: {
          "Content-Type": "application/json",
          ...(options.headers || {})
        },
        body: options.body ? JSON.stringify(options.body) : undefined
      });

      const text = await resp.text();
      let json;
      try {
        json = JSON.parse(text);
      } catch {
        json = text; // no era JSON, mostrar texto tal cual
      }

      if (!resp.ok) {
        setStatus(`Error HTTP ${resp.status}`, "error");
      } else {
        setStatus("OK", "ok");
      }

      setOutput(json);
    } catch (err) {
      console.error(err);
      setStatus("Error de red o CORS. Revisa consola.", "error");
      setOutput(String(err));
    }
  }

  btnHealth.addEventListener("click", () => {
    callEndpoint("/health"); // lo ajustas al endpoint real cuando exista
  });

  btnAudiencias.addEventListener("click", () => {
    // mientras no tengas backend real, esto puede apuntar a un mock o a /audiencias
    callEndpoint("/audiencias");
  });
})();
