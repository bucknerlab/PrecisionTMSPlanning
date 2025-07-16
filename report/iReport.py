import configparser
import subprocess
import sys
import argparse
import os
import logging
import re
import time

# Configure logging for console output
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')

def run_script(script_name, *args):
    if script_name.endswith('.sh'):
        command = ['bash', script_name] + list(map(str, args))
    elif script_name.endswith('.R'):
        command = ['Rscript', script_name] + list(map(str, args))
    else:
        command = [sys.executable, script_name] + list(map(str, args))

    # Log the command for debugging
    logging.debug("Running command with arguments: %s", command)
    try:
        result = subprocess.run(command, capture_output=True, text=True, check=True)
        logging.info("Output from %s: %s", script_name, result.stdout)
    except subprocess.CalledProcessError as e:
        logging.error("Error running %s: %s", script_name, e.stderr)
        sys.exit(e.returncode)

def run_matlab_script_with_dynamic_args(script_name, *args):
    # Extract the function name from the script name
    function_name = script_name[:-2].split('/')[-1]
    # Construct the MATLAB command dynamically using all provided arguments
    matlab_args = ', '.join([f"'{arg}'" for arg in args])
    matlab_command = f"{function_name}({matlab_args}); exit;"
    full_command = f'matlab -nodisplay -nodesktop -r "{matlab_command}"'
    
    # Log the command for debugging
    logging.debug("Running MATLAB command with arguments: %s", full_command)
    try:
        result = subprocess.run(full_command, capture_output=True, text=True, shell=True, check=True)
        logging.info("Output from %s: %s", script_name, result.stdout)
    except subprocess.CalledProcessError as e:
        logging.error("Error running %s: %s", script_name, e.stderr)
        sys.exit(e.returncode)

def main(config_path):
    config = configparser.ConfigParser()
    config.read(config_path)
    SUBID = config.get('parameters', 'SUBID')
    codedir = config.get('parameters', 'codedir')
    base = config.get('parameters', 'base')
    iprocdir = config.get('parameters', 'iprocdir')
    efieldfolder = config.get('parameters', 'efieldfolder')
    partition = config.get('parameters', 'partition')

    baseline_sess = config.get('baseline', 'sess')

    conditions = config.get('report', 'conditions').split(',')
    avoids = config.get('report', 'avoids').split(',')
    networks = config.get('report', 'networks').split(',')
    html_template_root = config.get('report', 'html_template_root')
    html_template_file = config.get('report', 'html_template_file')
    rlibpath = config.get('report', 'rlibpath')
    

    maskdir = os.path.join(base, "MASKS")

    # Run the scripts sequentially
    run_matlab_script_with_dynamic_args('quantify_efield_hotspot.m', codedir, SUBID, base, ','.join(conditions), efieldfolder)
    run_matlab_script_with_dynamic_args('extract_efield_values.m', codedir, SUBID, base, ','.join(conditions), efieldfolder)
    
    run_script(f'{codedir}/report/TANS_hotspot_plots.R', rlibpath, SUBID, base, ','.join(conditions), efieldfolder)  
    run_script(f'{codedir}/report/quantify_efield_result_density.R', rlibpath, SUBID, base, ','.join(conditions), efieldfolder) 
    run_script(f'{codedir}/report/wb_cifti_merge.sh', SUBID, base, ','.join(conditions), efieldfolder)
    run_script(f'{codedir}/report/wb_create_scene_brain.sh', SUBID, base, efieldfolder)
    run_script(f'{codedir}/report/wb_create_scene_skin.sh', SUBID, base, efieldfolder)
    run_script(f'{codedir}/report/wb_screenshot_brain.sh', SUBID, base, ','.join(networks), efieldfolder)
    run_script(f'{codedir}/report/wb_screenshot_skin.sh', SUBID, base, ','.join(networks), efieldfolder)
    run_script(f'{codedir}/report/copy_coordinates+dose_for_report.sh', SUBID, base, ','.join(conditions), efieldfolder)
    run_script(f'{codedir}/report/trim.sh', SUBID, base, efieldfolder)
    run_script(f'{codedir}/report/pad-images.py', SUBID, base, efieldfolder)
    run_script(f'{codedir}/report/make-html-from-template.py', SUBID, base, ','.join(conditions), ','.join(networks), html_template_root, html_template_file, efieldfolder)
    run_script(f'{codedir}/report/html-to-pdf.py', SUBID, base, efieldfolder)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run iTMS report with specified config file.")
    parser.add_argument('config_path', type=str, help="Path to the configuration file.")

    args = parser.parse_args()

    main(args.config_path)
