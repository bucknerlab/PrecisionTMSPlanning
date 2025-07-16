import asyncio
import nest_asyncio
from playwright.async_api import async_playwright
import fitz
import subprocess
import os
import argparse
from datetime import datetime

# Get today's date
today = datetime.today()
formatted_date = today.strftime('%Y%m%d')

def delete_first_page_and_add_page_numbers(input_pdf, output_pdf):
    try:
        # Open the PDF
        if not os.path.exists(input_pdf):
            print(f"Error: {input_pdf} does not exist.")
            return

        pdf = fitz.open(input_pdf)
        num_pages = pdf.page_count

        if num_pages < 2:
            print("The PDF has fewer than 2 pages. Cannot delete the first page.")
            return

        # Delete the first page
        pdf.delete_page(0)
        num_pages -= 1  # Adjust count after deleting the first page

        # Add page numbers
        for i in range(num_pages):
            page = pdf.load_page(i)
            text = f"{i + 1}"

            # Determine the position for bottom right-hand corner
            rect = page.rect
            x = rect.width - 25  # 25 points from the right
            y = rect.height - 15  # 15 points from the bottom

            # Add the text with Helvetica font
            page.insert_text((x, y), text, fontsize=12, fontname="helv", color=(0, 0, 0), overlay=True)

        # Save the modified PDF
        pdf.save(output_pdf)
        pdf.close()

        print('delete_first_page done')

    except Exception as e:
        print(f"Error processing PDF: {e}")

def compress_pdf(input_path, output_path):

    try:
        if not os.path.exists(input_path):
            print(f"Error: {input_path} does not exist.")
            return
        # Compress the PDF using ghostscript
        subprocess.run([
            'gs',
            '-sDEVICE=pdfwrite',
            '-dCompatibilityLevel=1.4',
            '-dPDFSETTINGS=/printer',  
            '-dNOPAUSE',
            '-dQUIET',
            '-dBATCH',
            f'-sOutputFile={output_path}',
            input_path
        ], check=True)
        print('compress_pdf done')
    except subprocess.TimeoutExpired:
        print(f"Error: Compression process timed out for {input_path}.")
    except Exception as e:
        print(f"Error during PDF compression: {e}")
async def html_to_pdf(html_file_path, output_pdf_path):
    try:
        if not os.path.exists(html_file_path):
            print(f"Error: {html_file_path} does not exist.")
            return

        async with async_playwright() as p:
            try:
                print("start async_playwright")
                html_dirname = os.path.dirname(html_file_path)
                outputpdf_dirname = os.path.dirname(output_pdf_path)
                sbind = os.environ.get('SINGULARITY_BIND', '').strip()
                if sbind:
                    sbind = ','.join([sbind, html_dirname, outputpdf_dirname])
                else:
                    sbind = ','.join([html_dirname, outputpdf_dirname])

                browser = await p.chromium.launch(executable_path="/path/to/chromium/container/chromium.sif", env={'SINGULARITY_BIND': sbind})
                page = await browser.new_page()
                await page.emulate_media(media='screen')
                await page.add_style_tag(
                    content='html {-webkit-print-color-adjust: exact}'
                )
                # Open the HTML file
                await page.goto(f'file://{html_file_path}')

                # Set PDF options
                pdf_options = {
                    'format': 'letter',
                    'print_background': True,
                    'margin': {
                        'top': '0in',
                        'right': '0in',
                        'bottom': '0in',
                        'left': '0in',
                    }
                }

                # Save the PDF
                await page.pdf(path=output_pdf_path, **pdf_options)
                print('save_pdf completed')
            finally:
                if 'browser' in locals() and browser:
                    await browser.close()

    except Exception as e:
        print(f"Error during HTML to PDF conversion: {e}")
        raise e

def run_async_task(task):
    try:
        print('start run_async_task')
        loop = asyncio.get_event_loop()
        if loop.is_running():
            new_loop = asyncio.new_event_loop()
            asyncio.set_event_loop(new_loop)
            new_loop.run_until_complete(task)
        else:
            loop.run_until_complete(task)

        print('completed run_async_task')
    except Exception as e:
        print(f"Error running async task: {e}")

def main(SUBID, root, efieldfolder):
    try:
        input_html = f"{root}/{SUBID}/{efieldfolder}/report/{SUBID}_Report_ws.html"
        output_pdf = f"{root}/{SUBID}/{efieldfolder}/report/{SUBID}_Report_ws.pdf"
        output_pdf2 = f"{root}/{SUBID}/{efieldfolder}/report/{SUBID}_Report_ws_pagenum.pdf"
        output_pdf3 = f"{root}/{SUBID}/{efieldfolder}/report/{SUBID}_Report_{formatted_date}.pdf"

        # Apply nest_asyncio to allow nested event loops
        nest_asyncio.apply()
        run_async_task(html_to_pdf(input_html, output_pdf))
        print("Successfully converted html to pdf!")

        # Delete first page, add page numbers, and compress PDF
        delete_first_page_and_add_page_numbers(output_pdf, output_pdf2)
        print("Successfully removed first page and added page numbers!")

        # Compress the resulting PDF
        compress_pdf(output_pdf2, output_pdf3)
        print("Successfully compressed pdf!")

        # Remove large files
        if os.path.exists(output_pdf2):
            os.remove(output_pdf2)
        if os.path.exists(output_pdf):
            os.remove(output_pdf)
        print("Successfully deleted large intermediate pdfs!")

    except Exception as e:
        print(f"Error in main process: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert HTML to PDF, remove first page, add page numbers, and compress the PDF.")
    parser.add_argument('SUBID', type=str, help="Subject ID.")
    parser.add_argument('root', type=str, help="Root directory.")
    parser.add_argument('efieldfolder', type=str, help="Efield directory.")

    args = parser.parse_args()

    main(args.SUBID, args.root, args.efieldfolder)
