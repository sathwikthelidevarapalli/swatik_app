// routes/bookingRoutes.js
import express from "express";
import {
  createBooking,
  getBookingsForVendor,
  updateBookingStatus,
  getBookingById,
} from "../controllers/bookingController.js";

const router = express.Router();

// create booking (public / customer)
router.post("/", createBooking);

// get vendor bookings (optionally ?status=new|confirmed|completed)
router.get("/vendor/:vendorId", getBookingsForVendor);

// get single booking
router.get("/:id", getBookingById);

// update status
router.put("/:id/status", updateBookingStatus);

export default router;
