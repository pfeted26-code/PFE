// ai-service/controllers/chat.controller.js
const { callLLM } = require("../services/ollama.service");
const { BASE_SYSTEM_PROMPT } = require("../prompts/system.prompt");
const { userDataPrompt } = require("../prompts/user.prompt");
const {
  detectIntent,
  fetchUserContext,
} = require("../services/chat.service");

exports.chat = async (req, res) => {
  const startedAt = Date.now();

  try {
    console.log("🟢 ========== AI-SERVICE REQUEST START ==========");
    console.log("📥 Request body:", JSON.stringify(req.body, null, 2));
    console.log(
      "📥 Headers:",
      req.headers.authorization ? "✅ Token present" : "❌ No token"
    );

    const message = String(req.body?.message || "").trim();
    const userId = String(req.body?.userId || "").trim();

    if (!message) {
      return res.status(400).json({
        success: false,
        error: "Message is required",
        message: "Message is required",
      });
    }

    if (!userId) {
      return res.status(400).json({
        success: false,
        error: "userId is required",
        message: "userId is required",
      });
    }

    const authorization = req.headers.authorization || "";
    const token = authorization.startsWith("Bearer ")
      ? authorization.slice(7).trim()
      : "";

    console.log(
      "🔑 Token:",
      token ? `${token.substring(0, 30)}...` : "❌ NO TOKEN"
    );

    const messages = [
      {
        role: "system",
        content: BASE_SYSTEM_PROMPT,
      },
    ];

    const intent = detectIntent(message);
    console.log(`🤖 Detected intent: "${intent}"`);

    if (token) {
      try {
        console.log(
          `📡 Fetching context for userId: ${userId}, intent: ${intent}`
        );

        const userContext = await fetchUserContext(
          userId,
          intent,
          token,
          message
        );

        console.log("📊 ========== USER CONTEXT RECEIVED ==========");
        console.log(JSON.stringify(userContext, null, 2));
        console.log("📊 ============================================");

        if (userContext && Object.keys(userContext).length > 0) {
          const generatedPrompt = userDataPrompt(userContext);

          if (
            typeof generatedPrompt === "string" &&
            generatedPrompt.trim()
          ) {
            console.log(
              "📝 User prompt generated, length:",
              generatedPrompt.length
            );

            messages.push({
              role: "system",
              content: generatedPrompt,
            });

            console.log("✅ User context added to messages");
          }
        } else {
          console.warn("⚠️ User context is empty or null");
        }
      } catch (contextError) {
        // The assistant can still answer without database context.
        console.error(
          "⚠️ Error fetching context:",
          contextError?.message || contextError
        );
      }
    } else {
      console.warn("⚠️ No token - skipping context fetch");
    }

    messages.push({
      role: "user",
      content: message,
    });

    console.log(`📤 Total messages for LLM: ${messages.length}`);
    console.log(
      "📤 Messages:",
      messages.map(
        (item, index) =>
          `${index}: ${item.role} (${item.content.length} chars)`
      )
    );

    const reply = await callLLM(messages);

    if (typeof reply !== "string" || !reply.trim()) {
      throw new Error("The language model returned an empty response");
    }

    const cleanReply = reply.trim();
    const durationMs = Date.now() - startedAt;

    console.log("✅ LLM response received:", cleanReply.substring(0, 200));
    console.log(`⏱️ Duration: ${durationMs} ms`);
    console.log("🟢 ========== AI-SERVICE REQUEST END ==========");

    // All common property names are returned for frontend compatibility.
    return res.status(200).json({
      success: true,
      reply: cleanReply,
      response: cleanReply,
      message: cleanReply,
      intent,
      durationMs,
    });
  } catch (error) {
    const durationMs = Date.now() - startedAt;

    console.error("❌ ai-service error:", error?.message || error);
    console.error("Stack:", error?.stack);

    if (res.headersSent) {
      return;
    }

    return res.status(503).json({
      success: false,
      error: "AI service error",
      message:
        error?.message ||
        "The AI assistant is temporarily unavailable.",
      details: error?.message,
      durationMs,
    });
  }
};
