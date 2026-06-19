import axios from "axios";

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || "http://localhost:5000";

const api = axios.create({
  baseURL: API_BASE_URL,
  withCredentials: true,
});

// Ajouter automatiquement le token JWT à chaque requête
api.interceptors.request.use(
  (config) => {
    const token =
      localStorage.getItem("token") ||
      localStorage.getItem("accessToken") ||
      localStorage.getItem("authToken");

    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }

    return config;
  },
  (error) => Promise.reject(error)
);

// Get dashboard statistics
export async function getDashboardStats(range = "week") {
  try {
    const response = await api.get("/dashboard/stats", {
      params: {
        range,
      },
    });

    return response.data;
  } catch (error) {
    console.error(
      "Dashboard API error:",
      error.response?.data || error.message
    );

    if (error.response?.status === 401) {
      throw new Error(
        error.response?.data?.message ||
          "Session expired. Please log in again."
      );
    }

    throw new Error(
      error.response?.data?.message ||
        `Failed to fetch dashboard stats: ${error.message}`
    );
  }
}

// Get emplois du temps for teacher
export async function getEmploisDuTemps() {
  try {
    const response = await api.get("/emplois");
    return response.data;
  } catch (error) {
    console.error(
      "Emplois API error:",
      error.response?.data || error.message
    );

    if (error.response?.status === 401) {
      throw new Error(
        error.response?.data?.message ||
          "Session expired. Please log in again."
      );
    }

    throw new Error(
      error.response?.data?.message ||
        `Failed to fetch emplois du temps: ${error.message}`
    );
  }
}

export default api;

