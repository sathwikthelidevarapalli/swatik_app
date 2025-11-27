import mongoose from "mongoose";
import bcrypt from "bcryptjs";

const vendorSchema = mongoose.Schema(
  {
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },

    businessName: String,
    ownerName: String,
    category: String,
    experience: String,
    description: String,
    phone: String,

    city: String,
    state: String,
    pincode: String,

    gstin: String,

    applicationStatus: { type: String, default: "pending" },
    rejectionReason: String,

    // ⭐ NEW — Photo Gallery Storage
    gallery: [
      {
        url: String,
        uploadedAt: { type: Date, default: Date.now }
      }
    ],

    // ⭐ NEW — Pricing Packages
    packages: [
      {
        title: String,
        price: Number,
        description: String,
        features: [String]
      }
    ],

    // ⭐ NEW — Verification Documents
    verification: {
      businessLicense: { status: { type: String, default: "pending" }, file: String },
      gst: { status: { type: String, default: "pending" }, gstin: String, file: String },
      addressProof: { status: { type: String, default: "pending" }, file: String },
      additionalDocs: [String]
    },

    // ⭐ NEW — Availability Calendar (list of unavailable days)
    unavailable: [String]
    ,
    // ⭐ NEW — Portfolio (separate from gallery)
    portfolio: [
      {
        url: String,
        uploadedAt: { type: Date, default: Date.now }
      }
    ]
  },
  { timestamps: true }
);

vendorSchema.virtual("location").get(function () {
  if (this.city && this.state) return `${this.city}, ${this.state}`;
  return "";
});

// Password hashing
vendorSchema.pre("save", async function (next) {
  if (!this.isModified("password")) return next();
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

vendorSchema.methods.matchPassword = async function (entered) {
  return await bcrypt.compare(entered, this.password);
};

const Vendor = mongoose.model("Vendor", vendorSchema);
export default Vendor;
