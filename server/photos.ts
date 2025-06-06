import fs from "fs";
import path from "path";
import { promisify } from "util";
import { storage } from "./storage";
import { PhotoItem } from "@shared/schema";

const readdir = promisify(fs.readdir);
const stat = promisify(fs.stat);

// Image file extensions
const IMAGE_EXTENSIONS = [".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp"];

export async function getPhotos(): Promise<PhotoItem[]> {
  try {
    // Get photo directory from settings
    const photoDirectory =
      (await storage.getSetting("photoDirectory")) ||
      path.join(process.cwd(), "family-photos");

    // Create directory if it doesn't exist
    if (!fs.existsSync(photoDirectory)) {
      fs.mkdirSync(photoDirectory, { recursive: true });
    }

    // Read directory contents
    const files = await readdir(photoDirectory);

    // Filter for image files and get their stats
    const photoPromises = files
      .filter((file) => {
        const ext = path.extname(file).toLowerCase();
        return IMAGE_EXTENSIONS.includes(ext);
      })
      .map(async (file) => {
        const filePath = path.join(photoDirectory, file);
        const fileStat = await stat(filePath);

        return {
          id: file,
          path: `/api/photos/${encodeURIComponent(file)}`,
          name: file,
          createdAt: fileStat.birthtime,
        };
      });

    return Promise.all(photoPromises);
  } catch (error) {
    console.error("Error reading photos directory:", error);
    return [];
  }
}

export async function getPhotoFile(photoName: string): Promise<string | null> {
  try {
    // Decode URL-encoded filename and sanitize to prevent directory traversal
    const decodedName = decodeURIComponent(photoName);
    const sanitizedName = path.basename(decodedName);
    
    console.log(`Looking for photo: ${sanitizedName}`);
    
    // Get stored path first, then fallback to defaults
    const storedPath = await storage.getSetting("photoDirectory");
    const possiblePaths = [];
    
    if (storedPath) {
      possiblePaths.push(path.join(storedPath, sanitizedName));
    }
    
    // Add default paths (family-photos first since that's the main directory)
    possiblePaths.push(
      path.join(process.cwd(), "family-photos", sanitizedName),
      path.join(process.cwd(), "server", "photos", sanitizedName)
    );

    // Ensure all paths are absolute
    const absolutePaths = possiblePaths.map(p => path.isAbsolute(p) ? p : path.resolve(p));

    console.log(`Checking paths:`, absolutePaths);

    // Return first existing file path
    for (const filePath of absolutePaths) {
      console.log(`Checking if exists: ${filePath}`);
      if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
        console.log(`Found photo at: ${filePath}`);
        return filePath;
      }
    }

    console.error(`Photo not found: ${sanitizedName} in any of the paths:`, absolutePaths);
    return null;
  } catch (error) {
    console.error("Error getting photo file:", photoName, error);
    return null;
  }
}

export async function saveUploadedPhoto(
  file: Express.Multer.File,
): Promise<boolean> {
  try {
    const photoDirectory =
      (await storage.getSetting("photoDirectory")) ||
      path.join(process.cwd(), "family-photos");

    // Create directory if it doesn't exist
    if (!fs.existsSync(photoDirectory)) {
      fs.mkdirSync(photoDirectory, { recursive: true });
    }

    // Get unique filename
    const uniqueFilename = `${Date.now()}-${file.originalname}`;
    const savePath = path.join(photoDirectory, uniqueFilename);

    // Save file
    fs.writeFileSync(savePath, file.buffer);

    return true;
  } catch (error) {
    console.error("Error saving uploaded photo:", error);
    return false;
  }
}