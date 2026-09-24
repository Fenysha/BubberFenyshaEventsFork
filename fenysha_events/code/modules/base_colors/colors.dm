/**
 * Color utilities + base_color system
 *
 * base_color — natural / original color of the atom.
 * color      — currently applied color.
 *
 * Color-dependent atoms can override on_color_updated() without
 * registering signals on themselves.
 */


/atom
	var/base_color = null


/atom/proc/on_color_updated(old_color, new_color, duration = 0)
	return


/atom/proc/set_base_color(new_color)
	var/old_base = base_color
	var/old_color = color

	base_color = new_color
	color = new_color

	if(old_base != new_color)
		SEND_SIGNAL(src, COMSIG_ATOM_BASE_COLOR_CHANGED, old_base, new_color)

	if(old_color != new_color)
		on_color_updated(old_color, new_color)

		SEND_SIGNAL(src, COMSIG_ATOM_COLOR_UPDATED, old_color, new_color)


/atom/proc/reset_to_base_color(duration = 0.5)
	if(!base_color || color == base_color)
		return

	var/old_color = color
	var/new_color = base_color

	if(duration > 0)
		animate(
			src,
			color = new_color,
			time = duration,
			easing = LINEAR_EASING
		)
	else
		color = new_color

	on_color_updated(old_color, new_color, duration)

	SEND_SIGNAL(src, COMSIG_ATOM_COLOR_UPDATED, old_color, new_color)


/atom/proc/modulate_color_towards(target, amount = 0.5, duration = 0.5)
	var/base = base_color || color
	if(!base)
		return

	var/new_color = blend_towards(base, target, amount)
	if(color == new_color)
		return

	var/old_color = color

	animate(
		src,
		color = new_color,
		time = duration,
		easing = LINEAR_EASING
	)

	on_color_updated(old_color, new_color, duration)

	SEND_SIGNAL(src, COMSIG_ATOM_COLOR_UPDATED, old_color, new_color)
	SEND_SIGNAL(src, COMSIG_ATOM_COLOR_MODULATED, old_color, new_color, amount)


/atom/proc/apply_color_tint(target_tint, amount = 0.5, duration = 0.5)
	modulate_color_towards(target_tint, amount, duration)


/atom/proc/multiply_current_color(tint, duration = 0.5)
	var/new_color

	if(!color)
		new_color = tint
	else
		new_color = multiply_color(color, tint)

	if(color == new_color)
		return

	var/old_color = color

	animate(
		src,
		color = new_color,
		time = duration,
		easing = LINEAR_EASING
	)

	on_color_updated(old_color, new_color, duration)

	SEND_SIGNAL(src, COMSIG_ATOM_COLOR_UPDATED, old_color, new_color)


/atom/proc/apply_tint_from_base(tint, duration = 0.5)
	if(!base_color)
		return

	var/new_color = multiply_color(base_color, tint)
	if(color == new_color)
		return

	var/old_color = color

	animate(
		src,
		color = new_color,
		time = duration,
		easing = LINEAR_EASING
	)

	on_color_updated(old_color, new_color, duration)

	SEND_SIGNAL(src, COMSIG_ATOM_COLOR_UPDATED, old_color, new_color)
	SEND_SIGNAL(src, COMSIG_ATOM_COLOR_MODULATED, old_color, new_color, 1.0)
