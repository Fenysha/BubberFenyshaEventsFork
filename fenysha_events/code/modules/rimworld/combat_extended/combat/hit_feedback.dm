/proc/rw_flinch_animation(mob/living/target)
	var/dx = pick(-3, 3)
	var/dy = pick(-2, 0, 2)
	animate(target, pixel_x = dx, pixel_y = dy, time = 1, flags = ANIMATION_RELATIVE|ANIMATION_PARALLEL)
	animate(pixel_x = -dx, pixel_y = -dy, time = 2, flags = ANIMATION_RELATIVE)

/proc/rw_flash_color(mob/living/target, flash_color = "#ff7070", speed = 2)
	if(target.stat == DEAD)
		return
	var/old_color = target.color
	animate(target, color = flash_color, time = speed)
	animate(color = old_color, time = speed)
