import argparse

def load_data(filename):
    try:
        with open(filename, 'r') as file:
            tools = set()
            data_points = {}
            for line in file.readlines():
                line = line.strip()
                fields = line.split()
                tool = fields[0]
                tools.add(tool)
                n = fields[3]
                time = fields[4]
                if n in data_points:
                    data_points[n][tool] = time
                else:
                    data_points[n]={tool:time}
            return tools, data_points
    except FileNotFoundError:
        print("File not found")
        return set(), {}

def print_data(tools, data_points):
    # Obtain tool list
    tool_list = list(tools)

    # Print header row
    header = "x"
    for i in range(len(tool_list)):
        header += "," + tool_list[i]
    print(header)

    # Print rest of rows
    for n in data_points:
        row = str(n)
        for i in range(len(tool_list)):
            if tool_list[i] in data_points[n]:
                row += "," + data_points[n][tool_list[i]]
            else:
                row += ","
        print(row)

def main():
    # Get input parameters
    parser = argparse.ArgumentParser(description="Generate n value experiments data.")
    parser.add_argument("filename", help="Name of the file containing the n value experiments data.")
    args = parser.parse_args()

    filename = args.filename

    # Load data
    tools, data_points = load_data(filename)

    # Print data
    print_data(tools, data_points)

if __name__ == "__main__":
    main()
