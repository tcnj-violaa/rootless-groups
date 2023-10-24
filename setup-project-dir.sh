#!/bin/bash

#Script to set up proper permissions on a new project folder.
#This mostly is meant to ensure that the professor/admin maintains access
#to project/user directories where file ownership and group membership 
#(and thus permissions) might change due to students writing to files and 
#gaining ownership.

# USAGE: ./setup-project-dir.sh [list of folders, separated by commas]
# EXAMPLE: ./setup-project-dir.sh crowd-analysis,affective-computing,baseball-stats

# This script will set default admin permissions for the user and library folders.
# If these are already set up, then there is no effect

source admin.conf

FOLDERS="$1"

IFS=',' read -ra PROJS <<< "$FOLDERS"

#Check if all supplied directories are valid before proceeding
for dir in "${PROJS[@]}"
do
	if [ ! -d "$LAB/$dir" ]; then
		echo "Folder "$LAB/$dir" doesn't exist. Check for typos."
		exit 1
	fi
done


#Apply admin permissions to appropriate folders
for dir in "${PROJS[@]}"
do

	#chmod u-s "$LAB"/"$dir"
	chmod g+s "$LAB"/"$dir"
	#chmod u+s "$LAB"/"$dir"
	setfacl -Rnm u:"$ADMIN":rwX "$LAB"/"$dir"
	setfacl -Rndm u:"$ADMIN":rwX "$LAB"/"$dir"

	echo $(date +"%x %X") " - Set up admin permissions for "$LAB/$dir >> setup-log
done


# Ensure you retain ownership of libraries file
chmod g+s "$LAB"/"$LIB_FOLDER"
setfacl -Rnm u:"$ADMIN":rwX "$LAB"/"$LIB_FOLDER"
setfacl -Rndm u:"$ADMIN":rwX "$LAB"/"$LIB_FOLDER"

# Ensure you retain ownership of data file
chmod g+s "$LAB"/data
setfacl -Rnm u:"$ADMIN":rwX "$LAB"/data
setfacl -Rndm u:"$ADMIN":rwX "$LAB"/data

# Same with user folder
chmod g+s "$LAB"/"$USER_FOLDER"
chmod o=r-- "$LAB"/"$USER_FOLDER"
setfacl -Rnm u:"$ADMIN":rwX "$LAB"/"$USER_FOLDER"
setfacl -Rndm u:"$ADMIN":rwX "$LAB"/"$USER_FOLDER"

echo $(date +"%x %X") " - Set up admin permissions for user and library folders in "$LAB >> "$ADMIN_LOG"


