#! /bin/bash

COMMAND=`basename $0`

# environment variables
# MB_OUTPUT_DIR
# MB_REPORT_DIR

IGNORE_FIRST_N=0

###
### ------------ Command Line Parsing ------------
###
LONGOPTS=help,output_dir:,report_dir:,ignore_first_n:
SHORTOPTS=ho:r:i:

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
    -i | --ignore_first_n    ignore first n samples
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
        --output_dir)      MB_OUTPUT_DIR=$2 ; shift ;;
        -o)                MB_OUTPUT_DIR=$2 ; shift ;;
        --report_dir)      MB_REPORT_DIR=$2 ; shift ;;
        -r)                MB_REPORT_DIR=$2 ; shift ;;
        --ignore_first_n)  IGNORE_FIRST_N=$2 ; shift ;;
        -i)                IGNORE_FIRST_N=$2 ; shift ;;
        --help)            printUsage ; exit 0 ;;
        -h)                printUsage ; exit 0 ;;
        --)                if [ X"$2" != X ] ; then printUsage ; exit 2 ; fi ; break ;;
    esac
    shift
done

unset POSIXLY_CORRECT

###
### ------------ Arguments Checking and Setup ------------
###

# Put the RE in a var for backward compatibility with versions <3.2
intregexp='^[0-9]*$'
if [[ ! $IGNORE_FIRST_N =~ $intregexp ]]
then
    echo "IGNORE_FIRST_N='$IGNORE_FIRST_N' is not a valid positive number"
    exit 1
fi

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
    exit 2
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

    IGNORE_FIRST_N_PLUS_ONE=`expr $IGNORE_FIRST_N + 1`

    for STAGE in $STAGES
    do
        echo "    Processing stage $STAGE of $STAGE_COUNT..."

        STAGE_FILE="$FILE.$STAGE"
        mb_stat $FILE -n -s $STAGE | tail -n +$IGNORE_FIRST_N_PLUS_ONE > $STAGE_FILE
        if [ ! -s $STAGE_FILE ]
        then
            echo "Stage $STAGE contains no samples, skipping..."
            continue
        fi
        STAT=`gnuplot -e "set print \"-\"; set datafile separator \",\"; stat \"$STAGE_FILE\" using 3 prefix \"s0\" nooutput; print $STAGE, s0_min, s0_lo_quartile, s0_mean, s0_stddev, s0_up_quartile, s0_max"`
        echo $STAT >> $STAT_FILE

        MIN_Y=`echo $STAT | cut -d ' ' -f 2`
        MEAN_Y=`echo $STAT | cut -d ' ' -f 4`
        STDDEV_Y=`echo $STAT | cut -d ' ' -f 5`
        MAX_Y=`echo $STAT | cut -d ' ' -f 7`

        #ITERATIONS=`cat $STAGE_FILE | wc -l`
        gnuplot << EOF
        set terminal pngcairo enhanced font "arial,10" fontscale 1.0 size 1024, 768
        set output '$STAGE_FILE.png'

        set datafile separator ","
        set title "Stage $STAGE sampling"
        plot $MEAN_Y-$STDDEV_Y with filledcurves y1=$MEAN_Y lt 1 lc rgb "#bbbbdd" title "stddev range", \
             $MEAN_Y+$STDDEV_Y with filledcurves y1=$MEAN_Y lt 1 lc rgb "#bbbbdd" notitle, \
             $MEAN_Y w l lt 3 title "mean", \
             '$STAGE_FILE' using 3 w p pt 7 lt 1 ps 1 notitle
EOF

        echo "      done."
    done

    if [ ! -s $STAT_FILE ]
    then
        echo "Statistics file contains no data, exiting..."
        exit 5
    fi

    echo "    Generating report..."
    gnuplot << EOF
    set terminal pngcairo enhanced font "arial,10" fontscale 1.0 size 1024, 768
    set output '$FILE.png'

    set boxwidth 0.2 absolute
    set title "min/lo quartile/mean/hi quartile/max per stage"
    set xrange [ 0 : $STAGE_COUNT+1 ] noreverse nowriteback
    plot '$STAT_FILE' using 1:3:2:7:6:xticlabels(1) with candlesticks lt 3 lw 2 title 'Quartiles' whiskerbars, \
         ''         using 1:4:4:4:4 with candlesticks lt -1 lw 2 notitle
EOF
    echo "      done."


    echo "  done."
done


