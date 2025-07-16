import re
import os
import argparse
from datetime import datetime

def read_coordinates(file_path):
    with open(file_path, 'r') as file:
        line = file.readline().strip()
        coords = line.split()
        rounded_coords = [str(round(float(coord), 1)) for coord in coords]
        if 'angle' in file_path:
            rounded_coords = [str(int(round(float(coord), 0))) for coord in coords]
        return rounded_coords

def read(file_path):
    with open(file_path, 'r') as file:
        return file.read()

def save(content, file_path):
    with open(file_path, 'w') as file:
        file.write(content)

def update_td_tags(html_content, best_dose_images):
    for image in best_dose_images:
        pattern = f'<td data-border="false"><img src="./efield_figures/trimmed/padded_images/{image}"'
        replacement = f'<td data-border="true"><img src="./efield_figures/trimmed/padded_images/{image}"'
        html_content = html_content.replace(pattern, replacement)
    return html_content

def make_html(SUBID, base, conditions, networks, template_root, template_file, efieldfolder):
    SUBID_filler = 'SUBIDFILLER'
    date_filler = 'DATEFILLER'

    today = datetime.today()
    formatted_date = today.strftime('%m/%d/%Y')

    root = f'{base}/{SUBID}/{efieldfolder}/report'
    output_file = os.path.join(root, f"{SUBID}_Report_ws.html")

    center = []
    orient = []
    dose = []
    for condition in conditions:
        center_coords_path = os.path.join(root, "coordinates", "{}_center.txt".format(condition))
        orient_coords_path = os.path.join(root, "coordinates", "{}_orientation.txt".format(condition))
        dose_path = os.path.join(root, "dose", "{}_bestdose.txt".format(condition))
        center_coords = read_coordinates(center_coords_path)
        orientation_coords = read_coordinates(orient_coords_path)
        dose_num = read_coordinates(dose_path)
        center.append(center_coords)
        orient.append(orientation_coords)
        dose.append(dose_num)

    dose_values = range(10, 20)
    dose_keys = ['73.9', '82.0', '90.2', '98.3', '106.4', '114.5', '122.6', '130.7', '138.8', '146.9']
    dose_dict = dict(zip(dose_keys, dose_values))

# this is assuming that T1_NegCorr appears first in the conditions list in the config file
    if "T1_NegCorr_Thr0_LBA46_d2" in conditions:
        best_dose = [networks[i]+'+Dose+MidT+Dorsal_{}.png'.format(dose_dict.get(dose[i+1][0])) for i in range(4)]
        replacements = {
            "1xcntr": center[1][0], "1ycntr": center[1][1], "1zcntr": center[1][2],
            "2xcntr": center[2][0], "2ycntr": center[2][1], "2zcntr": center[2][2],
            "3xcntr": center[3][0], "3ycntr": center[3][1], "3zcntr": center[3][2],
            "4xcntr": center[4][0], "4ycntr": center[4][1], "4zcntr": center[4][2],
            "5xcntr": center[0][0], "5ycntr": center[0][1], "5zcntr": center[0][2],
            "1xhand": orient[1][0], "1yhand": orient[1][1], "1zhand": orient[1][2],
            "2xhand": orient[2][0], "2yhand": orient[2][1], "2zhand": orient[2][2],
            "3xhand": orient[3][0], "3yhand": orient[3][1], "3zhand": orient[3][2],
            "4xhand": orient[4][0], "4yhand": orient[4][1], "4zhand": orient[4][2],
            "5xhand": orient[0][0], "5yhand": orient[0][1], "5zhand": orient[0][2],
            SUBID_filler: SUBID,
            date_filler: formatted_date
        }
    else: #if you do not want sgACC NegCorr condition in the report
        best_dose = [networks[i]+'+Dose+MidT+Dorsal_{}.png'.format(dose_dict.get(dose[i][0])) for i in range(4)]
        replacements = {
                "1xcntr": center[0][0], "1ycntr": center[0][1], "1zcntr": center[0][2],
                "2xcntr": center[1][0], "2ycntr": center[1][1], "2zcntr": center[1][2],
                "3xcntr": center[2][0], "3ycntr": center[2][1], "3zcntr": center[2][2],
                "4xcntr": center[3][0], "4ycntr": center[3][1], "4zcntr": center[3][2],
                "1xhand": orient[0][0], "1yhand": orient[0][1], "1zhand": orient[0][2],
                "2xhand": orient[1][0], "2yhand": orient[1][1], "2zhand": orient[1][2],
                "3xhand": orient[2][0], "3yhand": orient[2][1], "3zhand": orient[2][2],
                "4xhand": orient[3][0], "4yhand": orient[3][1], "4zhand": orient[3][2],
                SUBID_filler: SUBID,
                date_filler: formatted_date
            }

    print(best_dose)



    html = read(os.path.join(template_root,template_file))

    for key, value in replacements.items():
        html = html.replace(key, value)

    html = update_td_tags(html, best_dose)

    save(html, output_file)
    print(f"Successfully saved new HTML file: {output_file}!")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate HTML report from template.")
    parser.add_argument('SUBID', type=str, help="Subject ID.")
    parser.add_argument('base', type=str, help="Base directory for subject data.")
    parser.add_argument('conditions', type=str, help="Comma-separated list of conditions.")
    parser.add_argument('networks', type=str, help="Comma-separated list of networks.")
    parser.add_argument('html_template_root', type=str, help="Directory where html template is.")
    parser.add_argument('html_template_file', type=str, help="File name for html template.")
    parser.add_argument('efieldfolder', type=str, help="Efield directory")

    args = parser.parse_args()

    conditions = args.conditions.split(',')
    networks = args.networks.split(',')

    make_html(args.SUBID, args.base, conditions, networks, args.html_template_root, args.html_template_file, args.efieldfolder)
