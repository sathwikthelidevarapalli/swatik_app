// controllers/adminController.js
import asyncHandler from "express-async-handler";
import Vendor from "../models/vendorModel.js";
import dotenv from "dotenv";
dotenv.config();

// ADMIN LOGIN: uses .env ADMIN_EMAIL and ADMIN_PASSWORD
export const adminLogin = asyncHandler(async (req, res) => {
  const { email, password } = req.body;

  if (!process.env.ADMIN_EMAIL || !process.env.ADMIN_PASSWORD) {
    return res.status(500).json({ message: "Admin credentials not configured on server." });
  }

  if (email !== process.env.ADMIN_EMAIL || password !== process.env.ADMIN_PASSWORD) {
    return res.status(401).json({ message: "Invalid admin credentials" });
  }

  // simple response — you can return a token if you want later
  res.json({
    message: "Admin login successful",
    admin: { email },
  });
});

// GET ALL VENDORS
export const getAllVendors = asyncHandler(async (req, res) => {
  const vendors = await Vendor.find().sort({ createdAt: -1 });

  // Build absolute URLs for thumbnail image so admin app can display them
  const host = `${req.protocol}://${req.get("host")}`;
  const formatted = vendors.map((v) => {
    const obj = v.toObject ? v.toObject() : v;
    obj.imageUrl = obj.gallery && obj.gallery[0] && obj.gallery[0].url
      ? `${host}/${obj.gallery[0].url}`
      : null;
    return obj;
  });

  res.json({ vendors: formatted });
});

// APPROVE VENDOR — no email, just set status
export const approveVendor = asyncHandler(async (req, res) => {
  const vendor = await Vendor.findById(req.params.id);
  if (!vendor) return res.status(404).json({ message: "Vendor not found" });

  vendor.applicationStatus = "approved";
  vendor.rejectionReason = undefined;
  await vendor.save();

  res.json({ message: "Vendor approved", vendor });
});

// REJECT VENDOR — store reason
export const rejectVendor = asyncHandler(async (req, res) => {
  const vendor = await Vendor.findById(req.params.id);
  if (!vendor) return res.status(404).json({ message: "Vendor not found" });

  const { reason } = req.body;
  vendor.applicationStatus = "rejected";
  vendor.rejectionReason = reason || "No reason provided";
  await vendor.save();

  res.json({ message: "Vendor rejected", vendor });
});
