#!/bin/bash
# $Id$
# ------------------------------------------------------------------------------
#
# Compilation script for CLUBB using mkmf. It generates:
#  - libraries: libclubb_bugsrad.a, libclubb_param.a, libclubb_coamps.a
#  - executables: clubb_standalone clubb_tuner clubb_thread_test jacobian G_unit_tests int2txt
#
# Sub-makefiles for each target are automatically generated using the
# 'mkmf' utility. Dependencies among source files are sorted out by 'mkmf'.
# A master makefile is generated that invokes all sub-makefiles.
#
# Platform specific settings are included through a configuration
# file located under config/
#
# This script also depends on external files containing a list of source
# files to be included in each target, which we need to maintain manually.
# A non-exhaustive list of these files follows.
# - file_list/bugsrad_files : files needed for libclubb_bugsrad.a
# - file_list/model_files : files needed for clubb_standalone, clubb_tuner,
#              clubb_thread_test, jacobian, and G_unit_tests
# - file_list/clubb_standalone_files : files needed for clubb_standalone
# - file_list/clubb_thread_test_files : files needed for clubb_thread_test
# - file_list/clubb_tuner_files : files needed for clubb_tuner
# - file_list/jacobian_files : files needed for jacobian
# - file_list/G_unit_tests_files : files needed for G_unit_tests
# - file_list/int2txt_files : files needed for int2txt
#
# Some files are automatically generated by the script based on
# the directories in src and placed in the subdirectory generated_lists. This
# list may or may not be complete:
#
# - generated_lists/param_files : files needed for libclubb_param.a
# - generated_lists/coamps_files : files needed for libclubb_coamps.a
# - generated_lists/numerical_recipes_files : Numerical Recipes files for clubb_tuner
# - generated_lists/clubb_optional_files: Code in the UNRELEASED_CODE blocks of clubb
# - generated_lists/silhs_files: Code in the SILHS blocks of clubb
# - generated_lists/clubb_gfdl_activation_files : files needed for libclubb_gfdlact.a
#
# These file lists can be empty if those directories are empty due to licensing
# restrictions or similar issues.
# ------------------------------------------------------------------------------

# Flag to allow for promotion of reals to double precision at compile time
# This will exclude the Numerical Recipes files, so only the Siarry, et al.
# ESA algorithm will be usable for tuning runs.  Set to true to use double precision 
# everywhere that it is not explicitly specified. (Note: This should not be the case
# anywhere inside of code written by the CLUBB group; we use a generalized
# precision, core_rknd, which this flag does not affect).
l_double_precision=false

# This flag allows for the use of the MKL Lapack routines rather than the provided ones
# located in src. As of Oct 2018 the MKL Lapack routines have been found to be 
# significantly slower. This flag can be enabled by running this script with the -m option.
l_use_mkl_lapack=false

# Figure out the directory where the script is located
scriptPath=`dirname $0`

# Store the current directory location so it can be restored
restoreDir=`pwd`

# Change directories to the one the script is located in
cd $scriptPath


# Set using the default config flags
	CONFIG=./config/linux_x86_64_gfortran.bash # Linux (Redhat Enterprise 5 / GNU)
#	CONFIG=./config/linux_x86_64_g95_optimize.bash # Linux (Redhat Enterprise 5 g95)
#	CONFIG=./config/macosx_x86_64_gfortran.bash # MacOS X / GNU
#	CONFIG=./config/aix_powerpc_xlf90_bluefire.bash # IBM AIX on Bluefire / XL Fortran
#	CONFIG=./config/solaris_generic_oracle.bash # Oracle/Sun Solaris / Oracle/Sun Fortran

# Note that we use `"$@"' to let each command-line parameter expand to a 
# separate word. The quotes around `$@' are essential!
# We need TEMP as the `eval set --' would nuke the return value of getopt.
# This also expects gnu-getopt as opposed to BSD getopt. 
# Make sure you have gnu-getopt installed and it is before BSD getopt in your PATH.
TEMP=`getopt -o c:mh --long mkl_lapack,config:,help -n 'compile.bash' -- "$@"`

if [ $? != 0 ] ; then echo "Run with -h for help." >&2 ; exit 1 ; fi

# Note the quotes around `$TEMP': they are essential!
eval set -- "$TEMP"

