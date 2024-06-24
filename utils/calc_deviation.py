import numpy as np
import argparse

def load_data(filename):
    try:
        with open(filename, 'r') as file:
            data = []
            for line in file.readlines():
                line = line.strip()
                fields = line.split()
                data.append((int(fields[0]), fields[1]))
        return data
    except FileNotFoundError:
        print("File not found.")
        return []

def main():
    # Get input parameters
    parser = argparse.ArgumentParser(description="Calculate deviation of observed values with respect to optimal values.")
    parser.add_argument("nnodes", type=int, help="Number of nodes.")
    parser.add_argument("filename", help="Name of the file containing the process distribution data.")
    args = parser.parse_args()

    filename = args.filename
    nnodes = args.nnodes

    # Load data
    data_list = load_data(filename)

    # Extract values from data
    while len(data_list) < nnodes:
        data_list.append((0,str(len(data_list))))
    sum_counts = 0
    for i in range(len(data_list)):
        sum_counts += data_list[i][0]
    observed_values = []
    optimal_values = []
    for i in range(len(data_list)):
        observed_values.append(data_list[i][0]/sum_counts)
        optimal_values.append(1/nnodes)

    # Convert types
    observed_values = np.array(observed_values)
    optimal_values = np.array(optimal_values)

    # Mean Absolute Error (MAE)
    mae = np.mean(np.abs(observed_values - optimal_values))

    # Mean Squared Error (MSE)
    mse = np.mean((observed_values - optimal_values)**2)

    # Root Mean Squared Error (RMSE)
    rmse = np.sqrt(mse)

    # R-squared
    ss_res = np.sum((observed_values - optimal_values)**2)
    ss_tot = np.sum((observed_values - np.mean(observed_values))**2)
    r_squared = 1 - (ss_res / ss_tot)

    print("MAE:", mae)
    print("MSE:", mse)
    print("RMSE:", rmse)
    print("R-squared:", r_squared)

if __name__ == "__main__":
    main()
