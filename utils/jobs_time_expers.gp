# Set the output file name and format
set terminal pngcairo enhanced font 'arial,16' size 800, 600
set output 'jobs_time_expers_plot.png'

# Set plot title and labels
set title "Jobs-Time Experiments"
set xlabel "number of jobs"
set ylabel "Time (s)"
set key top left
set logscale x

# color definitions
set border linewidth 1.5
set style line 1 lc rgb '#800000' lt 1 lw 2
set style line 2 lc rgb '#ff0000' lt 1 lw 2
set style line 3 lc rgb '#ff4500' lt 1 lw 2
set style line 4 lc rgb '#ffa500' lt 1 lw 2
set style line 5 lc rgb '#006400' lt 1 lw 2
set style line 6 lc rgb '#0000ff' lt 1 lw 2

# Define data file and separator
datafile = "jobs_time_expers_data.csv"
set datafile separator ","

# Plot data using a loop for each column
plot for [col=2:*] datafile using 1:col with points ls col pt col title columnheader(col)
