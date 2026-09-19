/// Keys pressed while the lobby page has focus go to the browser, never to BYOND's macros, so
/// hotkeys like T do nothing until the map is clicked. This hands that first key to the
/// server's KeyDown like the map would, and moves focus to the map for everything after.
/// Its release is forwarded too if it beats the focus change, or the server would think it is
/// still held - a stuck Ctrl turns every later key into a Ctrl combo.
/// DM strings treat square brackets and backslashes specially, so the script avoids both.
/proc/lobby_key_forwarding_script()
	return {"
	<script>
		function byond_key(e) {
			var code = e.code || "";
			if (code.indexOf("Key") === 0 || code.indexOf("Digit") === 0) {
				return code.charAt(code.length - 1);
			}
			switch (e.key) {
				case "ArrowUp": return "North";
				case "ArrowDown": return "South";
				case "ArrowLeft": return "West";
				case "ArrowRight": return "East";
				case "Control": return "Ctrl";
				case "Shift": return "Shift";
				case "Alt": return "Alt";
				case " ": return "Space";
				case "Enter": return "Return";
				case "Backspace": return "Back";
				case "Tab": return "Tab";
				case "Delete": return "Delete";
			}
			if (e.key.length === 1) {
				return e.key;
			}
			if (e.key.charAt(0) === "F" && !isNaN(e.key.substring(1))) {
				return e.key;
			}
			return null;
		}

		function byond_command(command) {
			location.href = "byond://winset?command=" + encodeURIComponent(command);
		}

		var forwarded_keys = {};

		document.addEventListener("keydown", function(e) {
			var tag = String(e.target && e.target.tagName).toLowerCase();
			if (tag === "input" || tag === "textarea" || e.repeat) {
				return;
			}
			var key = e.key === "Escape" ? null : byond_key(e);
			if (key) {
				forwarded_keys\[key\] = true;
				byond_command('KeyDown "' + key + '" 0 0 0 0');
			}
			e.preventDefault();
			setTimeout(function() {
				location.href = "byond://winset?id=map&focus=true";
			}, 0);
		});

		document.addEventListener("keyup", function(e) {
			var key = byond_key(e);
			if (key && forwarded_keys\[key\]) {
				delete forwarded_keys\[key\];
				byond_command('KeyUp "' + key + '" 0 0 0 0');
			}
		});
	</script>
	"}
