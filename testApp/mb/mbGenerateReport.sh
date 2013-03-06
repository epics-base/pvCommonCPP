#! /bin/bash

COMMAND=`basename $0`

# environment variables
# MB_OUTPUT_DIR
# MB_REPORT_DIR

###
### ------------ Command Line Parsing ------------
###
LONGOPTS=help,output_dir:,report_dir:
SHORTOPTS=ho:r:

#
# Usage help.
#
function printUsage {
    cat << EOF
Reads micro-benchmark generated .csv filed and generates HTML report.

Usage $COMMAND [OPTIONS]
Options:
    -o | --output_dir        directory where .csv files are located, overrides MB_OUTPUT_DIR and current directory
    -r | --report_dir        directory where to put generated HTML report, overrides MB_REPORT_DIR and current directory
    -h | --help              prints this help and exits

EOF
}


export POSIXLY_CORRECT=1
getopt -n $COMMAND -Q -u -a -l $LONGOPTS $SHORTOPTS "$@" || {
    printUsage
    exit 1;
}

set -- `getopt -u -a -l $LONGOPTS $SHORTOPTS "$@"`

while :
do
    case "$1" in
        --output_dir)   MB_OUTPUT_DIR=$2 ; shift ;;
        -o)             MB_OUTPUT_DIR=$2 ; shift ;;
        --report_dir)   MB_REPORT_DIR=$2 ; shift ;;
        -r)             MB_REPORT_DIR=$2 ; shift ;;
        --help)         printUsage ; exit 0 ;;
        -h)             printUsage ; exit 0 ;;
        --)             if [ X"$2" != X ] ; then printUsage ; exit 2 ; fi ; break ;;
    esac
    shift
done

unset POSIXLY_CORRECT

###
### ------------ Arguments Checking and Setup ------------
###

if [ X"$MB_OUTPUT_DIR" = X ]
then
    export MB_OUTPUT_DIR=$PWD
fi

if [ X"$MB_REPORT_DIR" = X ]
then
    export MB_REPORT_DIR=$PWD
fi

if [ ! -d $MB_OUTPUT_DIR ]
then
    echo "MB_OUTPUT_DIR directory '$MB_OUTPUT_DIR' does not exists."
    exit 2;
fi

if [ ! -d $MB_REPORT_DIR ]
then
    mkdir -p $MB_REPORT_DIR || (echo "Failed to create MB_REPORT_DIR, existing..." && exit 2)
fi

###
### ------------ Main Logic ------------
###

INPUT_LIST=`ls -1 $MB_OUTPUT_DIR/mb_*.csv 2> /dev/null`
if [ X"$INPUT_LIST" = X ]
then
    echo "No mb_*.csv files found in $MB_OUTPUT_DIR."
    exit 3
fi

echo "Merging input files..."

# merge same named .csv files
# sort its content by stage
echo $INPUT_LIST | grep -v merged | cut -d '_' -f 2 | sort -u | xargs -I {} sh -c "cat $MB_OUTPUT_DIR/mb_{}*.csv | sort -t ',' -n -k2 > $MB_REPORT_DIR/merged_{}.csv"

echo "  done."

PROCESS_LIST=`ls $MB_REPORT_DIR/merged*.csv 2> /dev/null`
if [ X"$PROCESS_LIST" = X ]
then
    echo "No merged*.csv files found in $MB_REPORT_DIR, internal error!"
    exit 4
fi

for FILE in $PROCESS_LIST
do
    echo "Processing $FILE..."

    echo "    Determining number of stages..."
    # get stages, skip 0 stage
    STAGES=`cat $FILE | cut -d ',' -f 2 | sort -u -n | grep -v '^0'`
    STAGE_COUNT=`echo $STAGES | wc -w`
    echo "      done."

    STAT_FILE="$FILE.stat"
    rm $STAT_FILE 2> /dev/null

    for STAGE in $STAGES
    do
        echo "    Processing stage $STAGE of $STAGE_COUNT..."
        # TODO configurable
        IGNORE_FIRST_N=0

        STAGE_FILE="$FILE.$STAGE"
        mb_stat $FILE -n -s $STAGE -i $IGNORE_FIRST_N > $STAGE_FILE
        gnuplot -e "set print \"-\"; set datafile separator \",\"; stat \"$STAGE_FILE\" using 3 prefix \"s0\" nooutput; print $STAGE, s0_min, s0_lo_quartile, s0_mean, s0_stddev, s0_up_quartile, s0_max" >> $STAT_FILE

        #ITERATIONS=`cat $STAGE_FILE | wc -l`
        gnuplot << EOF
        set terminal pngcairo transparent enhanced font "arial,10" fontscale 1.0 size 1024, 768
        set output '$STAGE_FILE.png'

        set datafile separator ","
        set title "Stage $STAGE sampling"
        #plot mean_y-stddev_y with filledcurves y1=mean_y lt 1 lc rgb "#bbbbdd", \
        #     mean_y+stddev_y with filledcurves y1=mean_y lt 1 lc rgb "#bbbbdd", \
        #     mean_y w l lt 3, 'stats2.dat' u 1:2 w p pt 7 lt 1 ps 1
        plot '$STAGE_FILE' using 3 w p pt 7 lt 1 ps 1 notitle
EOF

        echo "      done."
    done

    echo "    Generating report..."
    gnuplot << EOF
    set terminal pngcairo transparent enhanced font "arial,10" fontscale 1.0 size 1024, 768
    set output '$FILE.png'


    set bars front
    by3(x) = (((int(x)%3)+1)/6.)
    by4(x) = (((int(x)%4)+1)/7.)
    rgbfudge(x) = x*51*32768 + (11-x)*51*128 + int(abs(5.5-x)*510/9.)

    set boxwidth 0.2 absolute
    set title "min/lo quartile/mean/hi quartile/max per stage"
    set xrange [ 0 : $STAGE_COUNT ] noreverse nowriteback
    plot '$STAT_FILE' using 1:3:2:7:6:1 with candlesticks lc var fs solid 0.5 noborder title 'Quartiles' whiskerbars, \
         ''         using 1:4:4:4:4:1 with candlesticks lc var fs solid 0.5 noborder notitle
EOF
    echo "      done."


    echo "  done."
done


