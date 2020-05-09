!
! Copyright (c) 2020 Vasilios E. Raptis <brapt@iacm.forth.gr>
!
! Permission is hereby granted, free of charge, to any person obtaining a copy
! of this software and associated documentation files (the "Software"), to deal
! in the Software without restriction, including without limitation the rights
! to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
! copies of the Software, and to permit persons to whom the Software is
! furnished to do so, subject to the following conditions:
!
! The above copyright notice and this permission notice shall be included in
! all copies or substantial portions of the Software.
!
! THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
! IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
! FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
! AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
! LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
! OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
! THE SOFTWARE.
!
!-----------------------------------------------------------------------
!
program epidemic
    use strings
    implicit none
    integer, parameter :: dblpr=kind(1.0d0)
    integer, parameter :: INPUT=10,OUTPUT=11,STAT=12
    integer, parameter :: SQSUM=0,SUMSQ=1
    integer, parameter :: SUSCEPTIBLE=0,INFECTED=1,IMMUNE=2,CASES=3,REPRAT=4
    integer, parameter :: GENERAL=1,SUPERSPREADER=2
    real   , parameter :: alpha=0.147    ! for approx expression for inverse error function
    real   , parameter :: PI=4.0*atan(1.0)
    real   , parameter :: sqr2=sqrt(2.0)
    type population_t
        integer capacity
        integer state
        integer time_of_infection
        real contacts
        real contacts_sigma
    end type population_t
    integer i,individual,irun,j,M
    integer N,Nruns,Nsim,Nstop,Nt,n_connect,other,step
    integer histogram(SUSCEPTIBLE:CASES)
    real c,cs,nh,r,sc,scs
    real(dblpr) x,ncon
    real(dblpr), allocatable :: statistics(:,:)
    type (population_t), allocatable :: population(:)
    ! Executable part starts here: 
    open(unit=INPUT,file='input')
    do while(get_record(input))
        i=strstr("#",record)    ! remove comments
        if(i==0) &
            i=RECLEN
        if(strstr("runs",record(1:i))>0)       &           ! how many simulations to run
            read(record(postok(2,record):),*) Nruns        !      
        if(strstr("general",record(1:i))>0)    &           ! parameters for the general population
            read(record(postok(2,record):),*) N,c,cs       ! population size, contacts, sigma
        if(strstr("super",record(1:i))>0)      &           ! parameters for the superspreaders
            read(record(postok(2,record):),*) M,sc,scs     ! number, contacts and sigma of superspr.
        if(strstr("simulation",record(1:i))>0) &           ! simul. details (steps, time one can transmit) 
            read(record(postok(2,record):),*) Nsim,Nt,Nstop! the virus, time to deactivate superspr.)
    enddo
    close(unit=INPUT)
    ! Set up population 
    allocate(statistics(SUSCEPTIBLE:2*REPRAT+1,Nsim))
    histogram (SUSCEPTIBLE   )=N
    histogram (INFECTED:CASES)=0
    statistics=0.0d0
    allocate(population(N))
    do individual=1,N-M
        population(individual)%capacity=GENERAL
        population(individual)%state=SUSCEPTIBLE
        population(individual)%time_of_infection=Nsim+1
        population(individual)%contacts=c
        population(individual)%contacts_sigma=cs
    enddo
    ! Add superspreaders, if any 
    do individual=N-M+1,N
        population(individual)%capacity=SUPERSPREADER
        population(individual)%state=SUSCEPTIBLE
        population(individual)%time_of_infection=Nsim+1
        population(individual)%contacts=cs
        population(individual)%contacts_sigma=scs
    enddo
    open(unit=OUTPUT,file='output'    )
    open(unit=STAT  ,file='statistics')
    write(STAT,'("#",2X,"Steps",2X)',advance='no')
    write(STAT,'("|",6X,"Susceptible",6X)',advance='no')
    write(STAT,'("|",8X,"Infected",8X)',advance='no')
    write(STAT,'("|",9X,"Immune",9X)',advance='no')
    write(STAT,'("|",9X,"Cases",10X)',advance='no')
    write(STAT,'("|",6X,"Effective R0",5X,"|")')
    write(STAT,'("#---------")',advance='no')
    do i=1,5
        write(STAT,'("+-----------------------")',advance='no')
    enddo
    write(STAT,'("|")')
    do irun=1,Nruns ! loop over simulation runs  
        write(OUTPUT,'(5I10)')0,histogram
        ! Infect someone: 
        CALL init_random_seed
        individual=random_pick(N)
        population(individual)%state=INFECTED
        population(individual)%time_of_infection=0
        histogram(SUSCEPTIBLE)=histogram(SUSCEPTIBLE)-1
        histogram(INFECTED   )=histogram(INFECTED   )+1
        histogram(CASES      )=histogram(CASES      )+1
        write(OUTPUT,'(5I10)')1,histogram
        ! Start spreading the virus
        do step=1,Nsim
            ! Deactivate superspreaders (if so desired)
            if(M>0 .AND. step>Nstop) &
                population(N-M+1:N)%state=IMMUNE
            ! Go on spreading
            ncon=0.0d0
            nh=histogram(INFECTED)
            do individual=1,N
                if(population(individual)%state==INFECTED) then
                    if(step-population(individual)%time_of_infection>Nt) then
                        population(individual)%state=IMMUNE
                        histogram(INFECTED)=histogram(INFECTED)-1
                        histogram(IMMUNE  )=histogram(IMMUNE  )+1
                    ! meaning of following condition: 
                    ! infect others at least one simulation step past own infection 
                    else if(population(individual)%time_of_infection<step) then 
                        ! sample normal distribution, then take nearest integer
                        CALL random_number(r)
                        c =population(individual)%contacts
                        cs=population(individual)%contacts_sigma
                        x =c+sqr2*cs*inverr(2.0*r-1.0)
                        x =max(0.0d0,x)
                        n_connect=nint(x)
                        ! that's it; let's infect some more fellow citizens
                        do j=1,n_connect
                            other=random_pick(N)                            
                            if(other/=individual .AND. population(other)%state==SUSCEPTIBLE) then
                                ncon=ncon+1.0d0
                                population(other)%state=INFECTED
                                population(other)%time_of_infection=step
                                histogram(SUSCEPTIBLE)=histogram(SUSCEPTIBLE)-1
                                histogram(INFECTED   )=histogram(INFECTED   )+1
                                histogram(CASES      )=histogram(CASES      )+1
                            endif
                         enddo
                    endif
                endif
            enddo
            if(nh>0) then
                write(OUTPUT,'(5I10,F10.5)')step,histogram,ncon/dble(nh)
            else
                write(OUTPUT,'(5I10      )')step,histogram
            endif
            !if(nh>0) then
            !    write(stdout,'(5I10,F10.5)')step,histogram,ncon/dble(nh)
            !else
            !    write(stdout,'(5I10      )')step,histogram
            !endif
            if(mod(step,2)==0) &
                write(stdout,'("*")',advance='no')
            do i=SUSCEPTIBLE,2*CASES,2
                x=dble(histogram(i/2))
                statistics(i+SQSUM,step)=statistics(i+SQSUM,step)+x
                statistics(i+SUMSQ,step)=statistics(i+SUMSQ,step)+x**2
            enddo
            if(nh>0) then
                x=ncon/dble(nh)
                i=2*REPRAT
                statistics(i+SQSUM,step)=statistics(i+SQSUM,step)+x
                statistics(i+SUMSQ,step)=statistics(i+SUMSQ,step)+x**2
            endif
        enddo   ! end simulation 
        write(stdout,'(" Run Nr",I4," completed")')irun
        write(OUTPUT,'(/)')
        ! Reset population 
        histogram (SUSCEPTIBLE   )=N
        histogram (INFECTED:CASES)=0
        population(:)%time_of_infection=Nsim+1
        population(:)%state=SUSCEPTIBLE
    enddo   ! end loop over runs
    do step=1,Nsim
        write(STAT,'(I10)',advance='no')step
        do i=SUSCEPTIBLE,2*CASES,2
            write(STAT,'(F12.1,F12.3)',advance='no') & 
            statistics(i+SQSUM,step)/dble(Nruns),stdev(Nruns,statistics(i+SQSUM:i+SUMSQ,step))
        enddo
        i=2*REPRAT
        write(STAT,'(F12.3,F12.3)',advance='yes') & 
        statistics(i+SQSUM,step)/dble(Nruns),stdev(Nruns,statistics(i+SQSUM:i+SUMSQ,step))
    enddo
    close(unit=STAT  )
    close(unit=OUTPUT)
