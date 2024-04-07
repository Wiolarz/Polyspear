class_name TestTools

extends GutTest


static func list_files_in_folder(
		folder_path : String,
		return_full_path : bool = false,
		scan_subfolders : bool = false) -> Array[String]:
	var dir = DirAccess.open(folder_path)
	if not dir:
			print("Error opening folder:", folder_path)
			return []
	var result:Array[String] = []
	for file in dir.get_files():
		var name_to_add = file
		if return_full_path:
			name_to_add = dir.get_current_dir() + "/" + name_to_add
		result.append(name_to_add)
	if scan_subfolders:
		for subdir in dir.get_directories():
			var subdirFiles = list_files_in_folder(\
				dir.get_current_dir() + "/" + subdir, return_full_path, true)
			if not return_full_path:
				subdirFiles = subdirFiles.map(\
					func add_prefix(fileName): return subdir + "/" + fileName)
			result.append_array(subdirFiles)
	return result
