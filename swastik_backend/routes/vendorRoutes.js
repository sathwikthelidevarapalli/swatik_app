import express from "express";
import upload from "../config/multerConfig.js";
import {
  registerVendor,
  loginVendor,
  getVendorById,
  getProfileData,
  updateProfileBasic,
  vendorDashboard,
} from "../controllers/vendorController.js";

import Vendor from "../models/vendorModel.js";
import Booking from "../models/bookingModel.js";

const router = express.Router();

/* =====================================================
   1️⃣ AUTH
===================================================== */
router.post("/register", registerVendor);
router.post("/login", loginVendor);

/* =====================================================
   2️⃣ BASIC PROFILE
===================================================== */
router.get("/profile/:id", getProfileData);
router.put("/profile/basic/:id", updateProfileBasic);
// Compatibility: some frontends call PUT /profile/:id
router.put("/profile/:id", updateProfileBasic);
// Compatibility: accept profile update with id in body
router.put("/profile", async (req, res) => {
  const id = req.body.id || req.body.vendorId;
  if (!id) return res.status(400).json({ message: "Missing vendor id" });
  // forward to controller
  req.params.id = id;
  return updateProfileBasic(req, res);
});

/* =====================================================
   3️⃣ DASHBOARD
===================================================== */
router.get("/dashboard/:vendorId", vendorDashboard);

/* =====================================================
   4️⃣ GALLERY
===================================================== */

// GET gallery photos
router.get("/gallery/:vendorId", async (req, res) => {
  try {
    const vendor = await Vendor.findById(req.params.vendorId);
    if (!vendor) return res.status(404).json({ message: "Vendor not found" });
    const host = `${req.protocol}://${req.get("host")}`;
    const photos = (vendor.gallery || []).map((p) => ({
      ...p._doc,
      url: p.url ? `${host}/${p.url}` : p.url,
    }));
    res.json({ photos });
  } catch (e) {
    console.error("GALLERY GET ERROR:", e);
    res.status(500).json({ message: "Gallery error" });
  }
});

// UPLOAD photo
router.post(
  "/gallery/upload/:vendorId",
  upload.single("photo"),
  async (req, res) => {
    try {
      if (!req.file)
        return res.status(400).json({ message: "No file uploaded" });

      const vendor = await Vendor.findById(req.params.vendorId);
      if (!vendor) return res.status(404).json({ message: "Vendor not found" });

      const relativePath = `uploads/gallery/${req.file.filename}`;
      vendor.gallery.push({ url: relativePath });

      await vendor.save();

      const fullUrl = `${req.protocol}://${req.get("host")}/${relativePath}`;

      res.json({
        message: "Uploaded successfully",
        url: fullUrl,
        photos: vendor.gallery.map((p) => ({ url: p.url ? `${req.protocol}://${req.get("host")}/${p.url}` : p.url })),
      });
    } catch (e) {
      console.error("GALLERY UPLOAD ERROR:", e);
      res.status(500).json({
        message: "Upload failed",
        error: e.message,
      });
    }
  }
);

// DELETE photo
router.delete("/gallery/delete/:photoId", async (req, res) => {
  try {
    const vendor = await Vendor.findOne({ "gallery._id": req.params.photoId });
    if (!vendor) return res.status(404).json({ message: "Vendor not found" });

    vendor.gallery = vendor.gallery.filter(
      (p) => p._id.toString() !== req.params.photoId
    );

    await vendor.save();
    res.json({ message: "Deleted" });
  } catch (e) {
    console.error("GALLERY DELETE ERROR:", e);
    res.status(500).json({ message: "Delete failed" });
  }
});

/* =====================================================
   5️⃣ PRICING PACKAGES
===================================================== */

// GET packages
router.get("/packages/:vendorId", async (req, res) => {
  const vendor = await Vendor.findById(req.params.vendorId);
  res.json({ packages: vendor.packages || [] });
});

// ADD package
router.post("/packages/:vendorId", async (req, res) => {
  try {
    const vendor = await Vendor.findById(req.params.vendorId);

    if (!vendor.packages) vendor.packages = [];
    vendor.packages.push(req.body);

    await vendor.save();

    res.json({ message: "Package added", packages: vendor.packages });
  } catch (e) {
    console.error("PACKAGE ADD ERROR:", e);
    res.status(500).json({ message: "Failed" });
  }
});

