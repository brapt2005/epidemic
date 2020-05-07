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
# some variables
program    = epidemic
compiler   = gfortran
#options    =-cpp
#options    =-cpp -funroll-loops
options    =-cpp -fbounds-check -std=f2003 -Wall -Wextra
fixoptions =
objects    = epidemic.o strings.o 
modules    = epidemic.mod strings.mod   
          
# the target for the executable
epidemic: $(objects)
	$(compiler) -o $(program) $(objects)  

# compilation of sources
$(objects): %.o: %.f90
	$(compiler) -c $(options) $< -o $@

# dependencies for the project files
epidemic.o   :  strings.o    
strings.o    :     
   
clean: FORCE
	@make -s cleanme 
	
cleanme: FORCE  
	rm -f  $(objects) $(modules) $(program)
	
# use empty rule instead of .PHONY to comply with non-GNU make 
FORCE:
	 
