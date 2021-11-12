#!/usr/bin/env python3
import logging
import subprocess
import os
import csv
import time
import json
from github import Github
from s3_helper import S3Helper
from pr_info import PRInfo
from get_robot_token import get_best_robot_token
from upload_result_helper import upload_results

NAME = "Style Check (actions)"


def process_result(result_folder):
    test_results = []
    additional_files = []
    # Just upload all files from result_folder.
    # If task provides processed results, then it's responsible for content of result_folder.
    if os.path.exists(result_folder):
        test_files = [f for f in os.listdir(result_folder) if os.path.isfile(os.path.join(result_folder, f))]
        additional_files = [os.path.join(result_folder, f) for f in test_files]

    status_path = os.path.join(result_folder, "check_status.tsv")
    logging.info("Found test_results.tsv")
    status = list(csv.reader(open(status_path, 'r'), delimiter='\t'))
    if len(status) != 1 or len(status[0]) != 2:
        return "error", "Invalid check_status.tsv", test_results, additional_files
    state, description = status[0][0], status[0][1]

    try:
        results_path = os.path.join(result_folder, "test_results.tsv")
        test_results = list(csv.reader(open(results_path, 'r'), delimiter='\t'))
        if len(test_results) == 0:
            raise Exception("Empty results")

        return state, description, test_results, additional_files
    except Exception:
        if state == "success":
            state, description = "error", "Failed to read test_results.tsv"
        return state, description, test_results, additional_files

def get_commit(gh, commit_sha):
    repo = gh.get_repo(os.getenv("GITHUB_REPOSITORY", "ClickHouse/ClickHouse"))
    commit = repo.get_commit(commit_sha)
    return commit

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    repo_path = os.path.join(os.getenv("GITHUB_WORKSPACE", os.path.abspath("../../")))
    temp_path = os.path.join(os.getenv("RUNNER_TEMP", os.path.abspath("./temp")), 'style_check')

    with open(os.getenv('GITHUB_EVENT_PATH'), 'r') as event_file:
        event = json.load(event_file)
    pr_info = PRInfo(event)

    if not os.path.exists(temp_path):
        os.makedirs(temp_path)

    gh = Github(get_best_robot_token())

    images_path = os.path.join(temp_path, 'changed_images.json')
    docker_image = 'clickhouse/style-test'
    if os.path.exists(images_path):
        logging.info("Images file exists")
        with open(images_path, 'r') as images_fd:
            images = json.load(images_fd)
            logging.info("Got images %s", images)
            if 'clickhouse/style-test' in images:
                docker_image += ':' + images['clickhouse/style-test']

    logging.info("Got docker image %s", docker_image)
    for i in range(10):
        try:
            subprocess.check_output(f"docker pull {docker_image}", shell=True)
            break
        except Exception as ex:
            time.sleep(i * 3)
            logging.info("Got execption pulling docker %s", ex)
    else:
        raise Exception(f"Cannot pull dockerhub for image {docker_image}")

    s3_helper = S3Helper('https://s3.amazonaws.com')

    subprocess.check_output(f"docker run -u $(id -u ${{USER}}):$(id -g ${{USER}}) --cap-add=SYS_PTRACE --volume={repo_path}:/ClickHouse --volume={temp_path}:/test_output {docker_image}", shell=True)
    state, description, test_results, additional_files = process_result(temp_path)
    report_url = upload_results(s3_helper, pr_info.number, pr_info.sha, test_results, additional_files, NAME)
    print("::notice ::Report url: {}".format(report_url))
    commit = get_commit(gh, pr_info.sha)
    commit.create_status(context=NAME, description=description, state=state, target_url=report_url)
