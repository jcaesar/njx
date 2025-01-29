reset_keep_open = false
keep_open_val = nil
function nopause()
	print("Not pausing after current")
	if keep_open_val ~= nil then
		mp.set_property("keep-open", keep_open_val)
	end
	reset_keep_open = false
end
function pause_after_current()
	if reset_keep_open == false then
		keep_open_val = mp.get_property("keep-open")
		reset_keep_open = true
		mp.set_property("keep-open", "always")
		print("Pause after current. (keep-open: " .. mp.get_property("keep-open") .. ")")
	else
		nopause()
	end
end
function on_pause_change(name, value)
	if reset_keep_open then
		nopause()
	end
end
mp.observe_property("pause", "bool", on_pause_change)
mp.add_key_binding("P", "pause_after_current", pause_after_current)
