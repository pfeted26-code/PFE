// Backend/controllers/chat.controller.js
const axios = require("axios");
const mongoose = require("mongoose");
const Conversation = require("../models/conversation");

const AI_SERVICE_URL =
  process.env.AI_SERVICE_URL ||
  "http://127.0.0.1:7000";

const AI_REQUEST_TIMEOUT_MS =
  Number(process.env.AI_REQUEST_TIMEOUT_MS) ||
  180000;

exports.chat = async (req, res) => {
  const startedAt = Date.now();

  try {
    const message = String(req.body?.message || "").trim();
    const requestedConversationId = String(
      req.body?.conversationId || ""
    ).trim();
    const certificationId = req.body?.certificationId;

    const authenticatedUserId =
      req.user?._id ||
      req.user?.id;

    if (!authenticatedUserId) {
      return res.status(401).json({
        success: false,
        message: "User is not authenticated.",
      });
    }

    if (!message) {
      return res.status(400).json({
        success: false,
        message: "Message is required.",
      });
    }

    const userId = authenticatedUserId.toString();

    const conversationId =
      requestedConversationId ||
      new mongoose.Types.ObjectId().toString();

    const authorizationHeader =
      req.headers.authorization || "";

    const cookieToken = req.cookies?.jwt
      ? `Bearer ${req.cookies.jwt}`
      : "";

    const token =
      authorizationHeader.startsWith("Bearer ")
        ? authorizationHeader
        : cookieToken;

    if (!token) {
      return res.status(401).json({
        success: false,
        message: "Authentication token required.",
      });
    }

    console.log("🔵 Backend chat controller");
    console.log("📥 Authenticated user:", userId);
    console.log("📥 User role:", req.user?.role);
    console.log(
      `🔵 Calling AI service at ${AI_SERVICE_URL}/chat`
    );

    const aiResponse = await axios.post(
      `${AI_SERVICE_URL}/chat`,
      {
        message,
        userId,
        certificationId,
      },
      {
        headers: {
          Authorization: token,
          "Content-Type": "application/json",
        },
        timeout: AI_REQUEST_TIMEOUT_MS,
      }
    );

    const responseData = aiResponse.data || {};

    const answer =
      typeof responseData === "string"
        ? responseData
        : responseData.answer ||
          responseData.reply ||
          responseData.response ||
          responseData.message ||
          responseData.content;

    if (typeof answer !== "string" || !answer.trim()) {
      console.error(
        "❌ Invalid AI service response:",
        responseData
      );

      return res.status(502).json({
        success: false,
        message: "The AI service returned an empty response.",
      });
    }

    const cleanAnswer = answer.trim();

    // Saving the conversation must never block the AI response.
    try {
      await Conversation.create({
        userId,
        conversationId,
        message,
        response: cleanAnswer,
        createdAt: new Date(),
      });

      console.log("💾 Conversation saved successfully");
    } catch (databaseError) {
      console.error(
        "⚠️ Conversation save failed, but the AI response will still be returned:",
        databaseError?.message || databaseError
      );
    }

    const durationMs = Date.now() - startedAt;

    console.log(
      `✅ Backend received AI response in ${durationMs} ms`
    );

    return res.status(200).json({
      success: true,
      answer: cleanAnswer,
      reply: cleanAnswer,
      response: cleanAnswer,
      message: cleanAnswer,
      conversationId,
      durationMs,
    });
  } catch (error) {
    console.error("❌ Backend chat error:", {
      message: error?.message,
      code: error?.code,
      status: error?.response?.status,
      data: error?.response?.data,
    });

    if (res.headersSent) {
      return;
    }

    if (
      error?.code === "ECONNABORTED" ||
      error?.code === "ETIMEDOUT"
    ) {
      return res.status(504).json({
        success: false,
        message: "The AI service took too long to respond.",
      });
    }

    return res.status(
      error?.response?.status || 503
    ).json({
      success: false,
      message:
        error?.response?.data?.message ||
        error?.response?.data?.details ||
        error?.message ||
        "Chat service error.",
      details: error?.response?.data,
    });
  }
};
