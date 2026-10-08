/datum/dna
	/// Rimworld xenotype identity, separate from the physical species datum.
	var/datum/rw_xenotype/rw_xenotype
	/// Rimworld xenogenes belonging specifically to this DNA.
	/// Key = xenogene id
	/// Value = unique /datum/rw_xenogene instance
	var/list/rw_xenogenes

/datum/dna/Destroy()
	purge_rw_xenogenes()
	return ..()

/datum/dna/proc/set_rw_xenotype(list/gene_ids, list/option_values = null, new_species_path, new_name = null, new_description = null, new_icon_gene = null, new_id = null)
	QDEL_NULL(rw_xenotype)
	rw_xenotype = new /datum/rw_xenotype
	rw_xenotype.genes = list()
	if(islist(gene_ids))
		for(var/gene_id in gene_ids)
			if(GLOB.all_rw_xenogenes[gene_id])
				rw_xenotype.genes += gene_id
	rw_xenotype.gene_values = list()
	if(islist(option_values))
		for(var/gene_id in option_values)
			var/datum/rw_xenogene/gene = GLOB.all_rw_xenogenes[gene_id]
			if(gene && (gene_id in rw_xenotype.genes))
				rw_xenotype.gene_values[gene_id] = gene.sanitize_option(option_values[gene_id])
	rw_xenotype.species_path = "[new_species_path]"
	rw_xenotype.name = new_name || "Custom xenotype"
	rw_xenotype.description = new_description || "A unique combination of xenogenes."
	rw_xenotype.icon_gene = new_icon_gene
	rw_xenotype.id = new_id
	return rw_xenotype


/// Hard reset of this DNA's xenogene state without running visual cleanup. Used on pooled/preview
/// dummies so one character's genes can never leak into the next one rendered on the same dummy.
/datum/dna/proc/purge_rw_xenogenes()
	if(islist(rw_xenogenes))
		for(var/gene_id in rw_xenogenes)
			var/datum/rw_xenogene/gene = rw_xenogenes[gene_id]
			if(!gene)
				continue
			gene.holder = null
			qdel(gene)
	rw_xenogenes = list()
	QDEL_NULL(rw_xenotype)

/// innate_ids: gene ids that come from the race. Everything else is ACQUIRED. Source flags are
/// authoritative from the preferences, so a gene can never stay on a body after its race is gone.
/datum/dna/proc/set_rw_xenogenes(list/new_ids, list/option_values = null, apply = TRUE, list/innate_ids = null)
	if(!rw_xenogenes)
		rw_xenogenes = list()
	if(!islist(new_ids))
		new_ids = list()
	if(!islist(innate_ids))
		innate_ids = list()

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

	// Palette first, so parts that copy mutant colors read the final colors.
	var/list/ordered = list()
	if(RW_XENOGENE_MUTANT_COLORS in new_ids)
		ordered += RW_XENOGENE_MUTANT_COLORS
	for(var/gene_id in new_ids)
		if(gene_id != RW_XENOGENE_MUTANT_COLORS)
			ordered += gene_id

	for(var/gene_id in ordered)
		var/option_value
		if(islist(option_values))
			option_value = option_values[gene_id]
		var/source = (gene_id in innate_ids) ? RW_XENOGEN_SOURCE_INNATE : RW_XENOGEN_SOURCE_ACQUIRED
		var/datum/rw_xenogene/existing = rw_xenogenes[gene_id]
		var/already = !!existing
		var/old_option
		if(existing)
			old_option = existing.option_value
		add_rw_xenogene(gene_id, option_value, FALSE, source)
		existing = rw_xenogenes[gene_id]
		if(!existing)
			continue
		existing.xenogen_source_flags = source
		if(!apply || !holder)
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


/// Sum the metabolic-efficiency points from active RimWorld genes.
/datum/dna/proc/get_rw_metabolic_efficiency()
	var/total_efficiency = 0
	if(!length(rw_xenogenes))
		return total_efficiency
	for(var/gene_id in rw_xenogenes)
		var/datum/rw_xenogene/gene = rw_xenogenes[gene_id]
		if(gene)
			total_efficiency += gene.metabolic_efficiency
	return total_efficiency


/datum/dna/proc/has_rw_xenogene(gene_id)
	return !!get_rw_xenogene(gene_id)


/datum/dna/proc/has_innate_rw_xenogene(gene_id)
	var/datum/rw_xenogene/gene = get_rw_xenogene(gene_id)

	if(!gene)
		return FALSE

	return gene.is_innate()
