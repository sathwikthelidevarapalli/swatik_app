import multer from "multer";
import path from "path";
import fs from "fs";

// Ensure folder exists
function ensureFolder(folderPath) {
  if (!fs.existsSync(folderPath)) {
    fs.mkdirSync(folderPath, { recursive: true });
  }
}

const storage = multer.diskStorage({
  destination(req, file, cb) {
    let folder = "";

    const url = req.originalUrl.toLowerCase();

    // ----------------------------
    // GALLERY UPLOADS
    // ----------------------------
    if (url.includes("gallery")) {
      folder = "uploads/gallery";
    }

    // ----------------------------
    // VERIFICATION DOCUMENTS
    // ----------------------------
    else if (url.includes("verification") || url.includes("register/documents")) {
      folder = "uploads/documents";
    }

    // ----------------------------
    // PORTFOLIO UPLOADS (frontend uses register/portfolio)
    // ----------------------------
    else if (url.includes("register/portfolio") || url.includes("portfolio")) {
      folder = "uploads/portfolio";
    }

    // ----------------------------
    // FALLBACK
    // ----------------------------
    else {
      folder = "uploads";
    }

    // Create folder if not exists
    ensureFolder(folder);

    cb(null, folder);
  },

  filename(req, file, cb) {
    const ext = path.extname(file.originalname);
    const fileName =
      Date.now() + "-" + Math.round(Math.random() * 1e9) + ext;

    cb(null, fileName);
  },
});

const upload = multer({ storage });

export default upload;
