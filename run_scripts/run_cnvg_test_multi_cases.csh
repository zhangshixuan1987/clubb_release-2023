#!/bin/csh
#SBATCH -A esmd 
#SBATCH -p slurm 
#SBATCH -N 1     
#SBATCH -t 24:00:00 
#SBATCH -J convergence_%j 
#SBATCH -o convergence_%j.out 
#SBATCH -e convergence_%j.err 

# Flag to run model compiling section 
set compile_model  = 1  # False: 0, True: 1

# Flag to run simulation section 
set run_model      = 1  # False: 0, True: 1

# Flag to run diagnose section. note: user needs to proprely setup 
# the environment for python in order to generate diagnostic figures 
set run_diagnostic = 1  # False: 0, True: 1

#user-specified code location, experiment name and model run directory 
set topdir = "/compyfs/zhan391/code/clubb_standalone_fnl/clubb_release-2023"
set expnam = "revwp3cl"
set wkdir  = "${topdir}/cnvg_${expnam}"
set outdir = "${topdir}/output"

if ( ! -d ${wkdir} ) then 
 mkdir -p ${wkdir}
endif 

if ( ! -d ${outdir} ) then
 mkdir -p ${outdir}
endif

#user-specified flags for configurations 
#options: 
# -default-rad: use radiation scheme in default case setup instead of turning it off 
# -default-micro: use microphysics in default case setups instead of turning it off
# -default-fc: using default setup for forcing (e.g. large-scale dynamics) which can be 
#              time dependent instead of setting the time-dependent forcing to .false. 
# -default-bc: using default setup for boundary condition (surface fluxes 
#              depend on grid spacing) instead of calculating surface fluxes 
#              with quantities at a fixed 20m model height 
# -default-ic: using default setup for initial condition (obtained with 
#              either linear interpolation on sounding profile
#              or constructed with formulations that depend on grid-space) 
#              instead of smoothed initial condition obtained with cubic-spline interpolation 
# -default-aterms: using default setup for turbulent advection terms 
#                  (pull "a coef." outside of the derivative) instead of 
#                  the standard formulation from continuous equation 
# -default-tau: using default formulation of eddy dissipation time scale (tau) for 
#               turbulent fluxes (employs a non-smoothed step function 
#               that can introduce discontinuities in model equations) instead of 
#               new formulations with smoothed Heaviside function   
# -default-df: using the default nonlinear numerical diffusion instead of linear numberical 
#              diffusion as discussed in clubb convergence paper               
# -default-spl: using default setup for wp2 splatting terms (non-zero and determined by C_wp2_splat 
#               parameter) instead of setting the term to zero (i.e. set C_wp2_splat = 0.0) 
# -default-lm: using the default setup for limiters on Brunt–Väisälä frequency and Richardson 
#              number instead of modified limiters as discussed in clubb convergence paper 
# -default-wp3cl: using the default setup for skewness clippings on wp3 instead of a new formulation 
#                 with smoothed Heaviside function   
# -godwp3: if specified, using Godunov upwinding discretization for turbulent advection
#          terms in wp3 equation instead of using cenctered-differencing scheme in 
#          default case setup in CLUBB 
# -godxpyp: if specified, using Godunov upwinding discretization for turbulent advection
#           terms in xpyp equations instead of using cenctered-differencing scheme in 
#           default case setup in CLUBB 
#Note: -godwp3 and -godxpyp are not discussed in clubb convergence paper 

#This script used to test the revised setups for convergence test in CLUBB-SCM. This includes 
# a. turn off radiation and mincrophysics parameterization   (no -default-rad -default-micro) 
# b. turn off C_wp2 splatting terms (i.e. C_wp2_splat = 0.0) (no -default-spl) 
# c. use standard turbulent advection term (i.e. a coef. inside vertical derivative) (no -default-aterms)
# d. use modified initial condition (with non-grid-dependent sounding profile + cubic-spline interpolation) (no -default-ic)
# e. use modified boundary condition (non time-dependent forcing + compute surface fluxes at fixed model height) (no -default-bc -default-fc)
# f. use modified limiters on the Brunt–Väisälä frequency and Richardson number (no -default-lm)
# g. smooth the eddy dissipation time scele for wpxp (with smoothed heaviside function) (no -default-tau)
# h. use the linear numerical diffusion instead of nonlinear numberical diffusion (no -default-df)
# i. use the smooth Heaviside function to construct the limiters for skewness clippings on wp3 (no -default-wp3cl)
set config_flags = ""
set dt_output    = 1800 # output frequency in seconds, default setup for convergence simulation
                        # is 600s (maximum time step size used for simulation)

#user-specified code and simulation run directory
#the default is the same as simulation setup in 
#clubb convergence paper (Zhang et. al., 2023, JAMES)
#name, start and end time for test case  in clubb-scm, 
set case   = ( bomex  rico   dycoms2_rf02_nd  wangara )  
set t0     = ( 0      0      0                82800 ) 
set tf     = ( 21600  21600  21600            104400 ) 
set ncase  = $#case

