(function () {
  const inputBaseUrl = document.getElementById("apiBaseUrl");
  const jwtInput = document.getElementById("jwtTokenInput");
  const btnHealth = document.getElementById("btnHealth");
  const btnAudiencias = document.getElementById("btnAudiencias");
  const btnOpenCognito = document.getElementById("btnOpenCognito");

  const roleSelector = document.getElementById("roleSelector");
  const roleHint = document.getElementById("roleHint");
  const btnListAudiencias = document.getElementById("btnListAudiencias");
  const btnCreateAudiencia = document.getElementById("btnCreateAudiencia");
  const btnCancelAudiencia = document.getElementById("btnCancelAudiencia");

  const output = document.getElementById("output");
  const statusEl = document.getElementById("status");

  // Campos de creación/cancelación
  const audId = document.getElementById("audId");
  const audAbogado = document.getElementById("audAbogado");
  const audFecha = document.getElementById("audFecha");
  const audSala = document.getElementById("audSala");
  const audEstado = document.getElementById("audEstado");
  const audDescripcion = document.getElementById("audDescripcion");
  const audCancelId = document.getElementById("audCancelId");

  // --------------- helpers UI ---------------

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
    return (jwtInput.value || "").trim();
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

  explainRole(roleSelector.value);

  roleSelector.addEventListener("change", () => {
    explainRole(roleSelector.value);
  });

  // Intentar extraer token de la URL hash si vienes de un callback de Cognito
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
      // Limpiar el hash para no dejar el token en la barra de direcciones
      window.location.hash = "";
    }
  })();

  // --------------- llamada genérica a la API ---------------

  async function callEndpoint(path, options = {}) {
    const base = getBaseUrl();
    if (!base) {
      setStatus("Por favor ingresa la URL base de la API.", "error");
      return;
    }

    const url = base.replace(/\/+$/, "") + path;

    const headers = {
      "Content-Type": "application/json",
      ...(options.headers || {}),
    };

    if (options.auth) {
      const token = getJwtToken();
      if (!token) {
        setStatus(
          "Este endpoint requiere token JWT. Pega un token en la sección 2.",
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
      setStatus("Error de red o CORS. Revisa consola.", "error");
      setOutput(String(err));
    }
  }

  // --------------- botones sección 2 / 3 ---------------

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

  // --------------- Mini UI Audiencias ---------------

  btnListAudiencias.addEventListener("click", () => {
    callEndpoint("/audiencias", { method: "GET", auth: true });
  });

  btnCreateAudiencia.addEventListener("click", () => {
    const id = audId.value.trim();
    const abogado = audAbogado.value.trim();
    const sala = audSala.value.trim();
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

    const desc = audDescripcion.value.trim();
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
    const id = audCancelId.value.trim();
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
})();
