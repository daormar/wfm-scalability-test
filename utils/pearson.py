import scipy
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
    parser = argparse.ArgumentParser(description="Calculate Pearson's correlation coefficient.")
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
    x_values = []
    y_values = []
    for i in range(len(data_list)):
        x_values.append(data_list[i][0]/sum_counts)
        y_values.append(1/nnodes)

    # Obtain Pearson's correlation coefficient
    c = scipy.stats.pearsonr(x_values, y_values)

    # Print result
    print(c)

if __name__ == "__main__":
    main()
