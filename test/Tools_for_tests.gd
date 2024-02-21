class_name TestTools

extends GutTest


static func list_files_in_folder(folder_path : String, return_full_path : bool = false) -> Array[String]:
	var dir = DirAccess.open(folder_path)
	var scenes:Array[String] = []

	if dir:
		for file in dir.get_files():
			if return_full_path:
				scenes.append(folder_path + "/" + file)
			else:
				scenes.append(file)
	else:
		print("Error opening folder:", folder_path)
	dir = null
	return scenes
