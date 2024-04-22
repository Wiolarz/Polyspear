extends GutHookScript

# needs to be added as post-run hook in gut config
# see .gutconfig.json
# or use the gut UI

func run():
	# script to print orphans after tests are run
	Node.print_orphan_nodes()