while true ; do
	case "$1" in
		-c|--config) # Set the compiler options folder
        
           	 	# Set new config file to the one specfied in the argument list
           	 	CONFIG=$2

			shift 2 ;;
		-m|--mkl_lapack) # Specifiy lapack version

			l_use_mkl_lapack=true

			shift;;
        	-h|--help) # Print the help message

			echo -e "Usage: compile.bash [-c FILE] [-m] [-h]"
			echo -e "\t-c FILE, --config FILE\t  Path to config flags file"
			echo -e "\t-m, --mkl_lapack\t  Flag to use MKL Lapack routines"
			echo -e "\t-h, --help\t\t  Prints this help message"

			exit 1 ;;
		--) shift ; break ;;
		*) echo "Something bad happened!" ; exit 1 ;;
	esac
done

# Load desired configuration file
if [ -e $CONFIG ]; then
	source $CONFIG
else
	echo "Cannot find " $CONFIG
	exit -1
fi

# ------------------------------------------------------------------------------
# Required libraries + platform specific libraries from LDFLAGS
REQ_LIBS="-lclubb_bugsrad -lclubb_KK_microphys -lclubb_parabolic -lclubb_morrison -lmicrophys_utils -lclubb_param"

OPT_LIBS="-lclubb_other"
# ------------------------------------------------------------------------------
# Append preprocessor flags and libraries as needed
if [ -e $srcdir/COAMPS_microphys ]; then
	CPPDEFS="${CPPDEFS} -DCOAMPS_MICRO"
	OPT_LIBS="${OPT_LIBS} -lclubb_coamps"
	COAMPS_LIB="libclubb_coamps.a"
fi
if ! "$l_double_precision"; then
	if [ -e $srcdir/Numerical_recipes ]; then
		CPPDEFS="${CPPDEFS} -DTUNER"
	fi
fi
if [ -e $srcdir/Benchmark_cases/Unreleased_cases ]; then
	CPPDEFS="${CPPDEFS} -DUNRELEASED_CODE"
fi

if [ -e $srcdir/SCM_Activation ]; then
	#CPPDEFS="${CPPDEFS} -DAERSOL_ACT"
	OPT_LIBS="${OPT_LIBS} -lclubb_gfdlact"
	GFDLACT_LIB="libclubb_gfdlact.a"
fi

if [ -e $srcdir/SILHS ]; then
	CPPDEFS="${CPPDEFS} -DSILHS"
	OPT_LIBS="${OPT_LIBS} -lsilhs"
	lh_LIB="libsilhs.a"
fi

# Add miscellaneous preprocessor definitions
# -Dradoffline and -Dnooverlap (see bugsrad documentation)
CPPDEFS="${CPPDEFS} -Dradoffline -Dnooverlap -DCLUBB"

# Add all flags together.  These must be linked by order of dependence, so 
# So libsilhs comes before libclubb comes before liblapack.
LDFLAGS="-L$libdir $OPT_LIBS $REQ_LIBS ${LDFLAGS}"

# ------------------------------------------------------------------------------
# Special addition for XLF, which uses the xlf for fixed format and xlf90 for 
# free format Fortran files.  For other compilers we can just assume FC is 
# good enough for fixed and free format.
if [ -z "${F77}" ] || [ -z "${F90}" ]; then
	if [ -z ${FC} ]; then
		echo "Either FC, or F90 and F77 must be defined in the config file"
		exit -1
	else
		F90="${FC}"
		F77="${FC}"
	fi
fi

# ------------------------------------------------------------------------------
# If the user sets l_double_precision of true, then we add the double precision 
# flags here.
if "$l_double_precision"; then
	FFLAGS="${FFLAGS} ${DOUBLE_PRECISION}"
fi

# ------------------------------------------------------------------------------
# Generate template for makefile generating tool 'mkmf'


cd $bindir
cat > mkmf_template << EOF
# mkmf_template needed my 'mkmf' and generated by 'compile.bash'
# Edit 'compile.bash' to customize.

F77 = ${F77}
F90 = ${F90}
LD = ${LD}
AR = ${AR}
CPPFLAGS = ${CPPFLAGS}
FFLAGS = ${FFLAGS}
LDFLAGS = ${LDFLAGS}
EOF
cd $dir

# ------------------------------------------------------------------------------
# Generate file lists
# It would be nice to generate file lists for clubb_standalone / clubb_tuner 
# dynamically, but this not possible without some major re-factoring of 
# the CLUBB source directories.

