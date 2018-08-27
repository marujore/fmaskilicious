#!/bin/bash

set -e
shopt -s nullglob

MCROOT=/usr/local/MATLAB/MATLAB_Runtime/v93

# parse command line
if [ $# -lt 1 ] || [ "$1" == "--help" ]; then
    echo "Usage: run_fmask.sh SCENE_ID FMASK_OPTIONS"
    exit 0
fi

SCENE_ID="$1"
INDIR=/mnt/input-dir/$SCENE_ID.SAFE
WORKDIR=/work/$SCENE_ID.SAFE
OUTDIR=/mnt/output-dir

if [ ! -d "$INDIR" ]; then
    echo "Error: no SAFE file found for scene ID $SCENE_ID"
    exit 1
fi

shift

# ensure that workdir is clean
if [ -d $WORKDIR ]; then
    rm -rf $WORKDIR
fi
mkdir -p $WORKDIR

ls -l $INDIR

for f in $INDIR/*; do
    if [ "$(basename $f)" != "GRANULE" ]; then
        ln -s $(readlink -f $f) $WORKDIR/$(basename $f)
    fi
done

# run fmask for every granule in SAFE
for granule_path in $INDIR/GRANULE/*; do
    granule=$(basename $granule_path)
    echo "Processing granule $granule"

    granuledir=$WORKDIR/GRANULE/$granule
    mkdir -p $granuledir
    for f in $INDIR/GRANULE/$granule/*; do
        ln -s $(readlink -f $f) $granuledir/$(basename $f)
    done
    ls -l $granuledir

    # call fmask
    cd $granuledir
    /usr/GERS/Fmask_4_0/application/run_Fmask_4_0.sh $MCROOT "$@"

    # copy outputs from workdir
    mkdir -p $OUTDIR/$granule
    for f in $granuledir/FMASK_DATA/*; do
        cp $f $OUTDIR/$granule
    done
done

ls -l $WORKDIR
ls -l $WORKDIR/GRANULE/*

rm -rf $WORKDIR