contains
    integer function random_pick(n)
        implicit none
        integer n
        real r
        CALL random_number(r)
        random_pick=int(real(n)*r)+1
        return
    end function random_pick   
!---
    real function inverr(r)
        ! approximation for inverse error function 
        ! (from S. Winitzki's work - see README file)
        implicit none
        real ln,r
        ln=log(1-r*r)
        inverr=(2.0/PI/alpha+ln/2.0)**2
        inverr=sqrt(inverr-ln/alpha)
        inverr=inverr-(2.0/PI/alpha+ln/2.0)
        inverr=sign(1.0,r)*sqrt(inverr)
        return
    end function inverr  
!---
    real(dblpr) function var(n,x)
        implicit none
        integer n
        real(dblpr) x(SQSUM:SUMSQ)
        real(dblpr) sum_sq,sq_sum
        if(n==1) then
            var=0.0d0
        else
            sq_sum=(x(SQSUM))**2
            sum_sq= x(SUMSQ)
            var=(sum_sq-sq_sum/dble(n))/dble(n-1)
            if(var<0.0) then
                !print*,x
                !print*,sum_sq-sq_sum/dble(n),n
                !STOP
                var=0.0d0   ! some ncon samples miss some entries so just skip them
            endif            
        endif
        return
    end function var
!---
    real(dblpr) function stdev(n,x)
        implicit none
        integer n 
        real(dblpr) x(SQSUM:SUMSQ)
        stdev=sqrt(var(n,x))
        return
    end function stdev
end program epidemic
!   
!---
!   
subroutine init_random_seed()   
! Source: https://stackoverflow.com/questions/18754438/generating-random-numbers-in-a-fortran-module
INTEGER :: i, n, clock       
INTEGER, DIMENSION(:), ALLOCATABLE :: seed       
CALL RANDOM_SEED(size = n)       
ALLOCATE(seed(n))       
CALL SYSTEM_CLOCK(COUNT=clock)       
seed = clock + 37 * (/ (i - 1, i = 1, n) /)       
CALL RANDOM_SEED(PUT = seed)       
DEALLOCATE(seed) 
end subroutine init_random_seed 