// DELETE package
router.delete("/packages/:packageId", async (req, res) => {
  const vendor = await Vendor.findOne({ "packages._id": req.params.packageId });
  if (!vendor) return res.status(404).json({ message: "Vendor not found" });

  vendor.packages = vendor.packages.filter(
    (p) => p._id.toString() !== req.params.packageId
  );

  await vendor.save();
  res.json({ message: "Deleted" });
});

/* =====================================================
   6️⃣ VERIFICATION DOCUMENTS
===================================================== */

router.get("/verification/:vendorId", async (req, res) => {
  const vendor = await Vendor.findById(req.params.vendorId);
  if (!vendor) return res.status(404).json({ message: "Vendor not found" });

  const host = `${req.protocol}://${req.get("host")}`;
  const ver = { ...(vendor.verification || {}) };
  if (ver.businessLicense && ver.businessLicense.file)
    ver.businessLicense.file = `${host}/${ver.businessLicense.file}`;
  if (ver.gst && ver.gst.file) ver.gst.file = `${host}/${ver.gst.file}`;
  if (ver.addressProof && ver.addressProof.file) ver.addressProof.file = `${host}/${ver.addressProof.file}`;
  if (ver.additionalDocs && Array.isArray(ver.additionalDocs))
    ver.additionalDocs = ver.additionalDocs.map((f) => (f ? `${host}/${f}` : f));

  res.json(ver);
});

// Upload document
router.post(
  "/verification/upload/:vendorId/:docType",
  upload.single("file"),
  async (req, res) => {
    try {
      if (!req.file)
        return res.status(400).json({ message: "No document uploaded" });

      const vendor = await Vendor.findById(req.params.vendorId);
      const relativePath = `uploads/documents/${req.file.filename}`;

      vendor.verification[req.params.docType] = {
        status: "submitted",
        file: relativePath,
      };

      await vendor.save();

      const full = `${req.protocol}://${req.get("host")}/${relativePath}`;
      res.json({ message: "Document uploaded", file: full });
    } catch (e) {
      console.error("VERIFICATION UPLOAD ERROR:", e);
      res.status(500).json({ message: "Upload failed" });
    }
  }
);

// Compatibility endpoints used by frontend registration wizard
// POST /api/vendors/register/documents/:vendorId
router.post(
  "/register/documents/:vendorId",
  upload.any(),
  async (req, res) => {
    try {
      console.log('[UPLOAD] documents handler entered for vendorId=', req.params.vendorId);
      console.log('[UPLOAD] files count=', req.files ? req.files.length : 0);
      if (!req.files || req.files.length === 0)
        return res.status(400).json({ message: "No document uploaded" });

      const vendor = await Vendor.findById(req.params.vendorId);
      if (!vendor) return res.status(404).json({ message: "Vendor not found" });

      if (!vendor.verification) vendor.verification = {};
      if (!vendor.verification.additionalDocs) vendor.verification.additionalDocs = [];

      const files = req.files.map((f) => `uploads/documents/${f.filename}`);
      vendor.verification.additionalDocs.push(...files);

      await vendor.save();

      const host = `${req.protocol}://${req.get("host")}`;
      const fullFiles = files.map((p) => `${host}/${p}`);
      console.log('[UPLOAD] documents saved:', fullFiles);
      res.json({ message: "Documents uploaded", files: fullFiles });
    } catch (e) {
      console.error("REGISTER DOCUMENTS UPLOAD ERROR:", e);
      res.status(500).json({ message: "Upload failed", error: e.message });
    }
  }
);

// Also accept PUT for documents (some clients use PUT)
router.put(
  "/register/documents/:vendorId",
  upload.any(),
  async (req, res) => {
    try {
      console.log('[UPLOAD] documents (PUT) handler entered for vendorId=', req.params.vendorId);
      console.log('[UPLOAD] files count=', req.files ? req.files.length : 0);
      if (!req.files || req.files.length === 0)
        return res.status(400).json({ message: "No document uploaded" });

      const vendor = await Vendor.findById(req.params.vendorId);
      if (!vendor) return res.status(404).json({ message: "Vendor not found" });

      if (!vendor.verification) vendor.verification = {};
      if (!vendor.verification.additionalDocs) vendor.verification.additionalDocs = [];

      const files = req.files.map((f) => `uploads/documents/${f.filename}`);
      vendor.verification.additionalDocs.push(...files);

      await vendor.save();
      const host = `${req.protocol}://${req.get("host")}`;
      const fullFiles = files.map((p) => `${host}/${p}`);
      console.log('[UPLOAD] documents (PUT) saved:', fullFiles);
      res.json({ message: "Documents uploaded", files: fullFiles });
    } catch (e) {
      console.error("REGISTER DOCUMENTS UPLOAD ERROR:", e);
      res.status(500).json({ message: "Upload failed", error: e.message });
    }
  }
);

