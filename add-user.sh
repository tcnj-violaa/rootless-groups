#!/bin/bash

#Script to set up a new student in this project group
#USAGE: ./add_user.sh [user] [list of folders the user can work in, separated by commas]
#EXAMPLE: ./add_user.sh alex affective-computing,crowd-analysis
# The user will be granted r-w permissions on the lab folder on the cluster,
# given r-x permissions within the libraries folder, 
# given rwx permissions within the specified folders in the lab folder, plus rwx
# permissions for a personal folder under user/[their username]

source admin.conf

USER="$1"
PROJECTS="$2"

# Possible TODO, do we want to maintain a list of users and their groups?
# It would make a 'remove user' functionality simpler


#Check arguments

if !(id "$USER" &>/dev/null); then
	echo "User not found, quitting."
	exit 1
fi

IFS=',' read -ra PROJS <<< "$PROJECTS"

for dir in "${PROJS[@]}"
do
	if [ ! -d "$LAB/$dir" ]; then
		echo "Folder "$LAB/$dir" doesn't exist. Check for typos."
		exit 1
	fi

done

#ls -lha "$LAB"/"$USER_FOLDER"


# find "$LAB" -depth -not -user labpi1 -not -path "$LAB/$USER_FOLDER/*"

#Reclaim ownership of files user might own
# This is nearly a copy-paste with a changed 'find' section... not very modular if you ask me but it should work
# Also this reclaims -all- user files in all project directories... perhaps
# kind of a kludge, but it shouldn't be a problem
# This 'find' returns all files owned by students, only in project directories
#reclaim $(find "$LAB" -depth -not -user "$ADMIN" -not -path "$LAB/$USER_FOLDER/*")

for file in $(find "$LAB" -depth -not -user "$ADMIN" -not -path "$LAB/$USER_FOLDER/*")
do
	#echo "$file"

	##TODO: We have an issue if a user makes a directory that they own...
	if [ -d "$file" ]; then 
		echo "$file" is a directory
		mkdir "$file".adm
		mv "$file"/* "$file".adm/
		rmdir "$file" 
		mv "$file".adm "$file"

		continue
		# ...
	fi
		
	#Replace the file with a copy that has admin:faculty ownership
	#preserve xattr retains additional acl permissions, which is crucial.
	cp --no-preserve=ownership --preserve=xattr "$file" "$file".new
	#getfacl "$file" | setfacl --set-file=- "$file".new
	mv -f "$file".new "$file"
done


## Grant user access to this lab folder
setfacl -m u:"$USER":r-x "$LAB"

## Grant user r-x access to users folder, and rwx to their own folder
setfacl -m u:"$USER":r-x "$LAB"/"$USER_FOLDER"

mkdir "$LAB"/user/"$USER"
setfacl -Rm u:"$USER":rwX "$LAB"/"$USER_FOLDER"/"$USER"

# -d sets 'default' permissions, so all files you or $USER creates will have these perms
setfacl -Rdm u:"$USER":rwX "$LAB"/"$USER_FOLDER"/"$USER"

# Ensure that admin keeps permissions on files when students own them
setfacl -Rm u:"$ADMIN":rwX "$LAB"/"$USER_FOLDER"/"$USER"
setfacl -Rdm u:"$ADMIN":rwX "$LAB"/"$USER_FOLDER"/"$USER"

## Grant user access to libraries
setfacl -Rm u:"$USER":r-X "$LAB"/"$LIB_FOLDER"
setfacl -Rdm u:"$USER":r-X "$LAB"/"$LIB_FOLDER"

## Grant user write access to their project folder(s)
for dir in "${PROJS[@]}"
do
 setfacl -Rm u:"$USER":rwX "$LAB"/"$dir"
 setfacl -Rdm u:"$USER":rwX "$LAB"/"$dir"
done

#For logging...
echo $(date +"%x %X") - Added $USER to projects $PROJECTS >> "$ADMIN_LOG"

