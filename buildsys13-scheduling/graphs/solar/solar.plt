set terminal postscript eps enhanced "Helvetica" 24  
set size 1.0,0.8 
set output "solar.eps"
set ylabel 'Power (kW)' font "Helvetica,28" 
set xlabel 'Time (minutes)' font "Helvetica,28" 
set border 3 
set ytics nomirror font "Helvetica,22" 
set xtics nomirror 12 font "Helvetica,22" 
set xtics ("7am" 420, "11am" 660, "5pm" 1020, "8pm" 1200)
set ytics auto
set yr [0:10]
set xr [390:1200]
set key top right
plot "solar.txt" using 1:2 axes x1y1 title "" with lines lw 5
exit



