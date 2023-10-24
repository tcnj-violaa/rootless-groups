#!/bin/bash

#Script to remove a user from the lab.
#USAGE: ./remove_user.sh [user]
#EXAMPLE: ./remove_user.sh alex

source admin.conf

USER="$1"

#Check arguments

if !(id "$USER" &>/dev/null); then
	echo "User not found, quitting."
	exit 1
fi


#Reclaim ownership of files user might own
#reclaim $(find "$LAB" -depth -user "$USER")

# -depth for depth first, so files in directories are 'reclaimed' before
# the directories containing them are
for file in $(find "$LAB" -depth -user "$USER")
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

#Remove the user's permissions recursively
setfacl -Rnx u:"$USER" -- "$LAB"
setfacl -Rnk u:"$USER" -- "$LAB"

#For logging...
echo $(date +"%x %X") - Removed $USER from lab and all projects >> "$ADMIN_LOG"

