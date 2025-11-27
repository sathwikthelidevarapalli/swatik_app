// routes/adminRoutes.js
import express from "express";
import {
  adminLogin,
  getAllVendors,
  approveVendor,
  rejectVendor,
} from "../controllers/adminController.js";

const router = express.Router();

router.post("/login", adminLogin);
router.get("/vendors", getAllVendors);
router.put("/vendors/:id/approve", approveVendor);
router.put("/vendors/:id/reject", rejectVendor);

export default router;