generated_lists_dir="$dir/file_list/generated_lists"
if [[ -e $generated_lists_dir ]]; then
	# The generated lists directory exists. This should not happen, but we
	# should handle it appropriately for the sake of robustness.
	rm -rf "$generated_lists_dir"
fi
mkdir "$generated_lists_dir"

# ------------------------------------------------------------------------------
# This is a list of file lists included in CLUBB's repository; it needs to be
# maintained manually.
repository_file_lists=( \
	$dir/file_list/clubb_bugsrad_files \
	$dir/file_list/clubb_KK_microphys_files \
	$dir/file_list/clubb_model_files \
	$dir/file_list/clubb_morrison_files \
	$dir/file_list/clubb_standalone_files \
	$dir/file_list/clubb_thread_test_files \
	$dir/file_list/clubb_tuner_files \
	$dir/file_list/G_unit_tests_files \
	$dir/file_list/int2txt_files \
	$dir/file_list/jacobian_files \
        $dir/file_list/clubb_parabolic_files )

# ------------------------------------------------------------------------------
#  Determine which restricted files are in the source directory and make a list
if [ -e $srcdir/Benchmark_cases/Unreleased_cases ]; then
	ls $srcdir/Benchmark_cases/Unreleased_cases/*.F90 > "$generated_lists_dir"/clubb_optional_files
fi
if [ -e $srcdir/SILHS ]; then
	ls $srcdir/SILHS/*.F90 > "$generated_lists_dir"/silhs_files
fi
if [ -e $srcdir/COAMPS_microphys ]; then
	ls $srcdir/COAMPS_microphys/*.F > "$generated_lists_dir"/clubb_coamps_files
fi
if [ -e $srcdir/SCM_Activation/aer_ccn_act_k.F90 ]; then 
	ls $srcdir/SCM_Activation/aer_ccn_act_k.F90 > "$generated_lists_dir"/clubb_gfdl_activation_files
fi
if [ -e  $srcdir/Microphys_utils  ]; then
	ls $srcdir/Microphys_utils/*.F90 > "$generated_lists_dir"/clubb_microphys_utils_files
fi
if [ -e  $srcdir/CLUBB_core ]; then
	ls $srcdir/CLUBB_core/*.[f,F]90 > "$generated_lists_dir"/clubb_param_files

    # Compile provided Lapack routines if not using MKL version
    if ! "$l_use_mkl_lapack"; then
	    ls $srcdir/Lapack/*.f >> "$generated_lists_dir"/clubb_param_files
    fi
else
	echo "Fatal error, CLUBB_core directory is missing"
	exit -1
fi

# Exclude numerical recipes if using double precision or numerical recipes doesn't exist
if ! "$l_double_precision"; then
	if [ -e $srcdir/Numerical_recipes ]; then
		ls $srcdir/Numerical_recipes/*.f90 > "$generated_lists_dir"/numerical_recipes_files
	fi
else
	echo "" > "$generated_lists_dir"/numerical_recipes_files
fi

all_files_list="$generated_lists_dir"/clubb_all_files
rm -f $all_files_list
cat ${repository_file_lists[@]} $generated_lists_dir/*_files > $all_files_list

# ------------------------------------------------------------------------------
# Generate makefiles using 'mkmf'

cd $objdir
$mkmf -t $bindir/mkmf_template -p $libdir/libclubb_param.a -m Make.clubb_param -c "${CPPDEFS}" \
  -o "${WARNINGS}" -e $all_files_list "$generated_lists_dir"/clubb_param_files

$mkmf -t $bindir/mkmf_template \
  -p $libdir/libclubb_bugsrad.a -m Make.clubb_bugsrad -c "${CPPDEFS}" \
  -e $all_files_list $dir/file_list/clubb_bugsrad_files

$mkmf -t $bindir/mkmf_template \
  -p $libdir/libmicrophys_utils.a -m Make.microphys_utils -c "${CPPDEFS}" \
  -e $all_files_list "$generated_lists_dir"/clubb_microphys_utils_files

$mkmf -t $bindir/mkmf_template \
  -p $libdir/libclubb_parabolic.a -m Make.clubb_parabolic -c "${CPPDEFS}" \
  -e $all_files_list $dir/file_list/clubb_parabolic_files

$mkmf -t $bindir/mkmf_template \
  -p $libdir/libclubb_KK_microphys.a -m Make.clubb_KK_microphys -c "${CPPDEFS}" \
  -o "${WARNINGS}" -e $all_files_list $dir/file_list/clubb_KK_microphys_files

$mkmf -t $bindir/mkmf_template \
  -p $libdir/libclubb_coamps.a -m Make.clubb_coamps -c "${CPPDEFS}" \
  -e $all_files_list -o "${DISABLE_WARNINGS}" "$generated_lists_dir"/clubb_coamps_files

$mkmf -t $bindir/mkmf_template \
  -p $libdir/libclubb_morrison.a -m Make.clubb_morrison -c "${CPPDEFS}" \
  -e $all_files_list -o "${DISABLE_WARNINGS}" $dir/file_list/clubb_morrison_files

$mkmf -t $bindir/mkmf_template \
  -p $libdir/libclubb_gfdlact.a -m Make.clubb_gfdlact -c "${CPPDEFS}" \
  -e $all_files_list -o "${DISABLE_WARNINGS}" "$generated_lists_dir"/clubb_gfdl_activation_files

$mkmf -t $bindir/mkmf_template \
  -p $libdir/libsilhs.a -m Make.silhs -c "${CPPDEFS}" -o "${WARNINGS}" \
  -e $all_files_list "$generated_lists_dir"/silhs_files

$mkmf -t $bindir/mkmf_template -p $libdir/libclubb_other.a -m Make.clubb_other -c "${CPPDEFS}" \
  -o "${WARNINGS}" -e $all_files_list "$generated_lists_dir"/clubb_optional_files \
  $dir/file_list/clubb_model_files

$mkmf -t $bindir/mkmf_template -p $bindir/clubb_standalone \
  -m Make.clubb_standalone -c "${CPPDEFS}" -o "${WARNINGS}" $clubb_standalone_mods \
  -e $all_files_list $dir/file_list/clubb_standalone_files

$mkmf -t $bindir/mkmf_template -p $bindir/clubb_thread_test \
  -m Make.clubb_thread_test -c "${CPPDEFS}" -o "${WARNINGS}" $clubb_standalone_mods \
  -e $all_files_list $dir/file_list/clubb_thread_test_files

$mkmf -t $bindir/mkmf_template -p $bindir/clubb_tuner \
  -m Make.clubb_tuner -c "${CPPDEFS}" -e $all_files_list \
  $dir/file_list/clubb_tuner_files "$generated_lists_dir"/numerical_recipes_files

$mkmf -t $bindir/mkmf_template -p $bindir/jacobian \
  -m Make.jacobian -c "${CPPDEFS}" -o "${WARNINGS}" -e $all_files_list \
   $dir/file_list/jacobian_files

$mkmf -t $bindir/mkmf_template -p $bindir/G_unit_tests \
  -m Make.G_unit_tests -c "${CPPDEFS}" -o "${WARNINGS}" -e $all_files_list \
  $dir/file_list/G_unit_tests_files

$mkmf -t $bindir/mkmf_template -p $bindir/int2txt -m Make.int2txt \
  -o "${WARNINGS}" -e $all_files_list $dir/file_list/int2txt_files

cd $dir

#-------------------------------------------------------------------------------
# Determine if additional folders need to be checked against the standard
if [ -e $srcdir/Benchmark_cases/Unreleased_cases ]; then
	CLUBBStandardsCheck_unreleased_cases="-perl ../utilities/CLUBBStandardsCheck.pl ../src/Benchmark_cases/Unreleased_cases/*.F90"
fi

if [ -e $srcdir/SILHS ]; then
	CLUBBStandardsCheck_silhs="-perl ../utilities/CLUBBStandardsCheck.pl ../src/SILHS/*.F90"
fi

# ------------------------------------------------------------------------------
# Generate master makefile
# CLUBB generates libraries.  The dependencies between such libraries must
# be handled manually.

cd $bindir
cat > Makefile << EOF
# Master makefile for CLUBB generated by 'compile.bash'
# Edit 'compile.bash' to customize.

all:	libclubb_param.a libclubb_bugsrad.a clubb_standalone clubb_tuner \
	jacobian G_unit_tests int2txt clubb_thread_test
	perl ../utilities/CLUBBStandardsCheck.pl ../src/*.F90
	perl ../utilities/CLUBBStandardsCheck.pl ../src/CLUBB_core/*.F90
	perl ../utilities/CLUBBStandardsCheck.pl ../src/Benchmark_cases/*.F90
	$CLUBBStandardsCheck_unreleased_cases
	perl ../utilities/CLUBBStandardsCheck.pl ../src/KK_microphys/*.F90
	$CLUBBStandardsCheck_silhs
	perl ../utilities/CLUBBStandardsCheck.pl ../src/G_unit_test_types/*.F90

libclubb_param.a:
	cd $objdir; \$(MAKE) -f Make.clubb_param

libclubb_bugsrad.a: libclubb_param.a
	cd $objdir; \$(MAKE) -f Make.clubb_bugsrad

libmicrophys_utils.a: libclubb_param.a
	cd $objdir; \$(MAKE) -f Make.microphys_utils

libclubb_parabolic.a: libclubb_param.a
	cd $objdir; \$(MAKE) -f Make.clubb_parabolic

libclubb_KK_microphys.a: libclubb_param.a libmicrophys_utils.a libclubb_parabolic.a
	cd $objdir; \$(MAKE) -f Make.clubb_KK_microphys

libclubb_coamps.a: libclubb_param.a
	cd $objdir; \$(MAKE) -f Make.clubb_coamps

libclubb_morrison.a: libclubb_param.a libmicrophys_utils.a
	cd $objdir; \$(MAKE) -f Make.clubb_morrison

libclubb_gfdlact.a: 
	cd $objdir; \$(MAKE) -f Make.clubb_gfdlact

libsilhs.a: libclubb_param.a libclubb_KK_microphys.a libmicrophys_utils.a
	cd $objdir; \$(MAKE) -f Make.silhs

libclubb_other.a: libclubb_param.a libclubb_bugsrad.a libclubb_KK_microphys.a libclubb_coamps.a libclubb_morrison.a libclubb_gfdlact.a libsilhs.a
	cd $objdir; \$(MAKE) -f Make.clubb_other

clubb_standalone: libclubb_bugsrad.a libclubb_param.a libclubb_KK_microphys.a $COAMPS_LIB libclubb_morrison.a libclubb_other.a $GFDLACT_LIB $lh_LIB
	cd $objdir; \$(MAKE) -f Make.clubb_standalone

clubb_thread_test: libclubb_bugsrad.a libclubb_param.a libclubb_KK_microphys.a $COAMPS_LIB libclubb_morrison.a libclubb_other.a $GFDLACT_LIB $lh_LIB
	cd $objdir; \$(MAKE) -f Make.clubb_thread_test

clubb_tuner: libclubb_bugsrad.a libclubb_param.a libclubb_KK_microphys.a $COAMPS_LIB libclubb_morrison.a libclubb_other.a $GFDLACT_LIB $lh_LIB
	cd $objdir; \$(MAKE) -f Make.clubb_tuner

jacobian: libclubb_bugsrad.a libclubb_param.a libclubb_KK_microphys.a $COAMPS_LIB libclubb_morrison.a libclubb_other.a $GFDLACT_LIB $lh_LIB
	cd $objdir; \$(MAKE) -f Make.jacobian

G_unit_tests: libclubb_bugsrad.a libclubb_param.a libclubb_KK_microphys.a $COAMPS_LIB libclubb_morrison.a libclubb_other.a $GFDLACT_LIB $lh_LIB
	cd $objdir; \$(MAKE) -f Make.G_unit_tests

int2txt: libclubb_bugsrad.a libclubb_param.a libclubb_KK_microphys.a $COAMPS_LIB libclubb_morrison.a libclubb_other.a
	cd $objdir; \$(MAKE) -f Make.int2txt

clean:
	-rm -f $objdir/*.o \
	$objdir/*.mod
	
distclean:
	-rm -f $objdir/*.* \
	$objdir/.cppdefs \
	$libdir/lib* \
	$bindir/clubb_standalone \
	$bindir/clubb_tuner \
	$bindir/clubb_thread_test \
	$bindir/int2txt \
	$bindir/jacobian \
	$bindir/G_unit_tests \
	$bindir/mkmf_template \
	$bindir/Makefile \

EOF
cd $dir

# ------------------------------------------------------------------------------
# Invoke master makefile

cd $bindir
$gmake
# Get the exit status of the gmake command
exit_status=${?}

# Remove unnecessary compiler artifacts
rm -rf "$generated_lists_dir"

cd $restoreDir

# Exit returing the result of the make
exit $exit_status
