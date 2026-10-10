#define ATOM_CAST_SHADOW (1<<0)
#define ATOM_SHADOW_USE_ICON_STATE (1<<1)
/// Extra pure-black, fully opaque footprint that is drawn OUTSIDE of the FOV pipeline,
/// so it ignores the observer/meson dimming. Used by /turf/cordon/absolute.
/// NOTE: this used to be (1<<1) - the same bit as ATOM_SHADOW_USE_ICON_STATE - which made every wall "absolute".
#define ATOM_SHADOW_ABSOLUTE (1<<2)

#define SMOOTH_GROUP_SHADOWMASK S_OBJ(199)

#define SHADOW_BLUR_HALO_A 4
#define SHADOW_BLUR_HALO_B 3
#define SHADOW_BLUR_CORE_A 1.5
/// Light blur on the mask base plane, removes the stair-steps left by the displace chain
#define SHADOW_BLUR_BASE 1
/// Mask strength while wearing mesons (was plane alpha 150/255)
#define SHADOW_MESON_STRENGTH (150/255)

/// How the shadow-origin sign is applied. If shadows move the WRONG way while looking, flip this to 1.
#define SHADOW_ORIGIN_SIGN -1


#define SHADOW_MAP_ICON 'fenysha_events/icons/shadows/walls_fov_wide.dmi'
/// Safety gap (px) kept between the edge of the displace map and the edge of the screen
#define SHADOW_MAP_MARGIN 4
/// Only this fraction of the displace map is trusted: its gradient fades/saturates near the border,
/// so shadows break up there even though the map is technically still "under" the pixel.
#define SHADOW_MAP_EFFECTIVE 0.88

/// Stages 0..11 are the displace chain, 12 is the visual plane (same layout as WALLS_FOV_PLANE_0..12)
#define CORDON_CHAIN_STAGES 13
/// Cordon chain planes sit half a step above their WALLS_FOV_PLANE_x twin. Plane MASTERS only, no atom is ever drawn on them.
#define CORDON_FOV_PLANE(main_plane) ((main_plane) + 0.5)
/// Color of the mask atoms of /turf/cordon/absolute: black with a barely visible blue tint (rgb 0,0,15), alpha untouched.
/// The tint is invisible on the normal shadows, but the cordon chain can pick it out (b - g).
#define CORDON_MARK_COLOR list(0,0,0,0, 0,0,0,-20, 0,0,0,20, 0,0,0,1, 0,0,0.06,0)
/// alpha = (b - g) * 20  ->  only the tinted cordon mask survives, as a black shape. Normal (neutral) shadows give 0.
#define CORDON_EXTRACT_COLOR list(0,0,0,0, 0,0,0,-20, 0,0,0,20, 0,0,0,0, 0,0,0,0)
