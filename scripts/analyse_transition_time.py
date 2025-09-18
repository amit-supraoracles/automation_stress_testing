import json
import re
import statistics
import csv

def parse_cycle_transitions(log_file):
    transition_data = []
    start_height = None

    with open(log_file, "r") as f:
        for line in f:
            # extract JSON payload inside EXECUTE_BLOCK log
            match = re.search(r'EXECUTE_BLOCK:(\{.*\})', line)
            if not match:
                continue

            try:
                data = json.loads(match.group(1))
            except json.JSONDecodeError:
                continue  # skip malformed lines

            # Look for START marker
            if "AUTOMATION_CYCLE_TRANSITION_START_BLOCK" in data:
                start_height = data.get("HEIGHT")

            # Look for END marker
            if "AUTOMATION_CYCLE_TRANSITION_END_BLOCK" in data:
                end_height = data.get("HEIGHT")
                exec_time = data.get("EXECUTE_BLOCK_S", None)

                if start_height is not None:
                    diff = end_height - start_height
                else:
                    diff = None  # in case START not seen

                transition_data.append({
                    "AUTOMATION_CYCLE_TRANSITION_START_BLOCK": start_height,
                    "AUTOMATION_CYCLE_TRANSITION_END_BLOCK": end_height,
                    "BLOCK_DIFF": diff,
                    "EXECUTE_BLOCK_S": exec_time
                })

                start_height = None  # reset for next cycle

    return transition_data


if __name__ == "__main__":
    log_file = "metrics.log"   # your metrics log file
    results = parse_cycle_transitions(log_file)

    # Collect execution times
    exec_times = [r['EXECUTE_BLOCK_S'] for r in results if r['EXECUTE_BLOCK_S'] is not None]

    # Print summary in console
    print("\nCycle Transition Analysis")
    print("=" * 80)
    print(f"{'AUTOMATION_CYCLE_TRANSITION_START_BLOCK':<35}"
          f"{'AUTOMATION_CYCLE_TRANSITION_END_BLOCK':<35}"
          f"{'BLOCK_DIFF':<12}"
          f"{'EXECUTE_BLOCK_S':<15}")
    print("-" * 80)

    for r in results:
        start = r['AUTOMATION_CYCLE_TRANSITION_START_BLOCK'] if r['AUTOMATION_CYCLE_TRANSITION_START_BLOCK'] is not None else "-"
        end = r['AUTOMATION_CYCLE_TRANSITION_END_BLOCK'] if r['AUTOMATION_CYCLE_TRANSITION_END_BLOCK'] is not None else "-"
        diff = r['BLOCK_DIFF'] if r['BLOCK_DIFF'] is not None else "-"
        exec_time = r['EXECUTE_BLOCK_S']
        exec_time_str = f"{exec_time:.6f}" if exec_time is not None else "-"
        print(f"{start:<35}{end:<35}{diff:<12}{exec_time_str:<15}")

    print("=" * 80)
    print(f"Total transitions found: {len(results)}")
    if exec_times:
        print(f"Min EXECUTE_BLOCK_S: {min(exec_times):.6f}")
        print(f"Max EXECUTE_BLOCK_S: {max(exec_times):.6f}")
        print(f"Mean EXECUTE_BLOCK_S: {statistics.mean(exec_times):.6f}\n")
    else:
        print("No EXECUTE_BLOCK_S values found.\n")

    # Save results to CSV
    csv_file = "cycle_transition_summary.csv"
    with open(csv_file, "w", newline="") as csv_out:
        fieldnames = [
            "AUTOMATION_CYCLE_TRANSITION_START_BLOCK",
            "AUTOMATION_CYCLE_TRANSITION_END_BLOCK",
            "BLOCK_DIFF",
            "EXECUTE_BLOCK_S"
        ]
        writer = csv.DictWriter(csv_out, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(results)

        # Append summary rows
        writer.writerow({})
        writer.writerow({"AUTOMATION_CYCLE_TRANSITION_START_BLOCK": "Total transitions",
                         "AUTOMATION_CYCLE_TRANSITION_END_BLOCK": len(results)})
        if exec_times:
            writer.writerow({"AUTOMATION_CYCLE_TRANSITION_START_BLOCK": "Min EXECUTE_BLOCK_S",
                             "AUTOMATION_CYCLE_TRANSITION_END_BLOCK": min(exec_times)})
            writer.writerow({"AUTOMATION_CYCLE_TRANSITION_START_BLOCK": "Max EXECUTE_BLOCK_S",
                             "AUTOMATION_CYCLE_TRANSITION_END_BLOCK": max(exec_times)})
            writer.writerow({"AUTOMATION_CYCLE_TRANSITION_START_BLOCK": "Mean EXECUTE_BLOCK_S",
                             "AUTOMATION_CYCLE_TRANSITION_END_BLOCK": statistics.mean(exec_times)})

    print(f"Results written to {csv_file}")
