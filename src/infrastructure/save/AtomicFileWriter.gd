class_name AtomicFileWriter
extends RefCounted
## Temp-write, readback verification, backup, and same-directory atomic replacement.


func write_text(
	final_path: String,
	backup_path: String,
	contents: String,
	verifier: Callable,
	fault_after_step: StringName = &""
) -> AtomicWriteResult:
	var result := AtomicWriteResult.new()
	var absolute_final := ProjectSettings.globalize_path(final_path)
	var absolute_backup := ProjectSettings.globalize_path(backup_path) if not backup_path.is_empty() else ""
	var temp_path := "%s.tmp" % final_path
	var absolute_temp := ProjectSettings.globalize_path(temp_path)
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute_final.get_base_dir())
	if directory_error != OK:
		return _failure(directory_error, &"prepare_directory", "could not create save directory")
	if not absolute_backup.is_empty():
		directory_error = DirAccess.make_dir_recursive_absolute(absolute_backup.get_base_dir())
		if directory_error != OK:
			return _failure(directory_error, &"prepare_backup", "could not create backup directory")
	if FileAccess.file_exists(temp_path):
		DirAccess.remove_absolute(absolute_temp)
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return _failure(FileAccess.get_open_error(), &"write_temp", "could not open temporary save")
	file.store_string(contents)
	file.flush()
	file = null
	if fault_after_step == &"after_temp_write":
		return _failure(ERR_FILE_CANT_WRITE, &"after_temp_write", "simulated interruption after temporary write")
	if not bool(verifier.call(temp_path)):
		DirAccess.remove_absolute(absolute_temp)
		return _failure(ERR_FILE_CORRUPT, &"verify_temp", "temporary save failed readback verification")
	if fault_after_step == &"after_temp_verify":
		return _failure(ERR_FILE_CANT_WRITE, &"after_temp_verify", "simulated interruption after temporary verification")
	if FileAccess.file_exists(final_path) and not backup_path.is_empty():
		var copy_error := _copy_file(final_path, backup_path)
		if copy_error != OK:
			DirAccess.remove_absolute(absolute_temp)
			return _failure(copy_error, &"backup", "could not preserve previous save")
	if fault_after_step == &"after_backup":
		return _failure(ERR_FILE_CANT_WRITE, &"after_backup", "simulated interruption after backup")
	if fault_after_step == &"before_commit":
		return _failure(ERR_FILE_CANT_WRITE, &"before_commit", "simulated interruption before commit")
	var rename_error := DirAccess.rename_absolute(absolute_temp, absolute_final)
	if rename_error != OK:
		return _failure(rename_error, &"commit", "could not atomically replace final save")
	if not bool(verifier.call(final_path)):
		if not backup_path.is_empty() and FileAccess.file_exists(backup_path):
			restore_backup(backup_path, final_path, verifier)
		return _failure(ERR_FILE_CORRUPT, &"verify_final", "committed save failed verification")
	return result


func restore_backup(backup_path: String, final_path: String, verifier: Callable) -> AtomicWriteResult:
	if not FileAccess.file_exists(backup_path):
		return _failure(ERR_FILE_NOT_FOUND, &"restore_backup", "backup file is missing")
	var recovery_path := "%s.recovery.tmp" % final_path
	var copy_error := _copy_file(backup_path, recovery_path)
	if copy_error != OK:
		return _failure(copy_error, &"restore_copy", "could not copy backup for recovery")
	if not bool(verifier.call(recovery_path)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(recovery_path))
		return _failure(ERR_FILE_CORRUPT, &"restore_verify", "backup failed recovery verification")
	var rename_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(recovery_path),
		ProjectSettings.globalize_path(final_path)
	)
	if rename_error != OK:
		return _failure(rename_error, &"restore_commit", "could not restore backup atomically")
	return AtomicWriteResult.new()


func _copy_file(source_path: String, destination_path: String) -> Error:
	var source := FileAccess.open(source_path, FileAccess.READ)
	if source == null:
		return FileAccess.get_open_error()
	var destination := FileAccess.open(destination_path, FileAccess.WRITE)
	if destination == null:
		return FileAccess.get_open_error()
	destination.store_buffer(source.get_buffer(source.get_length()))
	destination.flush()
	return OK


func _failure(error: Error, step: StringName, message: String) -> AtomicWriteResult:
	var result := AtomicWriteResult.new()
	result.error = error
	result.step = step
	result.message = message
	return result
