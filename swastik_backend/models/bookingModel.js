// models/bookingModel.js
import mongoose from "mongoose";

const bookingSchema = mongoose.Schema(
  {
    vendor: { type: mongoose.Schema.Types.ObjectId, ref: "Vendor", required: true },
    customerName: { type: String, required: true },
    customerEmail: { type: String },
    customerPhone: { type: String },
    eventType: { type: String, required: true },
    packageName: { type: String },
    date: { type: String }, // keep string for now, or use Date if you prefer
    time: { type: String },
    guests: { type: Number },
    amount: { type: Number, default: 0 },
    status: {
      type: String,
      enum: ["new", "confirmed", "completed", "rejected"],
      default: "new",
    },
    rejectionReason: { type: String },
  },
  { timestamps: true }
);

const Booking = mongoose.model("Booking", bookingSchema);
export default Booking;
