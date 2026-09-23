/datum/dna
	/// Rimworld xenogene ids currently on this DNA. Singletons live in GLOB.all_rw_xenogenes.
	var/list/rw_xenogenes

/datum/dna/proc/set_rw_xenogenes(list/new_ids, apply = TRUE)
	if(apply)
		remove_rw_xenogenes()
	rw_xenogenes = new_ids?.Copy()
	if(apply)
		apply_rw_xenogenes()

/datum/dna/proc/apply_rw_xenogenes()
	if(!holder || !length(rw_xenogenes))
		return
	for(var/gene_id in rw_xenogenes)
		var/datum/rw_xenogene/gene = GLOB.all_rw_xenogenes[gene_id]
		gene?.on_gain(holder)

/datum/dna/proc/remove_rw_xenogenes()
	if(!holder || !length(rw_xenogenes))
		return
	for(var/gene_id in rw_xenogenes)
		var/datum/rw_xenogene/gene = GLOB.all_rw_xenogenes[gene_id]
		gene?.on_lose(holder)
