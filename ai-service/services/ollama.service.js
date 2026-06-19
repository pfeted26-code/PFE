// ai-service/services/ollama.service.js
const OLLAMA_URL =
  process.env.OLLAMA_URL ||
  "http://127.0.0.1:11434/v1/chat/completions";

const OLLAMA_MODEL =
  process.env.OLLAMA_MODEL ||
  "llama3.1:8b";

const OLLAMA_TIMEOUT_MS =
  Number(process.env.OLLAMA_TIMEOUT_MS) ||
  180000;

async function callLLM(messages) {
  if (!Array.isArray(messages) || messages.length === 0) {
    throw new Error("Messages must be a non-empty array");
  }

  messages.forEach((item, index) => {
    if (!item?.role) {
      throw new Error(`Message ${index} is missing the role field`);
    }

    if (typeof item?.content !== "string") {
      throw new Error(
        `Message ${index} content must be a string`
      );
    }
  });

  const controller = new AbortController();

  const timeoutId = setTimeout(() => {
    controller.abort();
  }, OLLAMA_TIMEOUT_MS);

  try {
    console.log(
      `📤 Sending ${messages.length} messages to Ollama model ${OLLAMA_MODEL}`
    );

    const response = await fetch(OLLAMA_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: OLLAMA_MODEL,
        messages,
        temperature: 0.2,
        stream: false,
        keep_alive: "10m",
      }),
      signal: controller.signal,
    });

    const responseText = await response.text();

    if (!response.ok) {
      console.error("❌ Ollama error response:", responseText);

      throw new Error(
        `Ollama API error ${response.status}: ${
          responseText || response.statusText
        }`
      );
    }

    let data;

    try {
      data = JSON.parse(responseText);
    } catch {
      throw new Error("Ollama returned invalid JSON");
    }

    // OpenAI-compatible Ollama endpoint.
    const openAICompatibleReply =
      data?.choices?.[0]?.message?.content;

    // Native Ollama /api/chat endpoint.
    const nativeChatReply =
      data?.message?.content;

    // Native Ollama /api/generate endpoint.
    const nativeGenerateReply =
      data?.response;

    const reply =
      openAICompatibleReply ||
      nativeChatReply ||
      nativeGenerateReply;

    if (typeof reply !== "string" || !reply.trim()) {
      console.error(
        "❌ Unsupported Ollama response:",
        JSON.stringify(data, null, 2)
      );

      throw new Error(
        "Invalid or empty response format from Ollama"
      );
    }

    return reply.trim();
  } catch (error) {
    if (error?.name === "AbortError") {
      throw new Error(
        `Ollama request timed out after ${
          OLLAMA_TIMEOUT_MS / 1000
        } seconds`
      );
    }

    throw error;
  } finally {
    clearTimeout(timeoutId);
  }
}

module.exports = {
  callLLM,
};
