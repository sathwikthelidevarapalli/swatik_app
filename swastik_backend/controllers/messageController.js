import Message from "../models/messageModel.js";
import User from "../models/user.js";
import Vendor from "../models/vendorModel.js";

// -------------------------
// SEND MESSAGE
// -------------------------
export const sendMessage = async (req, res) => {
  try {
    const msg = await Message.create({
      vendorId: req.body.vendorId,
      customerId: req.body.customerId,
      sender: req.body.sender,
      message: req.body.message,
    });

    res.status(201).json(msg);
  } catch (e) {
    res.status(500).json({ message: "Error sending message", error: e.message });
  }
};

// -------------------------
// GET ALL CONVERSATIONS FOR VENDOR
// -------------------------
export const getVendorMessages = async (req, res) => {
  try {
    const { vendorId } = req.params;

    const messages = await Message.find({ vendorId }).sort({ createdAt: -1 });

    const grouped = {};

    for (const msg of messages) {
      const cid = msg.customerId;

      if (!grouped[cid]) {
        const customer = await User.findById(cid);

        grouped[cid] = {
          customerId: cid,
          customerName: customer?.name ?? "Customer",
          eventType: customer?.eventType ?? "",
          lastMessage: msg.message,
          unreadCount: 0,
          lastTime: msg.createdAt,
        };
      }

      if (msg.sender === "customer" && !msg.isRead) {
        grouped[cid].unreadCount++;
      }
    }

    res.json(Object.values(grouped));
  } catch (e) {
    res.status(500).json({ message: "Error fetching messages", error: e.message });
  }
};

// -------------------------
// GET FULL CHAT
// -------------------------
export const getChat = async (req, res) => {
  try {
    const { vendorId, customerId } = req.params;

    const chat = await Message.find({ vendorId, customerId }).sort({ createdAt: 1 });

    res.json(chat);
  } catch (e) {
    res.status(500).json({ message: "Error fetching chat", error: e.message });
  }
};
