#!/usr/bin/env python3
"""
Image compression script for Flutter app assets.
Compresses all images in assets/app_images (including subfolders).
Preserves aspect ratio with minimum dimension of 256px.
Target file size: 50-100KB per image.
"""

import os
from pathlib import Path
from PIL import Image
import pillow_heif

# Register HEIF opener
pillow_heif.register_heif_opener()

# Configuration
SOURCE_DIR = "assets/app_images"
OUTPUT_DIR = "assets/app_images_compressed"
MIN_DIMENSION = 255
TARGET_FILE_SIZE_MIN = 50 * 1024  # 50KB
TARGET_FILE_SIZE_MAX = 100 * 1024  # 100KB
INITIAL_QUALITY = 85
MIN_QUALITY = 60


def ensure_output_dir(path):
    """Create output directory if it doesn't exist."""
    Path(path).mkdir(parents=True, exist_ok=True)


def calculate_resize_dimensions(original_size):
    """
    Calculate new dimensions maintaining aspect ratio.
    Smallest dimension will be MIN_DIMENSION.
    """
    width, height = original_size

    if width < height:
        # Width is smaller, set it to MIN_DIMENSION
        new_width = MIN_DIMENSION
        new_height = int((height / width) * MIN_DIMENSION)
    else:
        # Height is smaller or equal, set it to MIN_DIMENSION
        new_height = MIN_DIMENSION
        new_width = int((width / height) * MIN_DIMENSION)

    return (new_width, new_height)


def get_file_size(filepath):
    """Get file size in bytes."""
    return os.path.getsize(filepath)


def get_save_format_and_params(file_path, img_mode):
    """
    Determine save format and parameters based on file extension.
    Returns (format, save_params_dict)
    """
    ext = file_path.suffix.lower()

    # Map extensions to PIL format names
    format_map = {
        '.jpg': 'JPEG',
        '.jpeg': 'JPEG',
        '.png': 'PNG',
        '.webp': 'WEBP',
        '.bmp': 'BMP',
        '.tiff': 'TIFF',
        '.tif': 'TIFF',
    }

    format_name = format_map.get(ext, 'JPEG')

    # Determine if we need RGB or can keep RGBA
    needs_rgb = format_name in ('JPEG', 'BMP')

    return format_name, needs_rgb


