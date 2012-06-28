#!/bin/bash

HELP="$(cat << EOF
Usage:
    iso2usb.sh -i file.iso -d /dev/diskN
EOF)"

function help {
    echo $HELP
    exit 1
}

TMPDIR="$(mktemp -d /tmp/iso2usb.XXXXXXXXXX)"

function cleanup {
    echo "Removing temp dir."
    rm -rf "$TMPDIR"
}

trap cleanup EXIT

while getopts "i:d:" OPT
do
    case $OPT in
        i)
            INFILE=$OPTARG
            if [ ! -f "$INFILE" ]
            then
                echo "Invalid ISO file"
                exit 1
            fi
            ;;
        d)
            DISK=$OPTARG
            if [ ! -b "$DISK" ]
            then
                echo "Invalid disk specified."
                exit 1
            fi
            ;;
        \?)
            help
            ;;
    esac
done

if [ -z "$INFILE" -o -z "$DISK" ]
then
    help
fi

echo "Listing the disk you specified."
diskutil list $DISK
while true
do
    read -p"Is this the right disk? (y/n) " CONFIRM
    if [ "$CONFIRM" = "y" ]
    then
        echo "Doing as you wish."
        break
    else
        if [ "$CONFIRM" = "n" ]
        then
            echo "Breaking the process."
            exit 1
        else
            echo "Wrong choice."
            continue
        fi
    fi
done

echo "Converting ISO"

hdiutil convert -format UDRW -o "$TMPDIR/out" "$INFILE"

if [ "$?" -ne 0 ]
then
    echo "Something went worng with hdiutil check logs above."
    exit 1
fi
echo "File converted, erasing your disk and writing the new file. It will ask for your password."
diskutil unmountDisk "$DISK"

if [ "$?" -ne 0 ]
then
    echo "diskutil was not able to unmount the disk, aborting operation."
    exit 1
fi

sudo dd if="$TMPDIR/out.dmg" of="$DISK" bs=1m

if [ "$?" -eq 0 ]
then
    echo "Convertion successful."
    exit 0
else
    echo "Something went wrong while writing on the disk."
    exit 1
fi
