import csv
import json
import os
from typing import List
import subprocess


def flatten_statical_metrics_data(key_prefix: str, statical_data: dict) -> dict:
    return {
        f"{key_prefix}_min": statical_data["min"]["data"],
        f"{key_prefix}_max": statical_data["max"]["data"],
        f"{key_prefix}_mean": statical_data["mean"],
    }


def prepare_metrics(
    bin_dir_path: str,
    experiments_data_dir_path: str,
    parsed_metrics_file_name: str,
    epoch_indexes: List[List[int]],
):
    metrics_parser_bin_path = os.path.join(
        bin_dir_path, "automation-network-metrics-parser"
    )
    process_envs = os.environ.copy()
    process_envs["RUST_BACKTRACE"] = "1"
    for indexes, dir_entry in zip(
        epoch_indexes,
        sorted(os.scandir(experiments_data_dir_path), key=lambda d: d.path),
    ):
        process_envs["METRICS_LOG_FILE"] = str(
            os.path.join(dir_entry.path, "smr_node_logs/metrics.log")
        )
        process_envs["EPOCH_INDEX_START"] = str(indexes[0])
        process_envs["EPOCH_INDEX_END"] = str(indexes[1])
        process_envs["PARSED_METRICS_FILE_PATH"] = str(
            os.path.join(dir_entry.path, parsed_metrics_file_name)
        )
        print(f"Generating metrics of {dir_entry.name} experiment")
        subprocess.run([metrics_parser_bin_path], check=True, env=process_envs)


def main():
    bin_dir_path = "../bin"
    experiments_data_dir_path = "../data/experiments"
    epoch_indexes = [[80, 85],[5,10], [5, 10], [40, 45]]
    parsed_metrics_file_name = "parsed_metrics.json"
    aggregated_metrics_file_path = "../data/aggregated_metrics.csv"
    targeted_statical_metrics_data_name = [
        "total_blocks_stats",
        "boundary_block_execution_time_stats",
        "automation_task_load_time_stats",
        "transactions_execution_time_stats",
        "block_execution_time_stats",
    ]
    flattened_statical_metrics_data_keys = ["tx_block_size"]
    for name in targeted_statical_metrics_data_name:
        flattened_statical_metrics_data_keys.extend(
            [f"{name}_min", f"{name}_max", f"{name}_mean"]
        )

    prepare_metrics(
        bin_dir_path, experiments_data_dir_path, parsed_metrics_file_name, epoch_indexes
    )
    print("Preparing aggregated metrics")
    data = []
    for dir_entry in sorted(
        os.scandir(experiments_data_dir_path), key=lambda d: d.path
    ):
        with open(os.path.join(dir_entry.path, parsed_metrics_file_name)) as file:
            parsed_metrics = json.load(file)
            row = {}
            row.update({flattened_statical_metrics_data_keys[0]: dir_entry.name})
            for name in targeted_statical_metrics_data_name:
                row.update(flatten_statical_metrics_data(name, parsed_metrics[name]))
            data.append(row)

    with open(aggregated_metrics_file_path, "w", newline="") as csvfile:
        fieldnames = flattened_statical_metrics_data_keys
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(data)


if __name__ == "__main__":
    main()
