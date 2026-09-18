// ============================================================================
// Low-level color helpers
// ============================================================================

/**
 * Parse "#RRGGBB" or "#RGB" into list(r, g, b) in 0-255 range.
 * Returns null on failure.
 */
/proc/parse_color(color)
	if(!istext(color))
		return null

	color = lowertext(color)
	if(copytext(color, 1, 2) != "#")
		return null

	var/len = length(color)
	var/r, g, b

	if(len == 7) // #RRGGBB
		r = hex2num(copytext(color, 2, 4))
		g = hex2num(copytext(color, 4, 6))
		b = hex2num(copytext(color, 6, 8))
	else if(len == 4) // #RGB
		r = hex2num(copytext(color, 2, 3)) * 17
		g = hex2num(copytext(color, 3, 4)) * 17
		b = hex2num(copytext(color, 4, 5)) * 17
	else
		return null

	return list(r, g, b)

/**
 * Convert list(r, g, b) back to "#RRGGBB"
 */
/proc/format_color(list/rgb)
	if(!islist(rgb) || length(rgb) < 3)
		return null

	var/r = clamp(round(rgb[1]), 0, 255)
	var/g = clamp(round(rgb[2]), 0, 255)
	var/b = clamp(round(rgb[3]), 0, 255)

	return "#[num2hex(r, 2)][num2hex(g, 2)][num2hex(b, 2)]"

/**
 * Linear interpolation between two colors.
 * amount: 0.0 = color_a, 1.0 = color_b
 */
/proc/lerp_color(color_a, color_b, amount = 0.5)
	var/list/a = parse_color(color_a)
	var/list/b = parse_color(color_b)

	if(!a || !b)
		return color_a // fallback

	amount = clamp(amount, 0, 1)

	var/list/result = list(
		a[1] + (b[1] - a[1]) * amount,
		a[2] + (b[2] - a[2]) * amount,
		a[3] + (b[3] - a[3]) * amount
	)

	return format_color(result)

/**
 * Multiply two colors (component-wise).
 * Useful for tinting grayscale icons.
 */
/proc/multiply_color(color_a, color_b)
	var/list/a = parse_color(color_a)
	var/list/b = parse_color(color_b)

	if(!a || !b)
		return color_a

	var/list/result = list(
		(a[1] * b[1]) / 255,
		(a[2] * b[2]) / 255,
		(a[3] * b[3]) / 255
	)

	return format_color(result)

/**
 * Blend color towards a target using base as the identity point.
 *
 * amount = 0 → returns base
 * amount = 1 → returns target
 * amount = 0.5 → midpoint between base and target
 */
/proc/blend_towards(base, target, amount = 0.5)
	return lerp_color(base, target, amount)
