// controllers/earningsController.js
import asyncHandler from "express-async-handler";
import Earnings from "../models/earningsModel.js";

// ------------------------------------------
// GET TOTAL EARNINGS + AI INSIGHTS
// ------------------------------------------
export const getVendorEarnings = asyncHandler(async (req, res) => {
  const vendorId = req.params.vendorId;

  const records = await Earnings.find({ vendorId });

  let totalEarnings = 0;
  let last6Months = [];

  records.forEach((r) => {
    totalEarnings += r.amount;
    last6Months.push(r.amount);
  });

  const growthRate =
    last6Months.length >= 2
      ? (((last6Months[last6Months.length - 1] -
          last6Months[last6Months.length - 2]) /
          last6Months[last6Months.length - 2]) *
        100)
      : 0;

  res.json({
    totalEarnings,
    growthRate,
    last6Months,
  });
});

// ------------------------------------------
// RECENT TRANSACTIONS
// ------------------------------------------
export const getTransactions = asyncHandler(async (req, res) => {
  const vendorId = req.params.vendorId;

  const records = await Earnings.find({ vendorId });

  let allTx = [];
  records.forEach((r) => {
    allTx.push(...r.transactions);
  });

  // sort latest first
  allTx = allTx.sort((a, b) => new Date(b.date) - new Date(a.date));

  res.json(allTx);
});
