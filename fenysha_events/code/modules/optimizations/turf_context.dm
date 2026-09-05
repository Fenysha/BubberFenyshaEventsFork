/// Turfs keep their signal registrations across ChangeTurf on purpose (see the warning in change_turf.dm), so a
/// turf that was contextual before re-registers on its next Initialize and RegisterSignal warns. Overriding is
/// what we actually want - the new turf's add_context replaces the previous type's - and it avoids a stack_trace
/// per turf, which was over half the wall time of a station load.
/turf/register_context()
	flags_1 |= HAS_CONTEXTUAL_SCREENTIPS_1
	RegisterSignal(src, COMSIG_ATOM_REQUESTING_CONTEXT_FROM_ITEM, TYPE_PROC_REF(/atom, add_context), override = TRUE)
