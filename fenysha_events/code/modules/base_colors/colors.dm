/**
 * Color utilities + base_color system
 *
 * base_color  — the natural / original color of the atom (reference point)
 * color       — the currently applied / displayed color
 *
 * Used for seasonal changes, weather effects, biome tinting, etc.
 */
/atom
	/// Natural / original color of the atom. Used as reference for transitions.
	var/base_color = null

/**
 * Sets base_color and immediately applies it as the current color.
 * Call this during initialization or when you want to fully reset the atom.
 */
/atom/proc/set_base_color(new_color)
	var/old_base = base_color
	var/old_color = color

	base_color = new_color
	color = new_color

	if(old_base != base_color)
		SEND_SIGNAL(src, COMSIG_ATOM_BASE_COLOR_CHANGED, old_base, base_color)

	if(old_color != color)
		SEND_SIGNAL(src, COMSIG_ATOM_COLOR_UPDATED, old_color, color)

/**
 * Instantly restores the atom to its base_color.
 */
/atom/proc/reset_to_base_color()
	if(!base_color)
		return

	var/old_color = color
	color = base_color

	if(old_color != color)
		SEND_SIGNAL(src, COMSIG_ATOM_COLOR_UPDATED, old_color, color)

/**
 * Shifts the current color towards a target, using base_color as the reference.
 *
 * amount:
 *   0.0 — fully base_color
 *   1.0 — fully target
 *   0.3 — 30% target + 70% base
 *
 * If base_color is not set, falls back to the current color as base.
 */
/atom/proc/modulate_color_towards(target, amount = 0.5)
	var/base = base_color || color
	if(!base)
		return

	var/old_color = color
	color = blend_towards(base, target, amount)

	if(old_color != color)
		SEND_SIGNAL(src, COMSIG_ATOM_COLOR_UPDATED, old_color, color)
		SEND_SIGNAL(src, COMSIG_ATOM_COLOR_MODULATED, old_color, color, amount)

/**
 * Convenience wrapper for modulate_color_towards().
 */
/atom/proc/apply_color_tint(target_tint, amount = 0.5)
	modulate_color_towards(target_tint, amount)

/**
 * Multiplies the current color by a tint.
 * Useful when you want to layer an additional shade on top of the existing color.
 */
/atom/proc/multiply_current_color(tint)
	var/old_color = color

	if(!color)
		color = tint
	else
		color = multiply_color(color, tint)

	if(old_color != color)
		SEND_SIGNAL(src, COMSIG_ATOM_COLOR_UPDATED, old_color, color)

/**
 * Multiplies base_color by a tint and applies the result as the current color.
 * Does not modify base_color itself.
 */
/atom/proc/apply_tint_from_base(tint)
	if(!base_color)
		return

	var/old_color = color
	color = multiply_color(base_color, tint)

	if(old_color != color)
		SEND_SIGNAL(src, COMSIG_ATOM_COLOR_UPDATED, old_color, color)
		SEND_SIGNAL(src, COMSIG_ATOM_COLOR_MODULATED, old_color, color, 1.0)

