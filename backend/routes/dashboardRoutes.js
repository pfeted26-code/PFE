const express = require("express");
const router = express.Router();

const dashboardController = require("../controllers/dashboardController");
const {
  requireAuthUser,
} = require("../middlewares/authMiddlewares");

// GET /dashboard/stats
router.get(
  "/stats",
  requireAuthUser,
  dashboardController.getDashboardStats
);

module.exports = router;