def compress_image(input_path, output_path, relative_path=""):
    """
    Compress and resize image to target specifications.
    Uses binary search to find optimal quality for target file size.
    Maintains aspect ratio with minimum dimension of MIN_DIMENSION.
    Preserves original image format.
    """
    try:
        # Open image
        with Image.open(input_path) as img:
            # Determine output format
            save_format, needs_rgb = get_save_format_and_params(
                output_path, img.mode
            )

            # Convert mode if necessary
            if needs_rgb and img.mode in ('RGBA', 'LA', 'P'):
                # Create white background for transparency
                background = Image.new('RGB', img.size, (255, 255, 255))
                if img.mode == 'P':
                    img = img.convert('RGBA')
                if img.mode in ('RGBA', 'LA'):
                    background.paste(img, mask=img.split()[-1])
                else:
                    background.paste(img)
                img = background
            elif needs_rgb and img.mode != 'RGB':
                img = img.convert('RGB')
            elif not needs_rgb and img.mode == 'P':
                img = img.convert('RGBA')

            # Calculate new dimensions maintaining aspect ratio
            new_size = calculate_resize_dimensions(img.size)

            # Resize with high-quality Lanczos resampling
            img_resized = img.resize(new_size, Image.Resampling.LANCZOS)

            # Ensure output directory exists
            ensure_output_dir(output_path.parent)

            # Binary search for optimal quality
            quality = INITIAL_QUALITY
            min_q = MIN_QUALITY
            max_q = 95
            best_quality = quality

            # Prepare save parameters based on format
            save_params = {'optimize': True}
            if save_format in ('JPEG', 'WEBP'):
                save_params['quality'] = quality

            # Try initial quality
            img_resized.save(output_path, save_format, **save_params)
            file_size = get_file_size(output_path)

            # If already in range, we're done
            if TARGET_FILE_SIZE_MIN <= file_size <= TARGET_FILE_SIZE_MAX:
                display_path = relative_path or os.path.basename(input_path)
                size_kb = file_size / 1024
                dims = f"{new_size[0]}x{new_size[1]}"
                qual_str = f", quality: {quality}" if save_format in (
                    'JPEG', 'WEBP'
                ) else ""
                print(f"✓ {display_path}: {size_kb:.1f}KB "
                      f"({dims}{qual_str})")
                return True

            # Binary search for optimal quality (only for JPEG/WEBP)
            if save_format in ('JPEG', 'WEBP'):
                attempts = 0
                max_attempts = 10

                while attempts < max_attempts and min_q <= max_q:
                    if file_size > TARGET_FILE_SIZE_MAX:
                        # File too large, reduce quality
                        max_q = quality - 1
                    elif file_size < TARGET_FILE_SIZE_MIN:
                        # File too small, increase quality
                        min_q = quality + 1

                    quality = (min_q + max_q) // 2
                    save_params['quality'] = quality
                    img_resized.save(output_path, save_format, **save_params)
                    file_size = get_file_size(output_path)

                    if (TARGET_FILE_SIZE_MIN <= file_size <=
                            TARGET_FILE_SIZE_MAX):
                        best_quality = quality
                        break

                    best_quality = quality
                    attempts += 1

            final_size = get_file_size(output_path)
            in_range = (TARGET_FILE_SIZE_MIN <= final_size <=
                        TARGET_FILE_SIZE_MAX)
            status = "✓" if in_range else "⚠"
            display_path = relative_path or os.path.basename(input_path)
            size_kb = final_size / 1024
            dims = f"{new_size[0]}x{new_size[1]}"
            qual_str = f", quality: {best_quality}" if save_format in (
                'JPEG', 'WEBP'
            ) else ""
            print(f"{status} {display_path}: {size_kb:.1f}KB "
                  f"({dims}{qual_str})")
            return True

    except Exception as e:
        display_path = relative_path or os.path.basename(input_path)
        print(f"✗ Error processing {display_path}: {str(e)}")
        return False


def find_all_images(source_dir):
    """
    Recursively find all image files in source directory.
    Returns list of tuples: (absolute_path, relative_path)
    """
    supported_formats = {
        '.jpg', '.jpeg', '.png', '.webp',
        '.heic', '.heif', '.bmp', '.tiff'
    }

    image_files = []
    source_path = Path(source_dir)

    for root, dirs, files in os.walk(source_path):
        for file in files:
            file_path = Path(root) / file
            if file_path.suffix.lower() in supported_formats:
                relative = file_path.relative_to(source_path)
                image_files.append((file_path, relative))

    return image_files


def main():
    """Main compression routine."""
    print("Image Compression Tool")
    print(f"Source: {SOURCE_DIR}")
    print(f"Output: {OUTPUT_DIR}")
    print(f"Min dimension: {MIN_DIMENSION}px (aspect ratio preserved)")
    min_kb = TARGET_FILE_SIZE_MIN / 1024
    max_kb = TARGET_FILE_SIZE_MAX / 1024
    print(f"Target file size: {min_kb:.0f}-{max_kb:.0f}KB")
    print("-" * 60)

    # Check if source directory exists
    source_path = Path(SOURCE_DIR)
    if not source_path.exists():
        print(f"Error: Source directory '{SOURCE_DIR}' does not exist!")
        return

    # Find all images recursively
    image_files = find_all_images(SOURCE_DIR)

    if not image_files:
        print(f"No image files found in {SOURCE_DIR}")
        return

    print(f"Found {len(image_files)} images to process\n")

    # Process each image
    success_count = 0
    for img_path, relative_path in sorted(image_files):
        # Create output path maintaining folder structure and format
        output_file = Path(OUTPUT_DIR) / relative_path

        if compress_image(img_path, output_file, str(relative_path)):
            success_count += 1

    print("-" * 60)
    total = len(image_files)
    print(f"Completed: {success_count}/{total} images processed")
    print(f"Output directory: {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
