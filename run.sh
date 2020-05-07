#
# Copyright (c) 2020 Vasilios E. Raptis <brapt@iacm.forth.gr>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
#-----------------------------------------------------------------------
#
#
echo "Run without superspreading"
cp input1 input
./epidemic 
cp output     general.out
cp statistics general.dat
echo "Run with superspreading"
cp input2 input
./epidemic 
cp output     super.out
cp statistics super.dat
echo "Superspreaders isolated at step 10"
cp input3 input
./epidemic 
cp output     isolate.out
cp statistics isolate.dat

rm -f epidemic.gp
touch epidemic.gp

# This is the gnuplot script
read -r -d '' SCRIPT <<- scriptdelimiter
    set term wxt
    set key left
    set yrange[0:12000000]
    set grid
    set style line 100 lt 1 lc rgb "gray50" lw 2
    set border ls 100
    set size ratio 0.75
    set xlabel 'Simulation steps' offset 0,0
    set ylabel 'Number of individuals' rotate by 90 offset 0,0
    set xtics offset 0.3,0 textcolor rgb "gray10"
    set ytics textcolor rgb "gray10"
    set xzeroaxis ls 100 
    p 'general.dat' u 1:4:5 t 'No superspr.: Infected' w yerrorlines lw 1
    rep 'general.dat' u 1:6:7 t 'No superspr.: Immune' w yerrorlines lw 1
    rep 'super.dat' u 1:4:5 t 'With superspr.: Infected' w yerrorlines lw 1
    rep 'super.dat' u 1:6:7 t 'With superspr.: Immune' w yerrorlines lw 1
    rep 'isolate.dat' u 1:6:7 t 'Isolated superspr.: Immune' w yerrorlines ls 100
    pause -1
    set term png enhanced
    set output 'epidemic.png'
    set term wxt
    set yrange[1:100000000]
    set logscale y
    unset key
    p 'general.dat' u 1:6:7 t 'No superspr.: Immune' w yerrorlines lw 1
    rep 'super.dat' u 1:6:7 t 'With superspr.: Immune' w yerrorlines lw 1
    rep 'isolate.dat' u 1:6:7 t 'Isolated superspr.: Immune' w yerrorlines ls 100
    pause -1
    set term png enhanced
    set output 'logscale.png'
    rep
scriptdelimiter

echo "$SCRIPT" >> epidemic.gp

gnuplot epidemic.gp

# rm epidemic.gp
