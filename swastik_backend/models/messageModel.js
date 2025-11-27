import mongoose from "mongoose";

const messageSchema = mongoose.Schema(
  {
    vendorId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Vendor",
      required: true,
    },
    customerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Customer",
      required: true,
    },

    customerName: String,
    eventType: String,

    messages: [
      {
        sender: String,       // vendor | customer
        text: String,
        timestamp: Date,
        read: { type: Boolean, default: false }
      }
    ]
  },
  { timestamps: true }
);

const Message = mongoose.model("Message", messageSchema);
export default Message;
