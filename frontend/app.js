// frontend/app.js
(function () {
  const inputBaseUrl = document.getElementById("apiBaseUrl");
  const inputJwtToken = document.getElementById("jwtToken");

  const btnHealth = document.getElementById("btnHealth");
  const btnAudiencias = document.getElementById("btnAudiencias");
  const btnCrearAudiencia = document.getElementById("btnCrearAudiencia");
  const btnListarAudiencias = document.getElementById("btnListarAudiencias");

  const output = document.getElementById("output");
  const statusEl = document.getElementById("status");

  const idAudienciaEl = document.getElementById("idAudiencia");
  const abogadoIdEl = document.getElementById("abogadoId");
  const fechaEl = document.getElementById("fecha");
  const salaEl = document.getElementById("sala");
  const estadoEl = document.getElementById("estado");
  const descripcionEl = document.getElementById("descripcion");

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
      output.textContent =
        typeof data === "string" ? data : JSON.stringify(data, null, 2);
    } catch (e) {
      output.textContent = String(data);
    }
  }

  function getBaseUrl() {
    return inputBaseUrl.value.trim();
  }

  function getJwtToken() {
    return (inputJwtToken.value || "").trim();
  }

  async function callEndpoint(path, options = {}) {
    const base = getBaseUrl();
    if (!base) {
      setStatus("Por favor ingresa la URL base de la API.", "error");
      return;
    }

    const url = base.replace(/\/+$/, "") + path;
    const requireAuth = options.requireAuth || false;

    const headers = {
      "Content-Type": "application/json",
      ...(options.headers || {}),
    };

    if (requireAuth) {
      const token = getJwtToken();
      if (!token) {
        setStatus(
          "Este endpoint requiere JWT. Pega un token válido en la sección de Cognito.",
          "error"
        );
        setOutput("");
        return;
      }
      headers["Authorization"] = "Bearer " + token;
    }

    setStatus(`Llamando a ${url} ...`, "");
    setOutput("");

    try {
      const resp = await fetch(url, {
        method: options.method || "GET",
        headers,
        body: options.body ? JSON.stringify(options.body) : undefined,
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

  // =========================
  // Handlers de botones
  // =========================

  // GET /health (público, sin token)
  btnHealth.addEventListener("click", () => {
    callEndpoint("/health", { method: "GET", requireAuth: false });
  });

  // GET /audiencias (protegido, requiere JWT)
  btnAudiencias.addEventListener("click", () => {
    callEndpoint("/audiencias", { method: "GET", requireAuth: true });
  });

  // POST /audiencias – crear audiencia
  btnCrearAudiencia.addEventListener("click", () => {
    const id_audiencia = (idAudienciaEl.value || "").trim();
    const abogado_id = (abogadoIdEl.value || "").trim();
    const fecha = (fechaEl.value || "").trim();
    const sala = (salaEl.value || "").trim();
    const estado = (estadoEl.value || "").trim() || "PENDIENTE";
    const descripcion = (descripcionEl.value || "").trim();

    if (!id_audiencia || !abogado_id || !fecha || !sala) {
      setStatus(
        "Campos obligatorios para crear audiencia: id_audiencia, abogado_id, fecha, sala.",
        "error"
      );
      return;
    }

    const body = {
      id_audiencia,
      abogado_id,
      fecha,
      sala,
      estado,
    };

    if (descripcion) {
      body.descripcion = descripcion;
    }

    callEndpoint("/audiencias", {
      method: "POST",
      requireAuth: true,
      body,
    });
  });

  // GET /audiencias – listar audiencias
  btnListarAudiencias.addEventListener("click", () => {
    callEndpoint("/audiencias", { method: "GET", requireAuth: true });
  });
})();
