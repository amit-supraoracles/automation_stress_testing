import requests
import numpy as np
import time
import pexpect  # For handling interactive prompts
import sys

DEFAULT_PASSWORD = ""  # Replace with your actual default password

# Configuration parameters
API_URL_MAINNET = 'https://rpc-mainnet.supra.com/rpc/v1/view'
API_URL = 'https://rpc-autonet.supra.com/rpc/v2/view'
FUNCTION_ID = "0xd4e92056cb0acf11f792ae143f74bc8a2bbbffd4af5d850e18c9da0b30bf1c0e::supra_oracle_storage::mock_price_feed_bulk"
PAYLOAD = {
    "function": "0xe3948c9e3a24c51c4006ef2acc44606055117d021158f320062df099c4a94150::supra_oracle_storage::get_prices",
    "type_arguments": [],
    "arguments": [[500, 0, 1, 14, 10, 49, 3, 16, 2, 5]]
}
HEADERS = {
    'accept': 'application/json',
    'Content-Type': 'application/json'
}
GAUSSIAN_MEAN = 0  # Mean for Gaussian distribution

# Dictionary to store the last updated values for each pair
last_updated_values = {}

# Dictionary to store the standard deviation multiplier for each pair_id
std_dev_multipliers = {
    500: 0.5,  # pair_id 500 = SUPRA/USDT
    0: 0.5,    # pair_id 0 = BTC/USDT
    1: 0.5,    # pair_id 1 = ETH/USDT
    14: 0.5,   # pair_id 14 = XRP/USDT
    10: 0.5,   # pair_id 10 = SOL/USDT
    49: 0.5,   # pair_id 49 = BNB/USDT 
    3: 0.5,    # pair_id 3 = DOGE/USDT
    16: 0.5,   # pair_id 16 = ADA/USDT
    2: 0.5,    # pair_id 2 = LINK/USDT
    5: 0.5     # pair_id 5 = AVAX/USDT
}

# Function to update values based on the last updated value
def update_values(result_array):
    global last_updated_values

    # Initialize lists to store values
    pairs = []
    values = []
    decimals = []
    timestamps = []
    rounds = []

    # Iterate through each item in the result array
    for item in result_array:
        pair = int(item["pair"])

        # Get the last updated value or use the current value if it's the first time
        current_value = last_updated_values.get(pair, float(item["value"]))

        # Get the standard deviation multiplier for this pair_id
        std_dev_multiplier = std_dev_multipliers.get(pair, 0.5)  # Default to 0.5 if pair_id is not found

        # Generate a random value from the Gaussian distribution
        random_offset = np.random.normal(GAUSSIAN_MEAN, std_dev_multiplier)

        # Update the value
        updated_value = current_value + (current_value * random_offset / 100)

        # Store the updated value for the next iteration
        last_updated_values[pair] = updated_value

        # Append values to the respective lists
        pairs.append(pair)  # u32
        values.append(int(updated_value))  # u128
        decimals.append(int(item["decimal"]))  # u16
        timestamps.append(int(time.time()))  # u64
        rounds.append(int(time.time()))  # u64

    return pairs, values, decimals, timestamps, rounds

# Make the POST request to fetch data only once
response = requests.post(API_URL_MAINNET, headers=HEADERS, json=PAYLOAD)

# Check if the request was successful
if response.status_code == 200:
    # Parse the JSON response
    data = response.json()

    # Extract the result array
    result_array = data["result"][0]

    # Main loop to execute at specific intervals
    while True:
        # Update values based on the last updated values
        pairs, values, decimals, timestamps, rounds = update_values(result_array)

        # Construct the CLI command
        cli_command = f'supra-old move tool run --function-id {FUNCTION_ID} --args "u32:{pairs}" "u128:{values}" "u16:{decimals}" "u64:{timestamps}" "u64:{rounds}"'

        # Print the CLI command for debugging
        print("Executing CLI command:", cli_command)

        # Execute the CLI command using pexpect
        try:
            child = pexpect.spawn(cli_command, timeout=30)  # Set timeout to avoid indefinite hang
            child.logfile = sys.stdout.buffer  # Print output in real-time

            child.expect("Enter your password:", timeout=5)
            child.sendline(DEFAULT_PASSWORD)

            child.expect(pexpect.EOF, timeout=10)
            print(child.before.decode())  # Print output before EOF
        except pexpect.exceptions.TIMEOUT:
            print("Timeout occurred while waiting for the command response.")
        except pexpect.exceptions.ExceptionPexpect as e:
            print(f"Error executing CLI command: {e}")

        # Wait for a specific interval before the next iteration
        time.sleep(60)  # Adjust the interval as needed (e.g., 60 seconds)
else:
    print(f"Error: {response.status_code} - {response.text}")
