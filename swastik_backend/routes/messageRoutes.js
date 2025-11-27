import express from "express";
import { sendMessage, getVendorMessages, getChat } from "../controllers/messageController.js";

const router = express.Router();

router.post("/send", sendMessage);
router.get("/vendor/:vendorId", getVendorMessages);
router.get("/chat/:vendorId/:customerId", getChat);

export default router;
