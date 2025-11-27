// controllers/bookingController.js
import asyncHandler from "express-async-handler";
import Booking from "../models/bookingModel.js";
import Vendor from "../models/vendorModel.js";

// Create booking (customer action)
export const createBooking = asyncHandler(async (req, res) => {
  const {
    vendor,
    customerName,
    customerEmail,
    customerPhone,
    eventType,
    packageName,
    date,
    time,
    guests,
    amount,
  } = req.body;

  const vendorExists = await Vendor.findById(vendor);
  if (!vendorExists) return res.status(404).json({ message: "Vendor not found" });

  // Prevent booking against vendors who are not approved
  if (vendorExists.applicationStatus !== "approved") {
    return res.status(400).json({ message: "Vendor is not available for booking" });
  }

  const booking = await Booking.create({
    vendor,
    customerName,
    customerEmail,
    customerPhone,
    eventType,
    packageName,
    date,
    time,
    guests,
    amount,
    status: "new",
  });

  res.status(201).json({ booking });
});

// Get bookings for a vendor (with optional status filter)
export const getBookingsForVendor = asyncHandler(async (req, res) => {
  const { vendorId } = req.params;
  const { status } = req.query; // optional

  const query = { vendor: vendorId };
  if (status) query.status = status;

  const bookings = await Booking.find(query).sort({ createdAt: -1 });
  res.json({ bookings });
});

// Update booking status (accept / reject / complete)
export const updateBookingStatus = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { status, reason } = req.body;

  const booking = await Booking.findById(id);
  if (!booking) return res.status(404).json({ message: "Booking not found" });

  booking.status = status;
  if (status === "rejected") booking.rejectionReason = reason || "";
  if (status !== "rejected") booking.rejectionReason = undefined;

  await booking.save();
  res.json({ message: "Booking updated", booking });
});

// Optional: get single booking
export const getBookingById = asyncHandler(async (req, res) => {
  const booking = await Booking.findById(req.params.id);
  if (!booking) return res.status(404).json({ message: "Booking not found" });
  res.json({ booking });
});
