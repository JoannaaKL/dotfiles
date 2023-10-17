
clean(){
	items=$(gh codespace list --json name,state | jq -c -r '.[] | select(.state | contains("Shutdown")) | .name')
	for i in $items; do
    	echo "Deleting codespace $i"
	result=$(gh codespace delete -c $i)
	done
}
clean
