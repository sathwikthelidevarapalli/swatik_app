// routes/earningsRoutes.js
import express from "express";
import {
  getVendorEarnings,
  getTransactions,
} from "../controllers/earningsController.js";

const router = express.Router();

router.get("/:vendorId", getVendorEarnings);
router.get("/transactions/:vendorId", getTransactions);

export default router;
