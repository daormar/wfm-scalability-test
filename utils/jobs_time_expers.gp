# Set the output file name and format
set terminal pngcairo enhanced font 'arial,16' size 800, 600
set output 'jobs_time_expers_plot.png'

# Set plot title and labels
set title "Jobs-Time Experiments"
set xlabel "number of jobs"
set ylabel "Time (s)"
set key top left
set logscale x
set xrange [0.1:1000000]

# Define data file and separator
datafile = "jobs_time_expers_data.csv"
set datafile separator ","

# Define point types
PointType(i) = i
PointColor(i) = i

# Plot data using a loop for each column
plot datafile using 1:2:(PointType($0+1)):(PointColor($0+1)) with points lc variable pt variable ps 2 notitle, \
     '' using 1:2:3 with labels offset char 1,1 notitle
