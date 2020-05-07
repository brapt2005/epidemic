# Implementation of a simple network model for the study of epidemics

#### Author:

Vasilios E. Raptis  
  
#### Contact: 

    brapt@iacm.forth.gr  
  
**Version**        :   1.0.0  

**Release date**   :   May 7th, 2020  


## 1. Introduction
This project contains all the software that was developed and employed  to carry 
out the calculations reported in the article "COVID-19: An escape route from the 
Symplegades of hygienic crisis and economic meltdown" to appear in some preprint 
server soon. The project consists of a program in Fortran, implementing a simple 
network model to predict contagion of an infective disease;  an auxiliary module 
borrowed from my POLYANA project;  a shell script that launched the calculations 
mentioned in the article; a sample input file; and the Makefile.  

In the below paragraphs, a Linux environment (bash shell) is assumed. It should 
be very easy to adapt the instructions to other environments.  

## 2. How to build and run the program 

### Compilation 
If you have gfortran installed, this is straightforward. Just type  

    make  

press Enter, and an executable called *epidemic* will appear in your folder. If 
you use another Fortran compiler you have to edit Makefile accordingly.  

### Running the program 
Provided an input file is in place, you just have to call the executable  
 
    ./epidemic

and you will see something like the following in your screen:  

    ******************** Run Nr   1 completed  
    ******************** Run Nr   2 completed  
    ******************** Run Nr   3 completed  
    ******************** Run Nr   4 completed  
    ******************** Run Nr   5 completed  

(The number of asterisks and lines will vary with simulation details defined in 
the input file. Each asterisk denotes two simulation steps.)  

With the end of the simulation,  two more files are generated,  called 'output' 
and 'statistics'. These are discussed in Section 4.  

## 3. Input explained 
Input is read from a file called 'input' and consists of a few lines containing 
directives followed by appropriate arguments.  Comments can be placed  in these 
lines or separate lines by placing a sharp (#) mark. 
The program ignores everything after the '#' characters.  

The directives understood by the program, are summarised in the table below:  

        Directive     | Description
        ---           | ---
        runs *n*      | Run *n* independent simulations in one batch 
        general       | General population described by three arguments as below:
          *n1*        | Population size
          *n2*        | How many can be infected by an individual in one step
          *n3*        | Standard deviation of *n2* (see next section for details)
        super         | Subpopulation of superspreaders described by three arguments
          *n1*        | How many members of total population are superspreaders
          *n2*        | How many can be infected by a superspreader in one step
          *n3*        | Standard deviation of *n2* (see next section for details)
        simulation    | Simulation details determined by three arguments
          *n1*        | Simulation steps
          *n2*        | Steps it takes for infected individual to gain immunity
          *n3*        | Steps from start of simulation, superspreaders are active

## 4. Output explained 

### File 'output' 

This file consists of 5 columns:  

* Column 1: Simulation steps  
* Column 2: Number of susceptible individuals defined as ones that have not been
            infected or recovered yet.  
* Column 3: Number of infected individuals at given simulation step.  
* Column 4: Number of all individuals that have recovered so far and are immune 
            to the disease.  
* Column 5: Cumulative number of all infection cases so far whether recovered or 
            not.  

If more than one simulations are carried out in one batch (see directive *runs*) 
results from each simulation are stored in sections consisting of above columns. 
Consecutive sections are separated by two blank lines. This is a suitable format 
for plotting runs separately with the *gnuplot* package.  

### File 'statistics'  

This file summarises the information contained in *output* as averages over all 
runs and error bars (standard deviations). It consists of the following columns:  
  
* Column  1: Simulation steps  
* Column  2: Number of susceptible individuals for given step, averaged over all 
             runs.  
* Column  3: Standard deviation of susceptible individuals at given time step.  
* Column  4: Average number of infected individuals at given step, computed over 
             all runs.  
* Column  5: Standard deviation of infected individuals at given step.  
* Column  6: Average number of immune individuals computed over all runs for the 
             given time step.  
* Column  7: Standard deviation of immune individuals at given time step.  
* Column  8: Cumulative number of all infection cases so far  whether recovered 
             or not, averaged over all runs.  
* Column  9: Standard deviation of average cumulative number of cases.  
* Column 10: Average over all runs, of effective reproduction rate at given time 
             step. This is defined as the number of new infections taking place 
             during that step  over the number of individuals that were already 
             infected (but had not yet recovered) at the time.  
* Column 11: Standard deviation of effective reproduction rate.  

## 5. The companion script 

This script calls epidemic three times  to simulate three alternative scenaria, 
namely a homogeneous population where all individuals have the same transmission 
capacity; a population with a small minority of highly infectious individuals or 
'superspreaders'; and a population with an infectious minority that is isolated 
after 10 simulation steps.  

With each call to epidemic, the corresponding file containing simulation details 
is copied to input.  

Then, a script is generated that contains commands of the gnuplot package. This 
script allows users to inspect two diagrams (infected and immune individuals vs.
simulation steps in linear and logarithmic scale) that are saved as png images.  

## 6. A glance at the program's internals  
After reading input  and initialising some arrays holding information  about the 
population and the state (susceptible, infected, immune) of individuals, a loop 
is carried out over a user-defined number of simulations.  

During a simulation,  first an individual is picked at random  and acquires the 
status INFECTED.  Then, with every simulation step,  a loop is carried out over 
all individuals.  Each one is checked to see if it is infected and if so, one of 
the following happens:  

* If current step is more than a user-defined number of steps past the time that 
the individual was infected, it recovers and acquires the status IMMUNE.  
* Otherwise, a random number x is sampled from a normal distribution centered at 
the number of contacts (transmission rate) of the individual with the constraint 
x > 0, and the nearest integer, *n*, is taken.  
* A loop over *n* randomly chosen contacts is carried out; if these contacts are 
not infected or immune, their status switches from SUSCEPTIBLE to INFECTED.  

During the above process  a histogram is updated  together with an array holding 
data for statistical calculations.  Integers and single precision reals are used 
throughout,  except for the variables involved in computing standard deviations 
that are double precision, because truncation errors may lead to faulty results.  

The normal distribution is sampled with the aid of an approximate expression for 
the inverse error function based on the work by Sergei Winitzki, namely  

* S. Winitzki,  Uniform approximations for transcendental functions,  in Proc. 
ICCSA-2003, LNCS 2667/2003, p. 962.  
* S. Winitzki,  A handy approximation for the error function and its inverse (an 
unpublished manuscript that can be found online by searching its title).  
 
This is combined with the cumulative distribution function:  

F(x) = [1+erf((x-mu)/sigma/sqrt(2))]/2  

to sample the normal distribution.  

## 9. How to cite 
Please cite as follows: 

Vasilios Raptis, 
Implementation of a simple network model for the study of epidemics, 
https://github.com/brapt2005/epidemic (accessed on: ... insert date...)

## 10. Legal stuff, etc.
This program implements a simple model of social networks to look at infectious 
disease epidemics. It is freely distributed under the MIT license.  

### License

Copyright (c) 2020 Vasilios E. Raptis <brapt@iacm.forth.gr>  

Permission is hereby granted, free of charge, to any person obtaining a 
copy of this software and associated documentation files (the "Software"), 
to deal in the Software without restriction, including without limitation 
the rights to use, copy, modify, merge, publish, distribute, sublicense, 
and/or sell copies of the Software, and to permit persons to whom the 
Software is furnished to do so, subject to the following conditions:  

The above copyright notice and this permission notice shall be included 
in all copies or substantial portions of the Software.  

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS 
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
DEALINGS IN THE SOFTWARE.  


