class_name ContentHashBuilder
extends RefCounted
## Stable SHA-256 over sorted runtime source paths and exact bytes.


func compute(paths: Array[String], report: ContentLoadReport = null) -> String:
	var sorted_paths := paths.duplicate()
	sorted_paths.sort()
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK:
		if report != null:
			report.add_error(&"hash", "ContentHashBuilder", "could not initialize SHA-256")
		return ""
	for path: String in sorted_paths:
		if not FileAccess.file_exists(path):
			if report != null:
				report.add_error(&"hash", path, "source file is missing")
			continue
		context.update(path.to_utf8_buffer())
		context.update(PackedByteArray([0]))
		context.update(FileAccess.get_file_as_bytes(path))
		context.update(PackedByteArray([0]))
		if report != null:
			report.record_check(&"hash")
	return context.finish().hex_encode()