// Compatibility: POST /api/vendors/register/documents (vendorId in body)
router.post("/register/documents", upload.any(), async (req, res) => {
  try {
    const vendorId = req.body.vendorId || req.body.id;
    if (!vendorId) return res.status(400).json({ message: "Missing vendorId in body" });

    if (!req.files || req.files.length === 0)
      return res.status(400).json({ message: "No document uploaded" });

    const vendor = await Vendor.findById(vendorId);
    if (!vendor) return res.status(404).json({ message: "Vendor not found" });

    if (!vendor.verification) vendor.verification = {};
    if (!vendor.verification.additionalDocs) vendor.verification.additionalDocs = [];

    const files = req.files.map((f) => `uploads/documents/${f.filename}`);
    vendor.verification.additionalDocs.push(...files);

    await vendor.save();

    res.json({ message: "Documents uploaded", files });
  } catch (e) {
    console.error("REGISTER DOCUMENTS UPLOAD ERROR:", e);
    res.status(500).json({ message: "Upload failed", error: e.message });
  }
});

// POST /api/vendors/register/portfolio/:vendorId
router.post(
  "/register/portfolio/:vendorId",
  upload.any(),
  async (req, res) => {
    try {
      console.log('[UPLOAD] portfolio handler entered for vendorId=', req.params.vendorId);
      console.log('[UPLOAD] files count=', req.files ? req.files.length : 0);
      if (!req.files || req.files.length === 0)
        return res.status(400).json({ message: "No portfolio file uploaded" });

      const vendor = await Vendor.findById(req.params.vendorId);
      if (!vendor) return res.status(404).json({ message: "Vendor not found" });

      if (!vendor.portfolio) vendor.portfolio = [];

      const files = req.files.map((f) => ({ url: `uploads/portfolio/${f.filename}` }));
      vendor.portfolio.push(...files);

      await vendor.save();

      const host = `${req.protocol}://${req.get("host")}`;
      const full = files.map((f) => `${host}/${f.url}`);
      console.log('[UPLOAD] portfolio saved:', full);
      res.json({ message: "Portfolio uploaded", files: full });
    } catch (e) {
      console.error("REGISTER PORTFOLIO UPLOAD ERROR:", e);
      res.status(500).json({ message: "Upload failed", error: e.message });
    }
  }
);
 

// Compatibility: POST /api/vendors/register/portfolio (vendorId in body)
router.post("/register/portfolio", upload.any(), async (req, res) => {
  try {
    const vendorId = req.body.vendorId || req.body.id;
    if (!vendorId) return res.status(400).json({ message: "Missing vendorId in body" });

    if (!req.files || req.files.length === 0)
      return res.status(400).json({ message: "No portfolio file uploaded" });

    const vendor = await Vendor.findById(vendorId);
    if (!vendor) return res.status(404).json({ message: "Vendor not found" });

    if (!vendor.portfolio) vendor.portfolio = [];

    const files = req.files.map((f) => ({ url: `uploads/portfolio/${f.filename}` }));
    vendor.portfolio.push(...files);

    await vendor.save();

    res.json({ message: "Portfolio uploaded", files: files.map((f) => f.url) });
  } catch (e) {
    console.error("REGISTER PORTFOLIO UPLOAD ERROR:", e);
    res.status(500).json({ message: "Upload failed", error: e.message });
  }
});