#user-specified time-step and grid-spacing refinements for convergence test  
#the default is the same as simulation setup in clubb convergence paper (Zhang et. al., 2023, JAMES)
#refinment level for vertical resolution and corresponded time step sizes 
#set refine_levels = (  0   0   0   0   0   0  0  0  1  2    3    4     5      6       7) 
#set time_steps    = (600 300 120  60  30  15  8  4  2  1  0.5 0.25 0.125 0.0625 0.03125) 
set refine_levels = (0  1  2    3    4     5      6       7) 
set time_steps    = (4  2  1  0.5 0.25 0.125 0.0625 0.03125) 
set nrefs         = $#refine_levels

#compile model
if ( $compile_model > 0 )  then 

  cd $topdir/compile  

  sed -i "s/linux_x86_64_gfortran.bash/linux_x86_64_ifort_compy.bash/g" compile.bash
  ./clean_all.bash 
  ./compile.bash 

  if ( -f  "${topdir}/bin/clubb_standalone" ) then 
    echo "Model complie succeed, continue ...."
  else 
    echo "Model compile failed, aborting  ...."
    exit 
  endif  

endif 

#run simulations#
if ( ${run_model} > 0 ) then 
  echo "convergence simulation start"
  date
  echo

  if ( ! -d "${outdir}" ) then 
     mkdir -p ${outdir}
  endif 

  cd ${wkdir}

  set i = 1
  while ( $i <= $ncase )

    set casnam = $case[$i]
    set tstart = $t0[$i]
    set tend   = $tf[$i]
    echo "Running simulaitons for $casnam : tstart = $tstart, tend = $tend" 

    set run_script = ${expnam}_${casnam}_cnvg.bash
#generate shell scripts to run simulations on-the-fly 
cat << EOB >!  ${run_script} 
#!/bin/bash
date  
echo
EOB
    set k = 1
    while ( $k <= $nrefs )
      set jobid  = `printf "%02d" $k`
      set config = "-dt $time_steps[$k] -ref $refine_levels[$k] -ti ${tstart} -tf ${tend} -dto ${dt_output}" 
      set strs0  = 'time python3 '"${topdir}"'/run_scripts/run_scm_convergence.py $1 -output-name $2'
      if( $k < $nrefs) then 
        set strs1  = '-skip-check ${@:3} > ${1}_${2}_${SLURM_JOBID}-'"${jobid}"'.log 2>&1 &'
      else
        set strs1  = '-skip-check ${@:3} > ${1}_${2}_${SLURM_JOBID}-'"${jobid}"'.log 2>&1 '
      endif
      echo ""  >> ${run_script}
      echo "${strs0}  ${config} ${config_flags}  ${strs1}" >> ${run_script}
      echo "sleep 20" >> ${run_script}
      @ k++
    end
    
cat << EOB >>!  ${run_script} 
date 
echo
EOB
    #run simulation 
    bash ${run_script}  $casnam  ${expnam} & 

    sleep 5m 

   @ i++  
  end 

  wait

  if ( ! -d "${wkdir}/log_file" ) then 
    mkdir -p ${wkdir}/log_file
  endif
  mv *${expnam}*.log ${wkdir}/log_file/

  if ( ! -d "${wkdir}/config_file" ) then
    mkdir -p ${wkdir}/config_file
  endif
  mv *${expnam}*.in  ${wkdir}/config_file/

  date
  echo
  echo "convergence simulation done"
endif 

#generate convergence figures#
if ( $run_diagnostic > 0 ) then 
  echo "post-processing start"
  date
  echo
 
  #load python environment (user-specified)
  # module load python
  module load anaconda3/2019.03 
  source /share/apps/anaconda3/2019.03/etc/profile.d/conda.csh
  conda activate e3sm_analysis 

  set i = 1
  while ( $i <= $ncase )

    if ( ! -d "${wkdir}/figure" ) then
      mkdir ${wkdir}/figure
    endif

    set casnam = $case[$i]

    cd ${wkdir}

    cp ${topdir}/run_scripts/plot_l2_convergence.py ${casnam}_fig.py
    set j = 1
    while ( $j <= $nrefs ) 
      if ( $j == 1) then 
        set reflevs = "$refine_levels[$j]"
        set dtsteps = "$time_steps[$j]"
      else 
        set reflevs = "$reflevs,$refine_levels[$j]"
        set dtsteps = "$dtsteps,$time_steps[$j]"
      endif 
     @ j++ 
    end 
    #1-h, 2-h ... 6-h index in output 
    foreach hour ( 1 2 3 4 5 6 ) 
      @ indx = $hour * 3600 / $dt_output - 1
      if ( $hour == 1 ) then 
        set tpindex = "$indx"
      else  
        set tpindex = "$tpindex,$indx"
      endif 
    end  
    #echo $reflevs 
    #echo $dtsteps
    #echo $tpindex
    sed -i "s/CASE_NAME/${casnam}/g"         ${casnam}_fig.py
    sed -i "s/EXP_NAME/${expnam}/g"          ${casnam}_fig.py
    sed -i "s/REFINE_LEVELS/${reflevs}/g"    ${casnam}_fig.py
    sed -i "s/DTIME_VALUES/${dtsteps}/g"     ${casnam}_fig.py
    sed -i "s/DTIME_INDEX/${tpindex}/g"      ${casnam}_fig.py

    python ${casnam}_fig.py

    rm -rvf  ${casnam}_cnvg.bash
    rm -rvf  ${casnam}_fig.py

    @ i++ 
  end 

  date
  echo
  echo "post-processing done"
endif 

exit 

