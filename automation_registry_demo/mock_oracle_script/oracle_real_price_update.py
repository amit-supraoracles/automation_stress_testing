import requests
import subprocess

# API endpoint and payload
url = 'https://rpc-mainnet.supra.com/rpc/v1/view'
headers = {
    'accept': 'application/json',
    'Content-Type': 'application/json'
}
payload = {
    "function": "0xe3948c9e3a24c51c4006ef2acc44606055117d021158f320062df099c4a94150::supra_oracle_storage::get_prices",
    "type_arguments": [],
    "arguments": [[500, 0, 1, 14, 10, 49, 3, 16, 2, 5]]
}

# Make the POST request
response = requests.post(url, headers=headers, json=payload)

# Check if the request was successful
if response.status_code == 200:
    # Parse the JSON response
    data = response.json()
    
    # Extract the result array
    result_array = data["result"][0]
    
    # Initialize lists to store values
    pairs = []
    values = []
    decimals = []
    timestamps = []
    rounds = []

    # Iterate through each item in the result array
    for item in result_array:
        # Append values to the respective lists
        pairs.append(int(item["pair"]))  # u32
        values.append(int(item["value"]))  # u128
        decimals.append(int(item["decimal"]))  # u16
        timestamps.append(int(item["timestamp"]))  # u64
        rounds.append(int(item["round"]))  # u64
        
    # Construct the CLI command
    cli_command = [
        "supra-old",  # CLI tool
        "move", "tool", "run",
        "--function-id", "0xd4e92056cb0acf11f792ae143f74bc8a2bbbffd4af5d850e18c9da0b30bf1c0e::supra_oracle_storage::mock_price_feed_bulk",
        "--args",
        f'u32:{pairs}',  # Pair (u32)
        f'u128:{values}',  # Value (u128)
        f'u16:{decimals}',  # Decimal (u16)
        f'u64:{timestamps}',  # Timestamp (u64)
        f'u64:{rounds}'  # Round (u64)
    ]

    # Print the CLI command for debugging
    print("Executing CLI command:", " ".join(cli_command))
            
    # Execute the CLI command
    try:
        subprocess.run(cli_command, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error executing CLI command: {e}")

else:
    print(f"Error: {response.status_code} - {response.text}")
