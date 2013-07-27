set terminal postscript eps enhanced "Helvetica" 24  
set size 1.0,0.8 
set output "rate.eps"
set ylabel 'Rate ($/kWh)' font "Helvetica,28" 
set xlabel 'Time' font "Helvetica,28" 
set border 3 
set ytics nomirror font "Helvetica,22" 
set xtics nomirror 12 font "Helvetica,22" 
set xtics ("12am" 0, "7am" 7, "11am" 11, "5pm" 17, "7pm" 19, "11pm" 23)
set ytics auto
set yr [0:0.12]
set xr [0:24]
set key bottom right
set xtics   ("2am" 2, "5am" 5, "8am" 8, "11am" 11, "2pm" 14, "5pm" 17,"8pm" 20,"11pm" 23)
plot "ontario.txt" using ($1*0.989):2 axes x1y1 title "TOU" with lines lw 5,\
     "illinois.txt" using 1:2 axes x1y1 title "RTP" with lines lw 5
# Average Ontario Price: 8.233 US cents/kWh
# Average Illinois Price: 5.708 cents/kWh
exit



