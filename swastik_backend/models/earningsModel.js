// models/earningsModel.js
import mongoose from "mongoose";

const earningsSchema = mongoose.Schema(
  {
    vendorId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Vendor",
      required: true,
    },

    month: { type: String, required: true }, // e.g., "2024-11"
    amount: { type: Number, default: 0 },

    transactions: [
      {
        customerName: String,
        amount: Number,
        date: String,
        status: String, // completed | pending | failed
      },
    ],
  },
  { timestamps: true }
);

const Earnings = mongoose.model("Earnings", earningsSchema);
export default Earnings;
