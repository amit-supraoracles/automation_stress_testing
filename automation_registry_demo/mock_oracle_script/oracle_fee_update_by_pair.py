# python3 ./mock_oracle_script/oracle_fee_update_by_pair.py --pair 0 --value 862000000000000000000000 --decimal 18
# python3 ./mock_oracle_script/oracle_fee_update_by_pair.py --pair 1 --value 2280000000000000000000 --decimal 18

import argparse
import time
import subprocess

API_URL = 'https://rpc-autonet.supra.com/rpc/v2/view'
FUNCTION_ID = "0xd4e92056cb0acf11f792ae143f74bc8a2bbbffd4af5d850e18c9da0b30bf1c0e::supra_oracle_storage::mock_price_feed"

# Parse command-line arguments
parser = argparse.ArgumentParser(description="Process pair, value, and decimal.")
parser.add_argument('--pair', type=str, required=True, help='The pair value (e.g., 1)')
parser.add_argument('--value', type=int, required=True, help='The value (e.g., 1000000)')
parser.add_argument('--decimal', type=int, required=True, help='The decimal (e.g., 18)')
args = parser.parse_args()

# Assign values from arguments
pair = args.pair
value = args.value
decimal = args.decimal

# Generate timestamp and round
timestamp = int(time.time())
round = timestamp

# Construct the CLI command as a list of arguments
cli_command = [
    'supra', 'move', 'tool', 'run',
    '--function-id', FUNCTION_ID,
    '--args', f'u32:{pair}', f'u128:{value}', f'u16:{decimal}', f'u64:{timestamp}', f'u64:{timestamp}'
]

# Print the CLI command for debugging
print("Executing CLI command:", " ".join(cli_command))

# Execute the CLI command
try:
    subprocess.run(cli_command, check=True)
except subprocess.CalledProcessError as e:
    print(f"Error executing CLI command: {e}")