// Also accept PUT for portfolio (some clients use PUT)
router.put(
  "/register/portfolio/:vendorId",
  upload.any(),
  async (req, res) => {
    try {
      console.log('[UPLOAD] portfolio (PUT) handler entered for vendorId=', req.params.vendorId);
      console.log('[UPLOAD] files count=', req.files ? req.files.length : 0);
      if (!req.files || req.files.length === 0)
        return res.status(400).json({ message: "No portfolio file uploaded" });

      const vendor = await Vendor.findById(req.params.vendorId);
      if (!vendor) return res.status(404).json({ message: "Vendor not found" });

      if (!vendor.portfolio) vendor.portfolio = [];

      const files = req.files.map((f) => ({ url: `uploads/portfolio/${f.filename}` }));
      vendor.portfolio.push(...files);

      await vendor.save();

      const host = `${req.protocol}://${req.get("host")}`;
      const full = files.map((f) => `${host}/${f.url}`);
      console.log('[UPLOAD] portfolio (PUT) saved:', full);
      res.json({ message: "Portfolio uploaded", files: full });
    } catch (e) {
      console.error("REGISTER PORTFOLIO UPLOAD ERROR:", e);
      res.status(500).json({ message: "Upload failed", error: e.message });
    }
  }
);

// Compatibility: PUT /api/vendors/register/portfolio (vendorId in body)
router.put("/register/portfolio", upload.any(), async (req, res) => {
  try {
    const vendorId = req.body.vendorId || req.body.id;
    if (!vendorId) return res.status(400).json({ message: "Missing vendorId in body" });

    if (!req.files || req.files.length === 0)
      return res.status(400).json({ message: "No portfolio file uploaded" });

    const vendor = await Vendor.findById(vendorId);
    if (!vendor) return res.status(404).json({ message: "Vendor not found" });

    if (!vendor.portfolio) vendor.portfolio = [];

    const files = req.files.map((f) => ({ url: `uploads/portfolio/${f.filename}` }));
    vendor.portfolio.push(...files);

    await vendor.save();

    const host = `${req.protocol}://${req.get("host")}`;
    const full = files.map((f) => `${host}/${f.url}`);
    res.json({ message: "Portfolio uploaded", files: full });
  } catch (e) {
    console.error("REGISTER PORTFOLIO UPLOAD ERROR:", e);
    res.status(500).json({ message: "Upload failed", error: e.message });
  }
});

// Finalize registration (compatibility endpoint used by frontend)
// POST /api/vendors/register/submit/:vendorId
router.post("/register/submit/:vendorId", async (req, res) => {
  try {
    const vendor = await Vendor.findById(req.params.vendorId);
    if (!vendor) return res.status(404).json({ message: "Vendor not found" });

    // Accept a flexible body — update what is provided
    const {
      gstin,
      services,
      businessName,
      ownerName,
      experience,
      description,
      phone,
      email,
      location,
    } = req.body;

    if (gstin) vendor.gstin = gstin;
    if (services) {
      try {
        vendor.services = typeof services === 'string' ? JSON.parse(services) : services;
      } catch (_) {
        vendor.services = services;
      }
    }
    if (businessName) vendor.businessName = businessName;
    if (ownerName) vendor.ownerName = ownerName;
    if (experience) vendor.experience = experience;
    if (description) vendor.description = description;
    if (phone) vendor.phone = phone;
    if (email) vendor.email = email;
    if (location && location.includes(",")) {
      const p = location.split(",");
      vendor.city = p[0].trim();
      vendor.state = p[1].trim();
    }

    vendor.applicationStatus = "submitted";

    await vendor.save();

    res.json({ message: "Registration submitted", vendor });
  } catch (e) {
    console.error("REGISTER SUBMIT ERROR:", e);
    res.status(500).json({ message: "Submit failed", error: e.message });
  }
});

// Compatibility: POST /api/vendors/register/submit (vendorId in body)
router.post("/register/submit", async (req, res) => {
  try {
    const vendorId = req.body.vendorId || req.body.id;
    if (!vendorId) return res.status(400).json({ message: "Missing vendorId in body" });
    req.params.vendorId = vendorId;
    return router.handle(req, res);
  } catch (e) {
    console.error("REGISTER SUBMIT (body) ERROR:", e);
    res.status(500).json({ message: "Submit failed", error: e.message });
  }
});

// ----------------------------
// Compatibility: Business details (Step 1)
// Accepts PUT/POST to /register/business/:vendorId or /register/business with vendorId in body
// ----------------------------
async function handleBusinessUpdate(req, res) {
  try {
    const vendorId = req.params.vendorId || req.body.vendorId || req.body.id;
    if (!vendorId) return res.status(400).json({ message: "Missing vendor id" });

    const vendor = await Vendor.findById(vendorId);
    if (!vendor) return res.status(404).json({ message: "Vendor not found" });

    const { businessName, ownerName, category, experience, description } = req.body;
    if (businessName) vendor.businessName = businessName;
    if (ownerName) vendor.ownerName = ownerName;
    if (category) vendor.category = category;
    if (experience) vendor.experience = experience;
    if (description) vendor.description = description;

    await vendor.save();
    res.json({ message: "Business updated", vendor });
  } catch (e) {
    console.error("BUSINESS UPDATE ERROR:", e);
    res.status(500).json({ message: "Failed", error: e.message });
  }
}

