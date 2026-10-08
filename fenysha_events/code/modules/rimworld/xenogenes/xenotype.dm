/datum/rw_xenotype
	/// Stable preset id when this xenotype came from the shared browser.
	var/id
	var/name = "Custom xenotype"
	var/description = "A unique combination of xenogenes."
	/// Xenotype icon uses a gene's existing DMI icon; the selected gene id is stored here.
	var/icon_gene
	/// Body species path, separate from xenotype gene data.
	var/species_path
	var/list/genes = list()
	var/list/gene_values = list()

/datum/rw_xenotype/Destroy()
	genes = null
	gene_values = null
	return ..()

/datum/rw_xenotype/proc/make_copy()
	var/datum/rw_xenotype/copy = new
	copy.id = id
	copy.name = name
	copy.description = description
	copy.icon_gene = icon_gene
	copy.species_path = species_path
	copy.genes = list()
	for(var/gene_id in genes)
		copy.genes += gene_id
	copy.gene_values = list()
	for(var/gene_id in gene_values)
		copy.gene_values[gene_id] = gene_values[gene_id]
	return copy

/datum/rw_xenotype/proc/compile_ui_data()
	var/datum/species/species = GLOB.species_prototypes[text2path(species_path)]
	var/list/gene_rows = list()
	var/list/icon_data
	for(var/gene_id in genes)
		var/datum/rw_xenogene/gene = GLOB.all_rw_xenogenes[gene_id]
		if(!gene)
			continue
		var/list/row = list(
			"id" = gene.id,
			"name" = gene.name,
			"desc" = gene.desc,
			"category" = gene.category,
			"negative" = gene.negative,
			"iconSrc" = gene.compile_icon_png(gene.icon_state),
			"iconBgSrc" = gene.compile_icon_png(gene.icon_bg),
		)
		gene_rows += list(row)
		if(gene_id == icon_gene)
			icon_data = list(
				"src" = gene.compile_icon_png(gene.icon_state),
				"background" = gene.compile_icon_png(gene.icon_bg),
			)
	if(!islist(icon_data) && length(gene_rows))
		var/list/first = gene_rows[1]
		icon_data = list("src" = first["iconSrc"], "background" = first["iconBgSrc"])
	return list(
		"id" = id || "custom",
		"name" = name || "Custom xenotype",
		"description" = description || "A unique combination of xenogenes.",
		"icon" = icon_data || list(),
		"species" = species?.rw_label || species?.name || species_path || "Unknown race",
		"genes" = gene_rows,
	)
