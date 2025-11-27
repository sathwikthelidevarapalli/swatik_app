import express from "express";
import dotenv from "dotenv";
import cors from "cors";
import bodyParser from "body-parser";
import path from "path";
import { fileURLToPath } from "url";

import connectDB from "./config/db.js";

// ROUTES
import vendorRoutes from "./routes/vendorRoutes.js";
import userRoutes from "./routes/userRoutes.js";
import adminRoutes from "./routes/adminRoutes.js";
import bookingRoutes from "./routes/bookingRoutes.js";
import messageRoutes from "./routes/messageRoutes.js";
import earningsRoutes from "./routes/earningsRoutes.js";

dotenv.config();

// Path fix for ES Modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Express App
const app = express();

// Connect DB
connectDB();

// Middleware
app.use(cors());
app.use(express.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Request logger (helps debug mobile client 404s)
app.use((req, res, next) => {
  try {
    console.log(`\n[REQUEST] ${new Date().toISOString()} ${req.method} ${req.originalUrl}`);
    console.log("Headers:", JSON.stringify(req.headers));
    // Only print body for non-multipart requests
    const ct = req.headers["content-type"] || "";
    if (!ct.includes("multipart/form-data")) {
      console.log("Body:", JSON.stringify(req.body));
    } else {
      console.log("Body: <multipart/form-data - not logged>");
    }
  } catch (e) {
    console.error("Request logger error:", e);
  }
  next();
});

// Serve uploads folder (IMPORTANT)
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

// API ROUTES
app.use("/api/vendors", vendorRoutes);
app.use("/api/users", userRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/bookings", bookingRoutes);
app.use("/api/messages", messageRoutes);
app.use("/api/earnings", earningsRoutes);

// Simple ping for mobile/dev connectivity checks
app.get("/api/ping", (req, res) => {
  res.json({ ok: true, time: new Date().toISOString() });
});

// ROOT
app.get("/", (req, res) => {
  res.json({ message: "🚀 Swastik Backend API is running..." });
});

// 404
app.use((req, res) => {
  res.status(404).json({
    message: `API endpoint not found: ${req.originalUrl}`,
  });
});

// Global Error Handler
app.use((err, req, res, next) => {
  console.error("Server Error:", err.stack || err);
  res.status(500).json({ message: err.message || "Server Error" });
});

// Start Server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () =>
  console.log(`🚀 Server running on http://localhost:${PORT}`)
);