(function () {
  // ------------------ Referencias a elementos ------------------
  const inputBaseUrl = document.getElementById("apiBaseUrl");
  const jwtInput = document.getElementById("jwtTokenInput");

  const btnOpenCognito = document.getElementById("btnOpenCognito");
  const btnHealth = document.getElementById("btnHealth");
  const btnAudiencias = document.getElementById("btnAudiencias");

  const roleSelector = document.getElementById("roleSelector");
  const roleHint = document.getElementById("roleHint");
  const btnListAudiencias = document.getElementById("btnListAudiencias");
  const btnCreateAudiencia = document.getElementById("btnCreateAudiencia");
  const btnCancelAudiencia = document.getElementById("btnCancelAudiencia");

  const output = document.getElementById("output");
  const statusEl = document.getElementById("status");

  // Resumen de usuario
  const currentUserEl = document.getElementById("currentUser");
  const currentRoleEl = document.getElementById("currentRole");
  const currentGroupsEl = document.getElementById("currentGroups");
  const currentAssignedEl = document.getElementById("currentAssignedLawyers");
  const rawClaimsEl = document.getElementById("rawClaims");

  // Secciones que solo deberían estar activas para ADMINISTRADOR / SECRETARIA
  const adminSections = document.querySelectorAll(".only-admin-secretaria");

  // Campos de creación/cancelación
  const audId = document.getElementById("audId");
  const audAbogado = document.getElementById("audAbogado");
  const audFecha = document.getElementById("audFecha");
  const audSala = document.getElementById("audSala");
  const audEstado = document.getElementById("audEstado");
  const audDescripcion = document.getElementById("audDescripcion");
  const audCancelId = document.getElementById("audCancelId");

  // ------------------ Estado y helpers básicos ------------------

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
    return (inputBaseUrl.value || "").trim();
  }

  function getJwtToken() {
    return (jwtInput.value || "").trim();
  }

  // ------------------ Decodificación de JWT ------------------

  function decodeJwtPayload(token) {
    if (!token) return null;
    const parts = token.split(".");
    if (parts.length < 2) return null;

    try {
      let base64 = parts[1].replace(/-/g, "+").replace(/_/g, "/");
      // Relleno para múltiplos de 4
      const pad = base64.length % 4;
      if (pad === 2) base64 += "==";
      else if (pad === 3) base64 += "=";

      const json = atob(base64);
      return JSON.parse(json);
    } catch (e) {
      console.warn("No se pudo decodificar el payload del JWT:", e);
      return null;
    }
  }

  function applyClaims(claims) {
    if (!claims || typeof claims !== "object") {
      currentUserEl.textContent = "-";
      currentRoleEl.textContent = "-";
      currentGroupsEl.textContent = "-";
      currentAssignedEl.textContent = "-";
      rawClaimsEl.textContent = "";
      return;
    }

    // username
    const username =
      claims["cognito:username"] || claims["username"] || "(sin username)";
    currentUserEl.textContent = username;

    // grupos
    const groupsClaim = claims["cognito:groups"];
    let groupsList = [];
    if (Array.isArray(groupsClaim)) {
      groupsList = groupsClaim;
    } else if (typeof groupsClaim === "string") {
      groupsList = groupsClaim.split(",").map((g) => g.trim());
    }
    currentGroupsEl.textContent =
      groupsList.length > 0 ? groupsList.join(", ") : "-";

    // determinar rol igual que en el backend
    const order = ["ADMINISTRADOR", "SECRETARIA", "ABOGADO"];
    let detectedRole = null;

    for (const r of order) {
      if (groupsList.includes(r)) {
        detectedRole = r;
        break;
      }
    }

    if (!detectedRole && typeof claims["custom:rol"] === "string") {
      const cr = claims["custom:rol"];
      if (order.includes(cr)) detectedRole = cr;
    }

    currentRoleEl.textContent = detectedRole || "-";

    // abogados asignados
    const rawAssigned = claims["custom:abogados_asignados"];
    let assigned = "-";
    if (typeof rawAssigned === "string" && rawAssigned.trim()) {
      assigned = rawAssigned
        .split(",")
        .map((a) => a.trim())
        .filter(Boolean)
        .join(", ");
    }
    currentAssignedEl.textContent = assigned || "-";

    // claims completos
    try {
      rawClaimsEl.textContent = JSON.stringify(claims, null, 2);
    } catch {
      rawClaimsEl.textContent = String(claims);
    }

    // actualizar UI de rol (habilitar / deshabilitar secciones)
    updateRoleUI(detectedRole || "ABOGADO");
  }

  function explainRole(role) {
    switch (role) {
      case "ADMINISTRADOR":
        roleHint.textContent =
          "ADMINISTRADOR: puede ver todas las audiencias y crear/cancelar audiencias de cualquier abogado.";
        break;
      case "SECRETARIA":
        roleHint.textContent =
          "SECRETARIA: puede ver y gestionar audiencias solo de los abogados asignados (claim custom:abogados_asignados).";
        break;
      case "ABOGADO":
      default:
        roleHint.textContent =
          "ABOGADO: solo puede ver sus propias audiencias. Los intentos de crear/cancelar deberían fallar con 403.";
        break;
    }
  }

  function updateRoleUI(role) {
    explainRole(role);

    const canManage =
      role === "ADMINISTRADOR" || role === "SECRETARIA";

    adminSections.forEach((section) => {
      section.setAttribute("data-disabled", canManage ? "false" : "true");
    });

    // sincronizar también el selector visual de rol
    if (roleSelector) {
      roleSelector.value = role;
    }
  }

  function refreshFromToken() {
    const token = getJwtToken();
    if (!token) {
      applyClaims(null);
      return;
    }
    const claims = decodeJwtPayload(token);
    applyClaims(claims);
  }

  // ------------------ Extracción de token desde el hash ------------------

  (function tryExtractTokenFromHash() {
    const hash = window.location.hash;
    if (!hash || hash.length < 2) return;

    const params = new URLSearchParams(hash.substring(1));
    const accessToken = params.get("access_token");
    const idToken = params.get("id_token");
    const token = accessToken || idToken;

    if (token) {
      jwtInput.value = token;
      setStatus(
        "Token JWT detectado en la URL (callback de Cognito).",
        "ok"
      );
      refreshFromToken();
      // Limpiar el hash para no dejar el token en la barra de direcciones
      window.location.hash = "";
    }
  })();

  // Cuando el usuario pegue un token manualmente y salga del textarea
  jwtInput.addEventListener("blur", () => {
    refreshFromToken();
  });

  // Selector de rol (solo cambia textos y estado visual, la seguridad real es en backend)
  if (roleSelector) {
    roleSelector.addEventListener("change", () => {
      const manualRole = roleSelector.value;
      explainRole(manualRole);
      const canManage =
        manualRole === "ADMINISTRADOR" || manualRole === "SECRETARIA";
      adminSections.forEach((section) => {
        section.setAttribute("data-disabled", canManage ? "false" : "true");
      });
    });
  }

  // ------------------ Llamadas genéricas a la API ------------------

  async function callEndpoint(path, options = {}) {
    const base = getBaseUrl();
    if (!base) {
      setStatus("Por favor ingresa la URL base de la API (con o sin /dev).", "error");
      return;
    }

    const baseClean = base.replace(/\/+$/, "");
    const fullPath = path.startsWith("/") ? path : "/" + path;
    const url = baseClean + fullPath;

    const headers = {
      "Content-Type": "application/json",
      ...(options.headers || {}),
    };

    if (options.auth) {
      const token = getJwtToken();
      if (!token) {
        setStatus(
          "Este endpoint requiere token JWT. Pega un token en la sección 2 o inicia sesión desde Cognito.",
          "error"
        );
        setOutput(null);
        return;
      }
      headers["Authorization"] = "Bearer " + token;
    }

    setStatus(`Llamando a ${url} ...`, "");
    setOutput(null);

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
        json = text;
      }

      if (!resp.ok) {
        setStatus(`Error HTTP ${resp.status}`, "error");
      } else {
        setStatus("OK", "ok");
      }

      setOutput(json);
    } catch (err) {
      console.error(err);
      setStatus("Error de red o CORS. Revisa consola del navegador.", "error");
      setOutput(String(err));
    }
  }

  // ------------------ Eventos de botones ------------------

  btnOpenCognito.addEventListener("click", () => {
    if (
      typeof COGNITO_HOSTED_UI_URL === "string" &&
      COGNITO_HOSTED_UI_URL.length > 0
    ) {
      window.open(COGNITO_HOSTED_UI_URL, "_blank");
    } else {
      alert(
        "Configura COGNITO_HOSTED_UI_URL en config.js con la URL de tu Hosted UI de Cognito."
      );
    }
  });

  btnHealth.addEventListener("click", () => {
    callEndpoint("/health", { method: "GET", auth: false });
  });

  btnAudiencias.addEventListener("click", () => {
    callEndpoint("/audiencias", { method: "GET", auth: true });
  });

  btnListAudiencias.addEventListener("click", () => {
    callEndpoint("/audiencias", { method: "GET", auth: true });
  });

  btnCreateAudiencia.addEventListener("click", () => {
    const id = (audId.value || "").trim();
    const abogado = (audAbogado.value || "").trim();
    const sala = (audSala.value || "").trim();
    const estado = audEstado.value;
    const fechaRaw = audFecha.value; // formato local datetime-local

    if (!id || !abogado || !sala || !estado || !fechaRaw) {
      setStatus(
        "Para crear una audiencia, completa id_audiencia, abogado_id, fecha, sala y estado.",
        "error"
      );
      return;
    }

    // Convertir datetime-local (YYYY-MM-DDTHH:MM) a ISO con Z
    const fechaIso = new Date(fechaRaw).toISOString();

    const body = {
      id_audiencia: id,
      abogado_id: abogado,
      fecha: fechaIso,
      sala: sala,
      estado: estado,
    };

    const desc = (audDescripcion.value || "").trim();
    if (desc) {
      body.descripcion = desc;
    }

    callEndpoint("/audiencias", {
      method: "POST",
      auth: true,
      body,
    });
  });

  btnCancelAudiencia.addEventListener("click", () => {
    const id = (audCancelId.value || "").trim();
    if (!id) {
      setStatus(
        "Ingresa el id_audiencia a cancelar antes de llamar a DELETE /audiencias.",
        "error"
      );
      return;
    }

    callEndpoint(`/audiencias?id_audiencia=${encodeURIComponent(id)}`, {
      method: "DELETE",
      auth: true,
    });
  });

  // ------------------ Estado inicial ------------------

  // Por defecto, asume rol ABOGADO (se ajustará al decodificar el token real)
  updateRoleUI("ABOGADO");
})();
