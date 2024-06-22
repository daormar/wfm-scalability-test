# Set the output file name and format
set terminal pngcairo enhanced font 'arial,16' size 800, 600
set output 'cpu_evol_plot.png'

# Set plot title and labels
set title "CPU Experiments"
set xlabel "Time (s)"
set ylabel "CPU (%)"
set key top left
set logscale y

# color definitions
set border linewidth 1.5
set style line 1 lc rgb '#800000' lt 1 lw 2
set style line 2 lc rgb '#ff0000' lt 1 lw 2
set style line 3 lc rgb '#ff4500' lt 1 lw 2
set style line 4 lc rgb '#ffa500' lt 1 lw 2
set style line 5 lc rgb '#006400' lt 1 lw 2
set style line 6 lc rgb '#0000ff' lt 1 lw 2

# Add plot command
