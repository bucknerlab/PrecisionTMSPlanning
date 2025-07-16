import configparser
import subprocess
import sys
import argparse
import os
import logging
import re
import time
from datetime import datetime
import glob
import shutil


# Configure logging
def setup_logging(log_dir, subid):
    os.makedirs(log_dir, exist_ok=True)
    log_file = os.path.join(log_dir, f"{subid}_iTMS_{datetime.now().strftime('%Y-%m-%d_%H-%M-%S')}.log")
    
    logging.basicConfig(level=logging.DEBUG,
                        format='%(asctime)s - %(levelname)s - %(message)s',
                        handlers=[
                            logging.FileHandler(log_file),
                            logging.StreamHandler(sys.stdout)
                        ])
    logging.info(f"Logging to {log_file}")

# method for running iproc specific scripts/steps
def run_script_iproc(script_name, *args):
    if script_name.endswith('.sh'):
        command = ['bash', script_name] + list(map(str, args))
    else:  # for Python 
        command = [sys.executable, script_name] + list(map(str, args))

    # Log the command for debugging
    logging.debug("Running command with arguments: %s", command)
    try:
        result = subprocess.run(command, stdout=sys.stdout, stderr=sys.stderr, text=True, check=True)
        # No need to log the output here as it's already printed in real-time
    except subprocess.CalledProcessError as e:
        logging.error("Error running %s: %s", script_name, e.stderr)
        sys.exit(e.returncode)

# method for running bash, python, or R scripts
def run_script(script_name, *args):
    if script_name.endswith('.sh'):
        command = ['bash', script_name] + list(map(str, args))
    elif script_name.endswith('.R'):
        command = ['Rscript', script_name] + list(map(str, args))
    else: #for python 
        command = [sys.executable, script_name] + list(map(str, args))

    # Log the command for debugging
    logging.debug("Running command with arguments: %s", command)
    try:
        result = subprocess.run(command, capture_output=True, text=True, check=True)
        logging.info("Output from %s: %s", script_name, result.stdout)
    except subprocess.CalledProcessError as e:
        logging.error("Error running %s: %s", script_name, e.stderr)
        sys.exit(e.returncode)

# check if a job is finished (SLURM)
def is_job_finished(job_id):
    try:
        result = subprocess.run(['sacct', '-j', job_id, '--format=State', '--noheader'], capture_output=True, text=True, check=True)
        job_states = result.stdout.strip().split()
        # Check if the job state is one of the finished states
        finished_states = {'COMPLETED', 'FAILED', 'CANCELLED', 'TIMEOUT'}
        return any(state in finished_states for state in job_states)
    except subprocess.CalledProcessError as e:
        logging.error("Error checking job status: %s", e.stderr)
        return False

# wait for jobs to finish, checking every 30 seconds - this is based on user preference
def wait_for_jobs(job_ids, path_to_logs):
    logging.info(f"Waiting for job IDs: {', '.join(job_ids)} to finish")
    for i,job_id in enumerate(job_ids):
        while not is_job_finished(job_id):
            logging.info(f"Job {job_id} is still running. Waiting...")
            time.sleep(30)  # Wait for 30 seconds before checking again
        result = subprocess.run(['sacct', '-j', job_id, '--format=State', '--noheader'], capture_output=True, text=True, check=True)
        job_states = result.stdout.strip().split()[0]
        log = path_to_logs[i]
        log = log.replace("%j", job_id)
        logging.info(f"Job {job_id} has {job_states}. Logs here: {log}")

# submits a job to SLURM
def submit_job(path_to_log, partition,  codedir, script_name, args):
    # Construct the sbatch command
    sbatch_command = ['sbatch', '-p',  partition, '-o', path_to_log, os.path.join(codedir, script_name)] + args
    
    # Log the command for debugging
    logging.debug("Submitting sbatch with arguments: %s", sbatch_command)
    try:
        result = subprocess.run(sbatch_command, capture_output=True, text=True, check=True)
        logging.info("Job submitted successfully: %s", result.stdout)
        
        # Extract job ID from sbatch output
        match = re.search(r'\bSubmitted batch job (\d+)\b', result.stdout)
        if match:
            job_id = match.group(1)
            logging.info(f"Captured job ID: {job_id}")
            return job_id
        else:
            logging.error("Job ID not found in sbatch output.")
            sys.exit(1)  # Use a generic exit code since the exact error isn't clear
    except subprocess.CalledProcessError as e:
        logging.error("Error submitting job: %s", e.stderr)
        sys.exit(e.returncode)

