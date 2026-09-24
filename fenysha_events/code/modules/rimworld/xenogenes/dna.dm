/datum/dna
	/// Rimworld xenogenes belonging specifically to this DNA.
	/// Key = xenogene id
	/// Value = unique /datum/rw_xenogene instance
	var/list/rw_xenogenes


/datum/dna/proc/set_rw_xenogenes(list/new_ids, list/option_values = null, apply = TRUE)
	if(!rw_xenogenes)
		rw_xenogenes = list()
	if(!islist(new_ids))
		new_ids = list()

	var/list/wanted = list()
	for(var/gene_id in new_ids)
		wanted[gene_id] = TRUE

	for(var/gene_id in rw_xenogenes.Copy())
		if(wanted[gene_id])
			continue
		var/datum/rw_xenogene/stale = rw_xenogenes[gene_id]
		if(!stale)
			rw_xenogenes -= gene_id
			continue
		remove_rw_xenogene(gene_id, stale.xenogen_source_flags)

	for(var/gene_id in new_ids)
		var/option_value
		if(islist(option_values))
			option_value = option_values[gene_id]
		var/datum/rw_xenogene/existing = rw_xenogenes[gene_id]
		var/already = !!existing
		var/old_option
		if(existing)
			old_option = existing.option_value
		add_rw_xenogene(gene_id, option_value, FALSE, RW_XENOGEN_SOURCE_ACQUIRED)
		existing = rw_xenogenes[gene_id]
		if(!apply || !holder || !existing)
			continue
		if(!already || (!isnull(option_value) && old_option != existing.option_value))
			existing.on_gain(holder)


/datum/dna/proc/add_rw_xenogene(gene_id, option_value = null, apply = TRUE, source_flags = RW_XENOGEN_SOURCE_ACQUIRED)
	if(!gene_id)
		return null

	if(!rw_xenogenes)
		rw_xenogenes = list()

	var/datum/rw_xenogene/gene = rw_xenogenes[gene_id]

	if(gene)
		var/old_option = gene.option_value
		gene.xenogen_source_flags |= source_flags
		if(!isnull(option_value))
			gene.option_value = gene.sanitize_option(option_value)
		if(apply && holder && old_option != gene.option_value)
			gene.on_gain(holder)
		return gene

	var/datum/rw_xenogene/prototype = GLOB.all_rw_xenogenes[gene_id]
	if(!prototype)
		stack_trace("Unknown Rimworld xenogene id: [gene_id]")
		return null

	var/list/conflicts = prototype.conflicts_with_ids(rw_xenogenes)
	if(length(conflicts))
		return null

	gene = prototype.create_instance(holder, source_flags)
	if(!isnull(option_value))
		gene.option_value = gene.sanitize_option(option_value)
	rw_xenogenes[gene_id] = gene

	if(apply && holder)
		gene.on_gain(holder)

	return gene


/datum/dna/proc/apply_rw_xenogenes()
	if(!holder || !length(rw_xenogenes))
		return

	for(var/gene_id in rw_xenogenes)
		var/datum/rw_xenogene/gene = rw_xenogenes[gene_id]
		if(!gene)
			continue

		gene.on_gain(holder)


/datum/dna/proc/remove_rw_xenogenes()
	if(!length(rw_xenogenes))
		return

	var/list/to_remove = list()

	for(var/gene_id in rw_xenogenes)
		var/datum/rw_xenogene/gene = rw_xenogenes[gene_id]

		if(!gene)
			to_remove += gene_id
			continue

		// This only removes acquired genes.
		// Innate genes are deliberately untouched.
		if(!(gene.xenogen_source_flags & RW_XENOGEN_SOURCE_ACQUIRED))
			continue

		remove_rw_xenogene(gene_id, RW_XENOGEN_SOURCE_ACQUIRED)

	for(var/gene_id in to_remove)
		rw_xenogenes -= gene_id


/datum/dna/proc/remove_rw_xenogene(gene_id, source_flag = RW_XENOGEN_SOURCE_ACQUIRED)
	if(!rw_xenogenes)
		return FALSE

	var/datum/rw_xenogene/gene = rw_xenogenes[gene_id]
	if(!gene)
		return FALSE

	if(!(gene.xenogen_source_flags & source_flag))
		return FALSE

	gene.xenogen_source_flags &= ~source_flag

	// Another source still keeps the gene alive.
	if(gene.xenogen_source_flags)
		return TRUE

	gene.on_lose(holder)
	rw_xenogenes -= gene_id
	qdel(gene)

	return TRUE


/datum/dna/proc/get_rw_xenogene(gene_id)
	if(!rw_xenogenes)
		return null

	return rw_xenogenes[gene_id]


/datum/dna/proc/has_rw_xenogene(gene_id)
	return !!get_rw_xenogene(gene_id)


/datum/dna/proc/has_innate_rw_xenogene(gene_id)
	var/datum/rw_xenogene/gene = get_rw_xenogene(gene_id)

	if(!gene)
		return FALSE

	return gene.is_innate()
