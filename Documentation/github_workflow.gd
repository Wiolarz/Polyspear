extends Node


var IDEAS_FOR_BETTER_WORKFLOW
"""
During 'merge request procedure' it's a common occurence to face many conflicts.

This file presents methods that can help avoid problems like those in the future.



"""



var workflow
"""
each branch should focus on editing only a copule of scenes. 2 people shouldnt edit the same scene.

Before adding something new on your branch to the main scene. Add an empty object scene to the main branch.
So that in your branch you only edit, what this scene contains
"""






var project_dot_godot_changes
"""
When we want to change something global, like input names.

We should first do a small commit to the main branch with this small tweak, so that other developers can account for it.


"""



var basic_map_changes
"""
When we want to apply changes to the basic map, make those on a copy with added new map version

So that a person responsible for merging will apply other branches changes to a new map




"""
