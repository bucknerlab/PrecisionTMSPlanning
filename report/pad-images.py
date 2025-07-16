from PIL import Image, ImageOps
import os
import argparse

def pad_images(SUBID, base, efieldfolder):
    root = f"{base}/{SUBID}/{efieldfolder}/report/efield_figures/trimmed"

    image_names = [f for f in os.listdir(root) if 'MidT' in f]
    image_paths = [os.path.join(root, f) for f in image_names]

    cropped_images = [Image.open(img_path) for img_path in image_paths]

    # Step 2: Find max width and height
    max_width = max(image.width for image in cropped_images)
    max_height = max(image.height for image in cropped_images)

    # Step 3: Pad images to uniform size
    padded_images = []
    for image in cropped_images:
        # Create a new image with white background
        new_image = Image.new("RGB", (max_width, max_height), (255, 255, 255))
        # Paste the cropped image onto the new image, centering it
        new_image.paste(image, ((max_width - image.width) // 2, (max_height - image.height) // 2))
        padded_images.append(new_image)

    # Step 4: Save padded images
    output_dir = os.path.join(root, "padded_images")
    os.makedirs(output_dir, exist_ok=True)

    for i, image in enumerate(padded_images):
        output_path = os.path.join(output_dir, image_names[i])
        image.save(output_path)

    print(f"Padded midthickness images saved to {output_dir}")

    image_names2 = [f for f in os.listdir(root) if 'Inflated' in f or 'targ' in f]
    image_paths2 = [os.path.join(root, f) for f in image_names2]
    cropped_images2 = [Image.open(img_path) for img_path in image_paths2]

    # Step 2: Find max width and height
    max_width2 = max(image.width for image in cropped_images2)
    max_height2 = max(image.height for image in cropped_images2)

    # Step 3: Pad images to uniform size
    padded_images2 = []
    for image in cropped_images2:
        # Create a new image with white background
        new_image = Image.new("RGB", (max_width2, max_height2), (255, 255, 255))
        # Paste the cropped image onto the new image, centering it
        new_image.paste(image, ((max_width2 - image.width) // 2, (max_height2 - image.height) // 2))
        padded_images2.append(new_image)

    for i, image in enumerate(padded_images2):
        output_path = os.path.join(output_dir, image_names2[i])
        image.save(output_path)

    print(f"Padded inflated images saved to {output_dir}")

    # Step 5: Delete original images in the "trimmed" directory
    for image_path in image_paths + image_paths2:
        os.remove(image_path)

    print(f"Original images in the 'trimmed' directory deleted")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Pad images for a given subject ID and base directory.")
    parser.add_argument('SUBID', type=str, help="Subject ID.")
    parser.add_argument('base', type=str, help="Base directory.")
    parser.add_argument('efieldfolder', type=str, help="Efield directory.")

    args = parser.parse_args()

    pad_images(args.SUBID, args.base, args.efieldfolder)
