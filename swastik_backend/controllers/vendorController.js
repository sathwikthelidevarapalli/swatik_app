// controllers/vendorController.js
import asyncHandler from "express-async-handler";
import Vendor from "../models/vendorModel.js";
import generateToken from "../utils/generateToken.js";
import bcrypt from "bcryptjs";
import Booking from "../models/bookingModel.js";

// ------------------------------------
// REGISTER
// ------------------------------------
export const registerVendor = asyncHandler(async (req, res) => {
  const { name, email, password } = req.body;

  const exists = await Vendor.findOne({ email });
  if (exists) return res.status(400).json({ message: "Email already exists" });

  const vendor = await Vendor.create({ name, email, password });

  res.json({
    _id: vendor._id,
    name: vendor.name,
    email: vendor.email,
    token: generateToken(vendor._id),
  });
});

// ------------------------------------
// LOGIN
// ------------------------------------
export const loginVendor = asyncHandler(async (req, res) => {
  const { email, password } = req.body;

  const vendor = await Vendor.findOne({ email });
  if (!vendor) return res.status(404).json({ message: "Vendor not found" });

  const isMatch = await vendor.matchPassword(password);
  if (!isMatch) return res.status(400).json({ message: "Invalid password" });
  // Block login for vendors who are not approved yet
  const status = vendor.applicationStatus || "pending";
  if (status !== "approved") {
    // If rejected, return rejection reason
    if (status === "rejected") {
      return res.status(403).json({ message: vendor.rejectionReason || "Your application was rejected" });
    }

    // For pending applications, suggest retry after up to 48 hours since registration
    let remainingHours = 48;
    try {
      const created = vendor.createdAt ? new Date(vendor.createdAt).getTime() : null;
      if (created) {
        const hoursSince = (Date.now() - created) / (1000 * 60 * 60);
        if (hoursSince < 48) remainingHours = Math.ceil(48 - hoursSince);
        else remainingHours = 48; // keep message consistent if more than 48h passed
      }
    } catch (e) {
      remainingHours = 48;
    }

    return res.status(403).json({ message: `You are not verified yet. Please try again after ${remainingHours} hours.` });
  }

  // Include applicationStatus so frontend can show pending/rejected states
  res.json({
    _id: vendor._id,
    name: vendor.name,
    email: vendor.email,
    applicationStatus: status,
    rejectionReason: vendor.rejectionReason,
    token: generateToken(vendor._id),
  });
});

// ------------------------------------
// GET VENDOR
// ------------------------------------
export const getVendorById = asyncHandler(async (req, res) => {
  const vendor = await Vendor.findById(req.params.id);
  if (!vendor) return res.status(404).json({ message: "Vendor not found" });

  // Sanitize sensitive fields before returning
  const v = vendor.toObject ? vendor.toObject() : vendor;
  delete v.password;

  // Add convenience flags for clients
  const response = {
    ...v,
    isVerified: v.applicationStatus === "approved",
  };

  res.json({ vendor: response });
});

// ------------------------------------
// EDIT PROFILE — FETCH DATA
// ------------------------------------
export const getProfileData = asyncHandler(async (req, res) => {
  const vendor = await Vendor.findById(req.params.id);

  if (!vendor) return res.status(404).json({ message: "Vendor not found" });

  res.json({
    businessName: vendor.businessName || "",
    category: vendor.category || "",
    location: vendor.location || "",
    phone: vendor.phone || "",
    email: vendor.email || "",
    description: vendor.description || "",
  });
});

// ------------------------------------
// EDIT PROFILE — UPDATE
// ------------------------------------
export const updateProfileBasic = asyncHandler(async (req, res) => {
  const vendor = await Vendor.findById(req.params.id);
  if (!vendor) return res.status(404).json({ message: "Vendor not found" });
  // Accept partial updates — only overwrite fields present in the request body
  const { businessName, category, location, phone, email, description } = req.body;

  if (typeof businessName !== "undefined") vendor.businessName = businessName;
  if (typeof category !== "undefined") vendor.category = category;
  if (typeof phone !== "undefined") vendor.phone = phone;
  if (typeof email !== "undefined") vendor.email = email;
  if (typeof description !== "undefined") vendor.description = description;

  // convert "City, State" → city + state (only when location provided and valid)
  if (typeof location === "string" && location.includes(",")) {
    const p = location.split(",");
    vendor.city = p[0].trim();
    vendor.state = p[1].trim();
  }

  await vendor.save();
  res.json({ message: "Profile updated successfully", vendor });
});

// ------------------------------------
// DASHBOARD
// ------------------------------------
export const vendorDashboard = asyncHandler(async (req, res) => {
  const vendorId = req.params.vendorId;

  const vendor = await Vendor.findById(vendorId);
  if (!vendor) return res.status(404).json({ message: "Vendor not found" });

  // Only approved vendors can access dashboard data
  if (vendor.applicationStatus !== "approved") {
    return res.status(403).json({ message: "Vendor not approved yet" });
  }

  const totalBookings = await Booking.countDocuments({ vendor: vendorId });

  const totalEarningsAgg = await Booking.aggregate([
    {
      $match: {
        vendor: vendor._id,
        status: { $in: ["confirmed", "completed"] },
      },
    },
    { $group: { _id: null, total: { $sum: "$amount" } } },
  ]);

  const totalEarnings = totalEarningsAgg[0] ? totalEarningsAgg[0].total : 0;

  const recentBookings = await Booking.find({ vendor: vendorId })
    .sort({ createdAt: -1 })
    .limit(6);

  res.json({
    totalBookings,
    totalEarnings,
    avgRating: 0,
    profileViews: 0,
    recentBookings,
  });
});
// ------------------------------------
// GET ALL APPROVED VENDORS (For Customer Home Screen)
// ------------------------------------
export const getVendors = asyncHandler(async (req, res) => {
  // Accept either `location` or `city` query parameter (clients may send either)
  const location = (req.query.location || req.query.city || "").toString(); // e.g., "Hyderabad"
  const category = req.query.category; // optional category filter (from client)

  let filter = { applicationStatus: "approved" };

  // Build a flexible location filter: match city OR state OR legacy 'location' field (case-insensitive, partial)
  if (location && location.trim() !== "") {
    const re = new RegExp(location.trim(), "i");
    filter.$or = [{ city: re }, { state: re }, { location: re }];
  }

  if (category) {
    // Allow partial / case-insensitive matches for category
    filter.category = { $regex: new RegExp(category, "i") };
  }

  console.log('[GET VENDORS] filter =', JSON.stringify(filter));

  const vendors = await Vendor.find(filter);
  console.log('[GET VENDORS] found =', vendors.length);

  const formatted = vendors.map((v) => ({
    id: v._id,
    name: v.businessName || v.name,
    category: v.category || "General",
    rating: 4.5, // You can update later
    reviews: 100, // You can update later
    price: v.packages?.[0]?.price || 0,
    location: v.location,
    imageUrl:
      v.gallery && v.gallery[0] && v.gallery[0].url
        ? `${req.protocol}://${req.get("host")}/${v.gallery[0].url}`
        : null,
    isVerified: v.applicationStatus === "approved",
  }));

  res.json({ vendors: formatted });
});
