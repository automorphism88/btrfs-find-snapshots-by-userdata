#!/usr/bin/awk -f

# This script searches the output of snapper ls either for snapshots which have
# a specified userdata key defined, or for snapshots where the specified
# userdata key is equal to a specified value. It was written for use by
# snapraid-btrfs, but also functions independently as a standalone program.

# The userdata key/value can be specified by passing the variables
# 'key' and 'value' using the -v option. The output is a list of snapshot
# numbers separated by newlines, with the snapshots matched as follows:
# - if key and value are both nonempty, match snapshots with userdata key=value
# - else if key is nonempty, match all snapshots with key defined
# - else match all snapshots

# Copyright (C) 2017,2019 Alex deBeus

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

BEGIN { FS="|" } # snapper separates columns with '|' characters

# read column titles in header, so as to work with different versions of
# snapper that reorder columns
NR==1 {
    for (i=1;i<=NF;i++) {
        # remove padding spaces, then store column number indexed by title
        gsub(/[ ]+/,"",$i)
        column[$i] = i
    }
    # display an error message and exit if we didn't find columns
    # labelled "#" and "Userdata"
    if (column["#"] == "" || column["Userdata"] == "") {
        printf("error: expected snapper ls column names not found in input\n",
               "/dev/stderr")
        exit 1
    }
}
# snapshot data begins on line 3
NR>=3 {
    # remove nonnumeric characters (padding spaces, mount status) from #
    gsub(/[^0123456789]+/,"",$column["#"])
    if (key == "") {
        # match all snapshots
        print $column["#"]
    } else {
        # split userdata column into key=value pairs in case
        # multiple userdata keys are defined for a snapshot
        split($column["Userdata"],u,",")
        # construct a new array v where the keys are the values from u
        for (i in u) {
            # remove padding spaces
            gsub(/^[ ]+/,"",u[i])
            gsub(/[ ]+$/,"",u[i])
            if (value == "") {
                # We don't care about the value of the userdata key, so
                # split key=value pairs and store only the key as a key in v
                split(u[i],w,"=")
                v[w[1]]
            } else {
                # We care about both halves of the userdata key=value
                # pair, so store the whole key=value string as a key in v
                v[u[i]]
            }
        }
        # find and print our matches
        if (value == "") {
            if (key in v) {
                print $column["#"]
            }
        } else {
            if (key "=" value in v) {
                print $column["#"]
            }
        }
        # Wipe v so one match doesn't result in matching all subsequent lines
        # delete v only works in gawk
        split("",v," ")
    }
}