router.put("/register/business/:vendorId", (req, res) => handleBusinessUpdate(req, res));
router.post("/register/business/:vendorId", (req, res) => handleBusinessUpdate(req, res));
router.put("/register/business", (req, res) => handleBusinessUpdate(req, res));
router.post("/register/business", (req, res) => handleBusinessUpdate(req, res));

// Also accept /register/details as an alias used by some clients
router.put("/register/details/:vendorId", (req, res) => handleBusinessUpdate(req, res));
router.post("/register/details/:vendorId", (req, res) => handleBusinessUpdate(req, res));
router.put("/register/details", (req, res) => handleBusinessUpdate(req, res));
router.post("/register/details", (req, res) => handleBusinessUpdate(req, res));

// ----------------------------
// Compatibility: Contact details (Step 2)
// Accepts PUT/POST to /register/contact/:vendorId or /register/contact with vendorId in body
// ----------------------------
async function handleContactUpdate(req, res) {
  try {
    const vendorId = req.params.vendorId || req.body.vendorId || req.body.id;
    if (!vendorId) return res.status(400).json({ message: "Missing vendor id" });

    const vendor = await Vendor.findById(vendorId);
    if (!vendor) return res.status(404).json({ message: "Vendor not found" });

    const { phone, email, address, city, state, pincode, location } = req.body;
    if (phone) vendor.phone = phone;
    if (email) vendor.email = email;
    if (address) vendor.address = address;
    if (city) vendor.city = city;
    if (state) vendor.state = state;
    if (pincode) vendor.pincode = pincode;
    // some frontends send location as "City, State"
    if (location && typeof location === 'string' && location.includes(",")) {
      const p = location.split(",");
      vendor.city = p[0].trim();
      vendor.state = p[1].trim();
    }

    await vendor.save();
    res.json({ message: "Contact updated", vendor });
  } catch (e) {
    console.error("CONTACT UPDATE ERROR:", e);
    res.status(500).json({ message: "Failed", error: e.message });
  }
}

router.put("/register/contact/:vendorId", (req, res) => handleContactUpdate(req, res));
router.post("/register/contact/:vendorId", (req, res) => handleContactUpdate(req, res));
router.put("/register/contact", (req, res) => handleContactUpdate(req, res));
router.post("/register/contact", (req, res) => handleContactUpdate(req, res));

/* =====================================================
   7️⃣ AVAILABILITY
===================================================== */

// Get unavailable dates
router.get("/availability/:vendorId", async (req, res) => {
  const vendor = await Vendor.findById(req.params.vendorId);
  res.json({ unavailable: vendor.unavailable || [] });
});

// Mark Unavailable
router.post("/availability/:vendorId", async (req, res) => {
  const vendor = await Vendor.findById(req.params.vendorId);
  vendor.unavailable.push(req.body.date);
  await vendor.save();

  res.json({ message: "Added", unavailable: vendor.unavailable });
});

// Mark Available (delete)
router.delete("/availability/:vendorId/:date", async (req, res) => {
  const vendor = await Vendor.findById(req.params.vendorId);

  vendor.unavailable = vendor.unavailable.filter(
    (d) => d !== req.params.date
  );

  await vendor.save();
  res.json({ message: "Removed", unavailable: vendor.unavailable });
});

/* =====================================================
   8️⃣ BOOKED DATES (FOR CALENDAR)
===================================================== */

router.get("/booked/:vendorId", async (req, res) => {
  try {
    const bookings = await Booking.find({
      vendor: req.params.vendorId,
      status: { $in: ["confirmed", "completed"] },
    }).select("eventDate");

    const bookedDates = bookings.map((b) =>
      b.eventDate.toISOString().substring(0, 10)
    );

    res.json({ booked: bookedDates });
  } catch (e) {
    console.error("BOOKED DATE ERROR:", e);
    res.status(500).json({ message: "Failed to fetch booked dates" });
  }
});

/* =====================================================
   9️⃣ DEFAULT GET VENDOR
===================================================== */
router.get("/:id", getVendorById);

export default router;
