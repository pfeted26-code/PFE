// frontend/src/services/chatService.js
import axios from "axios";

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL ||
  "http://localhost:5000";

const AI_SERVICE_URL =
  import.meta.env.VITE_AI_SERVICE_URL ||
  "http://localhost:7000";

const CHAT_TIMEOUT_MS = 180000;

export async function sendChatMessage(
  message,
  userId,
  conversationId = null
) {
  const cleanMessage = String(message || "").trim();

  if (!cleanMessage) {
    throw new Error("Message is required.");
  }

  try {
    const response = await axios.post(
      `${API_BASE_URL}/chat`,
      {
        message: cleanMessage,
        userId,
        conversationId,
      },
      {
        withCredentials: true,
        timeout: CHAT_TIMEOUT_MS,
      }
    );

    console.log(
      "✅ chatService received:",
      response.data
    );

    return response.data;
  } catch (error) {
    console.error("❌ sendChatMessage error:", {
      code: error?.code,
      status: error?.response?.status,
      data: error?.response?.data,
      message: error?.message,
    });

    if (
      error?.code === "ECONNABORTED" ||
      error?.code === "ETIMEDOUT"
    ) {
      throw new Error(
        "The AI model took too long to respond."
      );
    }

    throw new Error(
      error?.response?.data?.message ||
        error?.response?.data?.details ||
        error?.response?.data?.error ||
        error?.message ||
        "Failed to send the chat message."
    );
  }
}

export async function uploadFile(file) {
  if (!file) {
    throw new Error("A file is required.");
  }

  try {
    const formData = new FormData();
    formData.append("file", file);

    const response = await axios.post(
      `${AI_SERVICE_URL}/chat/upload`,
      formData,
      {
        headers: {
          "Content-Type": "multipart/form-data",
        },
        withCredentials: true,
        timeout: CHAT_TIMEOUT_MS,
      }
    );

    return response.data;
  } catch (error) {
    throw new Error(
      error?.response?.data?.message ||
        error?.response?.data?.details ||
        error?.message ||
        "Failed to upload the file."
    );
  }
}