def main(config_path, step, no_wait):
    config = configparser.ConfigParser()
    config.read(config_path)
    SUBID = config.get('parameters', 'SUBID')
    codedir = config.get('parameters', 'codedir')
    base = config.get('parameters', 'base')
    iprocdir = config.get('parameters', 'iprocdir')
    efieldfolder = config.get('parameters', 'efieldfolder')
    partition = config.get('parameters', 'partition')
    threshold = config.get('parameters', 'sgacc_thresh')

    baseline_sess = config.get('baseline', 'sess')
    efield_conditions = config.get('efield', 'conditions').split(',')
    efield_avoids = config.get('efield', 'avoids').split(',')
    tans_roi = config.get('efield', 'tans_roi')
    tans_searchgrid = config.get('efield', 'tans_searchgrid')
    tans_simnibs = config.get('efield', 'tans_simnibs')
    tans_optimize = config.get('efield', 'tans_optimize')
    tans_dose = config.get('efield', 'tans_dose')

    conditions = config.get('report', 'conditions').split(',')
    avoids = config.get('report', 'avoids').split(',')
    networks = config.get('report', 'networks').split(',')
    html_template_root = config.get('report', 'html_template_root')
    html_template_file = config.get('report', 'html_template_file')
    rlibpath = config.get('report', 'rlibpath')
    

    maskdir = os.path.join(base, "MASKS")
    current_date = datetime.now().strftime('%Y-%m-%d')

    # Setting up the log directory
    log_dir = os.path.join(base, SUBID, 'logs')
    setup_logging(log_dir, SUBID)


    if step == 'IPROC_setup' or step == 'IPROC':
        run_script_iproc(f'{codedir}/run_iproc.sh', codedir, SUBID, baseline_sess, base, iprocdir, 'setup')
    if step == 'IPROC_bet' or step == 'IPROC':
        run_script_iproc(f'{codedir}/run_iproc.sh', codedir, SUBID, baseline_sess, base, iprocdir, 'bet')
    
    if step == 'IPROC_unwarpmc' or step == 'IPROC':
        run_script_iproc(f'{codedir}/run_iproc.sh', codedir, SUBID, baseline_sess, base, iprocdir, 'unwarp_motioncorrect_align')
        mri_root = f'{base}/{SUBID}/{iprocdir}/MRI/'
        run_script(f'{codedir}/iProc_prep/run_FD_value_checking.sh', SUBID, mri_root, 0.4, "0p4", f"{codedir}/iProc_prep")

    if step == 'IPROC_unwarpmc_1' or step == 'IPROC_MC_OPTIONS':
        run_script_iproc(f'{codedir}/run_iproc_mc_option.sh', codedir, SUBID, baseline_sess, base, iprocdir, '1')
        mri_root = f'{base}/{SUBID}/{iprocdir}/MRI/'
        run_script(f'{codedir}/iProc_prep/run_FD_value_checking.sh', f'{SUBID}_1', mri_root, 0.4, "0p4", f"{codedir}/iProc_prep")
    if step == 'IPROC_unwarpmc_2' or step == 'IPROC_MC_OPTIONS':
        run_script_iproc(f'{codedir}/run_iproc_mc_option.sh', codedir, SUBID, baseline_sess, base, iprocdir, '2')
    if step == 'IPROC_unwarpmc_3' or step == 'IPROC_MC_OPTIONS':
        run_script_iproc(f'{codedir}/run_iproc_mc_option.sh', codedir, SUBID, baseline_sess, base, iprocdir, '3')


    if step == 'IPROC_t1warp' or step == 'IPROC':
        run_script_iproc(f'{codedir}/run_iproc.sh', codedir, SUBID, baseline_sess, base, iprocdir, 'T1_warp_and_mask')
    if step == 'IPROC_sinterp' or step == 'IPROC':
        run_script_iproc(f'{codedir}/run_iproc.sh', codedir, SUBID, baseline_sess, base, iprocdir, 'combine_and_apply_warp')
    if step == 'IPROC_filterproject' or step == 'IPROC':
        run_script_iproc(f'{codedir}/run_iproc.sh', codedir, SUBID, baseline_sess, base, iprocdir, 'filter_and_project')

    # prepares inputs for running the MSHBM to estimate functional networks in the individual
    if step == 'MSHBM_prep':
        run_script(f'{codedir}/MSHBM/make-input-csv.sh', SUBID, base, baseline_sess)
        run_script(f'{codedir}/MSHBM/copy_resid_bpss_fs6_sm_files.sh', SUBID, base, baseline_sess, iprocdir)

    # actually running the MSHBM
    if step == 'MSHBM':
        sub_list = f'{base}/{SUBID}/{SUBID}_{baseline_sess}/NETWORKS/sub_list_{SUBID}.csv'
        output_dir = f'{base}/{SUBID}/{SUBID}_{baseline_sess}/NETWORKS/MSHBM_intermediate_files'
        run_script(f'{codedir}/MSHBM/run_MSHBM.sh', sub_list, output_dir, codedir)

        # check this directory for the output files
        check_dir_pattern = os.path.join(output_dir, 'Params_*', 'Params_training_*', 'estimate_group_priors', 'ind_parcellation', SUBID)
        
        # Initialize the flag
        check_flag = False

        # Iterate through the matched directories to check for the specific file
        while not check_flag:
            check_dirs = glob.glob(check_dir_pattern)
            for dir_path in check_dirs:
                check_files = os.listdir(dir_path)
                if f'{SUBID}_MSHBM.dlabel.nii' in check_files:
                    check_flag = True
                    logging.info(dir_path)
                    logging.info("MSHBM dlabel file is created - done with step!")
                    break
            if check_flag:
                break  # Exit the while loop if the file is found
            logging.info("MSHBM outputs not done yet. Waiting...")
            time.sleep(30)
        netpath = f'{base}/{SUBID}/{SUBID}_{baseline_sess}/NETWORKS/MSHBM_outputs'
        # Create the target directory if it doesn't exist
        os.makedirs(netpath, exist_ok=True)

        # Copy each file from dir_path to netpath
        for item in os.listdir(dir_path):
            s = os.path.join(dir_path, item)
            d = os.path.join(netpath, item)
            if os.path.isdir(s):
                shutil.copytree(s, d, dirs_exist_ok=True)  # For copying subdirectories
            else:
                shutil.copy2(s, d)  # For copying individual files  

    # after the MSHBM is run, this creates a scene for the specific subject and makes a pptx with screenshots of the 8 views as in Du et al 2024 (J Neurophys)
    if step == 'MSHBM_post':
        run_script(f'{codedir}/MSHBM/wb_create_scene_networks.sh', SUBID, baseline_sess, base)
        run_script(f'{codedir}/MSHBM/wb_screenshot_networks.sh', SUBID, baseline_sess, base)
        run_script(f'{codedir}/MSHBM/run_network_pptx.sh', SUBID, baseline_sess, base, codedir)

    # preparing outputs of iProc and MSHBM for running through TANS
    if step == 'PREP_TANS':
        indir = os.path.join(base, SUBID, efieldfolder)
        path_to_log = f'{indir}/logs/{SUBID}_{current_date}_PREP_TANS_%j.out'

        args = [codedir, SUBID, baseline_sess, base, iprocdir, efieldfolder]
        script_name = "run_prep_tans_files.sh"
        job_id = submit_job(path_to_log, partition, codedir, script_name, args)
        if job_id:
            logging.info(f"Job ID: {job_id}")
        # Wait for all jobs to finish
        if not no_wait:
            wait_for_jobs([job_id], [path_to_log])
        logging.info("PREP_TANS done.")

    # computes sgACC-cortical correlations and defines "anticorrelated" regions
    if step == 'SGACC_CORR':
        indir = os.path.join(base, SUBID, efieldfolder)
        path_to_log = f'{indir}/logs/{SUBID}_{current_date}_SGACC_CORR_%j.out'
        args = [codedir, SUBID, baseline_sess, base, iprocdir, efieldfolder, threshold]
        script_name = "run_sgacc_corr_sequence.sh"
        job_id = submit_job(path_to_log, partition, codedir, script_name, args)
        if job_id:
            logging.info(f"Job ID: {job_id}")
        # Wait for all jobs to finish
        if not no_wait:
            wait_for_jobs([job_id], [path_to_log])
        logging.info("SGACC_CORR done.")
    
    if step == 'TANS_HEADMODEL':
        indir = os.path.join(base, SUBID, efieldfolder)
        condition = efield_conditions[0]
        outdir = condition
        avoid = str(efield_avoids[0])
        if 'NegCorr' in condition:
            parcel = '2'
        else:
            parcel = '15'

        arr = condition.split("_")
        target = arr[0][1:]

        arr_thr = condition.split("_Thr")
        thresh = arr_thr[-1].split("_")[0]

        arr_net = "_".join(arr_thr[0].split("_")[1:])

        thr_str = f"Thr{thresh}_"
        search = condition.split(thr_str)[-1]

        path_to_log = f'{indir}/logs/{SUBID}_{current_date}_{outdir}_TANS_HEADMODEL_%j.out'

        args = [SUBID, indir, '1', '0', '0', '0', '0', '0', parcel, thresh, target, avoid, search, outdir, codedir, maskdir]
        script_name = "run_tans.sh"
        job_id = submit_job(path_to_log, partition, codedir, script_name, args)
        if job_id:
            logging.info(f"Job ID: {job_id}")
        # Wait for all jobs to finish
        if not no_wait:
            wait_for_jobs([job_id], [path_to_log])
        logging.info("TANS_HEADMODEL done.")

    if step == 'TANS_EFIELD':
        indir = os.path.join(base, SUBID, efieldfolder)
        job_ids = []
        path_to_logs = []
        for i, condition in enumerate(efield_conditions):
            outdir = condition
            avoid = str(efield_avoids[i])

            if 'NegCorr' in condition:
                parcel = '2'
            else:
                parcel = '15'

            arr = condition.split("_")
            target = arr[0][1:]

            arr_thr = condition.split("_Thr")
            thresh = arr_thr[-1].split("_")[0]

            arr_net = "_".join(arr_thr[0].split("_")[1:])

            thr_str = f"Thr{thresh}_"
            search = condition.split(thr_str)[-1]

            path_to_log = f'{indir}/logs/{SUBID}_{current_date}_{outdir}_TANS_EFIELD_%j.out'

            args = [SUBID, indir, '0', str(tans_roi), str(tans_searchgrid), str(tans_simnibs), str(tans_optimize), str(tans_dose), parcel, thresh, target, avoid, search, outdir, codedir, maskdir]

            script_name = "run_tans.sh"
            job_id = submit_job(path_to_log, partition, codedir, script_name, args)
            if job_id:
                logging.info(f"Job ID: {job_id}")
                job_ids.append(job_id)
                path_to_logs.append(path_to_log)
        
        # Wait for all jobs to finish
        if not no_wait:
            wait_for_jobs(job_ids, path_to_logs)
        logging.info("TANS_EFIELD done.")

    if step == 'REPORT':
        indir = os.path.join(base, SUBID, efieldfolder)
        script_name = "run_iTMS_report.sh"
        path_to_log = f'{indir}/logs/{SUBID}_{current_date}_iTMS_REPORT_%j.out'
        args = [f'{codedir}/report', config_path]
        job_id = submit_job(path_to_log, partition, codedir, script_name, args)
        if job_id:
            logging.info(f"Job ID: {job_id}")
            
        # Wait for all jobs to finish
        if not no_wait:
            wait_for_jobs([job_id], [path_to_log])
        logging.info("REPORT done.")

    if step == 'LOCALITE':
        for i, condition in enumerate(efield_conditions):
            outdir = str(condition)
            print(outdir)
            avoid = str(efield_avoids[i])

            arr = condition.split("_")
            target = "ELEC-"+arr[1][0]+arr[-2][0]
            print(target)
            run_script(f'{codedir}/localite/run_instrument_marker.sh', f"{codedir}/localite", SUBID, efieldfolder, outdir, target, 2, avoid, base)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run iTMS process with specified config file and step.")
    parser.add_argument('config_path', type=str, help="Path to the configuration file.")
    parser.add_argument('step', type=str, help="Step to run. ALL to run everything.")

    parser.add_argument('--no-wait', action='store_true', help="Do not wait for jobs to finish")

    args = parser.parse_args()

    main(args.config_path, args.step, args.no_wait)