PROCESSING_SUBSYSTEM_DEF(xenogenes)
	name = "\[RW\] Xenogenes"
	ss_flags = SS_BACKGROUND | SS_KEEP_TIMING
	stat_tag = "X"
	wait = 1 SECONDS



/datum/controller/subsystem/processing/xenogenes
	/// Shared server-side xenotype presets, indexed by stable id.
	var/list/saved_xenotypes = list()
	/// Admin-pinned gene ids shown above the normal catalog for every player.
	var/list/pinned_genes = list()
	var/xenotype_save_path = "data/rimworld_xenotypes.json"
	var/next_xenotype_id = 1


/datum/controller/subsystem/processing/xenogenes/Initialize()
	if(!length(GLOB.all_rw_xenogenes) && SSrw_character)
		SSrw_character.init_singletons()
	load_baseline_xenotypes()
	load_xenotypes()
	if(SSticker)
		SSticker.OnRoundend(CALLBACK(src, PROC_REF(save_xenotypes)))
	return SS_INIT_SUCCESS

/datum/controller/subsystem/processing/xenogenes/proc/load_baseline_xenotypes()
	var/list/base_species_paths = list(/datum/species/human, /datum/species/avali, /datum/species/lizard)
	for(var/species_path in base_species_paths)
		var/datum/species/species = GLOB.species_prototypes[species_path]
		var/temporary_species = FALSE
		if(!species)
			species = new species_path
			temporary_species = TRUE
		if(!species?.rw_default_xenotype_id)
			if(temporary_species)
				qdel(species)
			continue
		var/list/genes = list()
		var/list/values = list()
		var/icon_gene_id
		for(var/gene_id in species.rw_innate_xenogenes)
			if(!GLOB.all_rw_xenogenes[gene_id])
				continue
			genes += gene_id
			var/datum/rw_xenogene/gene = GLOB.all_rw_xenogenes[gene_id]
			if(!icon_gene_id && (gene.icon_state || gene.icon_bg))
				icon_gene_id = gene_id
			var/option_value = species.rw_innate_xenogene_values?[gene_id]
			if(gene.option_kind != RW_XENOGENE_OPTION_NONE)
				values[gene_id] = gene.sanitize_option(isnull(option_value) ? gene.default_option : option_value)
		var/list/baseline = list(
			"id" = species.rw_default_xenotype_id,
			"name" = "[species.rw_label || species.name] baseline",
			"description" = "Default xenotype for [species.rw_label || species.name].",
			"iconGene" = icon_gene_id,
			"species" = "[species_path]",
			"genes" = genes,
			"values" = values,
			"favorite" = FALSE,
			"pinned" = FALSE,
			"builtin" = TRUE,
			"creator" = "server",
		)
		saved_xenotypes[species.rw_default_xenotype_id] = baseline
		if(temporary_species)
			qdel(species)

/datum/controller/subsystem/processing/xenogenes/proc/set_dna_species_baseline(datum/dna/dna, datum/species/species)
	if(!dna || !species?.rw_default_xenotype_id)
		return FALSE
	var/list/entry = saved_xenotypes[species.rw_default_xenotype_id]
	var/list/gene_ids = list()
	var/list/values = list()
	if(islist(dna.rw_xenogenes))
		for(var/gene_id in dna.rw_xenogenes)
			var/datum/rw_xenogene/gene = dna.rw_xenogenes[gene_id]
			if(!gene)
				continue
			gene_ids += gene_id
			if(!isnull(gene.option_value))
				values[gene_id] = gene.option_value
	if(!length(gene_ids) && islist(entry))
		gene_ids = entry["genes"]
		values = entry["values"]
	var/is_baseline = islist(entry) && length(gene_ids) == length(entry["genes"])
	if(is_baseline)
		for(var/gene_id in gene_ids)
			if(!(gene_id in entry["genes"]))
				is_baseline = FALSE
				break
	var/baseline_name = is_baseline ? entry["name"] : "Custom xenotype"
	var/baseline_description = is_baseline ? entry["description"] : "A unique combination of xenogenes."
	var/icon_gene = is_baseline ? entry["iconGene"] : null
	dna.set_rw_xenotype(gene_ids, values, "[species.type]", baseline_name, baseline_description, icon_gene, is_baseline ? species.rw_default_xenotype_id : null)
	return TRUE


/datum/controller/subsystem/processing/xenogenes/Shutdown()
	save_xenotypes()
	return ..()


/datum/controller/subsystem/processing/xenogenes/proc/load_xenotypes()
	if(!islist(saved_xenotypes))
		saved_xenotypes = list()
	if(!fexists(xenotype_save_path))
		return
	var/list/root
	try
		root = json_decode(file2text(xenotype_save_path))
	catch
		root = null
	if(!islist(root) || !islist(root["xenotypes"]))
		stack_trace("Unable to load Rimworld xenotypes from [xenotype_save_path].")
		return
	pinned_genes = islist(root["pinnedGenes"]) ? root["pinnedGenes"] : list()
	for(var/list/entry as anything in root["xenotypes"])
		if(!islist(entry) || !istext(entry["id"]) || !length(entry["id"]))
			continue
		if(saved_xenotypes[entry["id"]])
			continue
		var/list/clean = sanitize_xenotype_entry(entry)
		if(!clean)
			continue
		clean["id"] = entry["id"]
		saved_xenotypes[clean["id"]] = clean
		next_xenotype_id++


/datum/controller/subsystem/processing/xenogenes/proc/save_xenotypes()
	var/list/entries = list()
	for(var/xenotype_id in saved_xenotypes)
		var/list/entry = saved_xenotypes[xenotype_id]
		if(!islist(entry) || entry["builtin"])
			continue
		var/list/gene_ids = entry["genes"]
		var/list/option_values = entry["values"]
		var/list/saved_gene_ids = list()
		var/list/saved_option_values = list()
		for(var/gene_id in gene_ids)
			saved_gene_ids += gene_id
		for(var/value_id in option_values)
			saved_option_values[value_id] = option_values[value_id]
		entries += list(list(
			"id" = xenotype_id,
			"name" = entry["name"],
			"description" = entry["description"] || "",
			"iconGene" = entry["iconGene"] || "",
			"species" = entry["species"],
			"genes" = saved_gene_ids,
			"values" = saved_option_values,
			"favorite" = !!entry["favorite"],
			"pinned" = !!entry["pinned"],
			"builtin" = !!entry["builtin"],
			"creator" = entry["creator"] || "",
		))
	var/list/root = list("version" = 2, "xenotypes" = entries)
	var/list/saved_pins = list()
	for(var/gene_id in pinned_genes)
		if(GLOB.all_rw_xenogenes[gene_id])
			saved_pins += gene_id
	root["pinnedGenes"] = saved_pins
	fdel(xenotype_save_path)
	WRITE_FILE(file(xenotype_save_path), json_encode(root))


/datum/controller/subsystem/processing/xenogenes/proc/sanitize_xenotype_entry(list/entry)
	if(!islist(entry))
		return null
	var/species_path = text2path(entry["species"])
	if(!(species_path in GLOB.rw_base_species))
		return null
	var/raw_name = entry["name"]
	var/name = trim("[raw_name]")
	if(!length(name))
		return null
	name = copytext(name, 1, 49)
	var/list/genes = list()
	var/list/values = list()
	var/list/raw_genes = entry["genes"]
	var/list/raw_values = entry["values"]
	if(islist(raw_genes))
		for(var/gene_id in raw_genes)
			var/datum/rw_xenogene/gene = GLOB.all_rw_xenogenes[gene_id]
			if(!gene || (gene_id in genes))
				continue
			genes += gene_id
			if(gene.option_kind != RW_XENOGENE_OPTION_NONE)
				values[gene_id] = gene.sanitize_option(islist(raw_values) ? raw_values[gene_id] : null)
	return list(
		"name" = name,
		"description" = copytext(trim("[entry["description"] || ""]"), 1, 513),
		"iconGene" = GLOB.all_rw_xenogenes[entry["iconGene"]] ? entry["iconGene"] : null,
		"species" = "[species_path]",
		"genes" = genes,
		"values" = values,
		"favorite" = !!entry["favorite"],
		"pinned" = !!entry["pinned"],
		"creator" = entry["creator"] || "",
	)


/datum/controller/subsystem/processing/xenogenes/proc/compile_xenotypes()
	var/list/compiled = list()
	for(var/xenotype_id in saved_xenotypes)
		var/list/entry = saved_xenotypes[xenotype_id]
		var/species_path = text2path(entry["species"])
		var/datum/species/species = GLOB.species_prototypes[species_path]
		var/list/gene_names = list()
		var/list/gene_ids = entry["genes"]
		for(var/gene_id in gene_ids)
			var/datum/rw_xenogene/gene = GLOB.all_rw_xenogenes[gene_id]
			if(gene)
				gene_names += gene.name
		var/datum/rw_xenogene/icon_gene = GLOB.all_rw_xenogenes[entry["iconGene"]]
		var/icon_src
		var/icon_bg_src
		if(icon_gene)
			icon_src = icon_gene.compile_icon_png(icon_gene.icon_state)
			icon_bg_src = icon_gene.compile_icon_png(icon_gene.icon_bg)
		compiled += list(list(
			"id" = xenotype_id,
			"name" = entry["name"],
			"species" = entry["species"],
			"speciesName" = species?.rw_label || species?.name || entry["species"],
			"genes" = gene_names,
			"geneIds" = gene_ids,
			"description" = entry["description"] || "",
			"iconGene" = entry["iconGene"] || "",
			"iconSrc" = icon_src,
			"iconBgSrc" = icon_bg_src,
			"favorite" = !!entry["favorite"],
			"pinned" = !!entry["pinned"],
			"builtin" = !!entry["builtin"],
		))
	return compiled


/datum/controller/subsystem/processing/xenogenes/proc/save_from_preferences(datum/rimworld_preferences/preferences, mob/user, preset_name, preset_description, icon_gene)
	if(!preferences || length(saved_xenotypes) >= 200)
		return FALSE
	var/list/preference_genes = preferences.xenogenes
	var/list/preference_values = preferences.xenogene_values
	var/list/saved_gene_ids = list()
	var/list/saved_option_values = list()
	for(var/gene_id in preference_genes)
		saved_gene_ids += gene_id
	for(var/value_id in preference_values)
		saved_option_values[value_id] = preference_values[value_id]
	var/list/entry = list(
		"name" = preset_name,
		"description" = preset_description,
		"iconGene" = icon_gene,
		"species" = "[preferences.rw_species()]",
		"genes" = saved_gene_ids,
		"values" = saved_option_values,
		"favorite" = FALSE,
		"creator" = user?.client?.ckey || "",
	)
	var/list/clean = sanitize_xenotype_entry(entry)
	if(!clean)
		return FALSE
	var/id = "xenotype_[world.realtime]_[next_xenotype_id++]"
	while(saved_xenotypes[id])
		id = "xenotype_[world.realtime]_[next_xenotype_id++]"
	saved_xenotypes[id] = clean
	clean["id"] = id
	preferences.xenotype_id = id
	preferences.xenotype_name = clean["name"]
	preferences.xenotype_description = clean["description"]
	preferences.xenotype_icon_gene = clean["iconGene"]
	preferences.save_character()
	preferences.update_preview()
	save_xenotypes()
	return TRUE

/datum/controller/subsystem/processing/xenogenes/proc/toggle_xenotype_pin(xenotype_id)
	var/list/entry = saved_xenotypes[xenotype_id]
	if(!islist(entry))
		return FALSE
	entry["pinned"] = !entry["pinned"]
	save_xenotypes()
	return TRUE

/datum/controller/subsystem/processing/xenogenes/proc/apply_to_preferences(datum/rimworld_preferences/preferences, xenotype_id)
	var/list/entry = saved_xenotypes[xenotype_id]
	if(!preferences || !islist(entry))
		return FALSE
	var/species_path = text2path(entry["species"])
	if(!(species_path in GLOB.rw_base_species))
		return FALSE
	var/old_species = preferences.rw_species()
	var/list/current_genes = preferences.xenogenes
	var/list/current_values = preferences.xenogene_values
	var/list/current_inheritable = preferences.xenogene_inheritable
	var/old_xenotype_id = preferences.xenotype_id
	var/old_xenotype_name = preferences.xenotype_name
	var/old_xenotype_description = preferences.xenotype_description
	var/old_xenotype_icon_gene = preferences.xenotype_icon_gene
	var/list/preset_genes = entry["genes"]
	var/list/preset_values = entry["values"]
	var/list/old_genes = list()
	var/list/old_values = list()
	var/list/old_inheritable = list()
	for(var/gene_id in current_genes)
		old_genes += gene_id
	for(var/value_id in current_values)
		old_values[value_id] = current_values[value_id]
	for(var/inheritable_id in current_inheritable)
		old_inheritable += inheritable_id
	if(!preferences.rw_set_species(species_path))
		return FALSE
	preferences.xenogenes = list()
	for(var/gene_id in preset_genes)
		preferences.xenogenes += gene_id
	preferences.xenogene_values = list()
	for(var/value_id in preset_values)
		preferences.xenogene_values[value_id] = preset_values[value_id]
	preferences.xenogene_inheritable = list()
	preferences.xenotype_name = entry["name"]
	preferences.xenotype_description = entry["description"]
	preferences.xenotype_icon_gene = entry["iconGene"]
	preferences.xenotype_id = entry["id"]
	preferences.sync_species_xenogenes()
	if(preferences.points_spent() > RW_CHARACTER_BUDGET)
		preferences.rw_set_species(old_species)
		preferences.xenogenes = old_genes
		preferences.xenogene_values = old_values
		preferences.xenogene_inheritable = old_inheritable
		preferences.xenotype_id = old_xenotype_id
		preferences.xenotype_name = old_xenotype_name
		preferences.xenotype_description = old_xenotype_description
		preferences.xenotype_icon_gene = old_xenotype_icon_gene
		preferences.sync_species_xenogenes()
		return FALSE
	preferences.save_character()
	preferences.update_preview()
	return TRUE


/datum/controller/subsystem/processing/xenogenes/proc/delete_xenotype(xenotype_id)
	var/list/entry = saved_xenotypes[xenotype_id]
	if(!islist(entry) || entry["builtin"])
		return FALSE
	saved_xenotypes -= xenotype_id
	save_xenotypes()
	return TRUE


/datum/controller/subsystem/processing/xenogenes/proc/toggle_xenotype_favorite(xenotype_id)
	var/list/entry = saved_xenotypes[xenotype_id]
	if(!islist(entry))
		return FALSE
	entry["favorite"] = !entry["favorite"]
	save_xenotypes()
	return TRUE

/datum/controller/subsystem/processing/xenogenes/proc/toggle_gene_pin(gene_id)
	if(!GLOB.all_rw_xenogenes[gene_id])
		return FALSE
	if(gene_id in pinned_genes)
		pinned_genes -= gene_id
	else
		pinned_genes += gene_id
	save_xenotypes()
	return TRUE

/datum/controller/subsystem/processing/xenogenes/proc/compile_gene_catalog()
	var/list/rows = list()
	for(var/gene_id in GLOB.all_rw_xenogenes)
		var/datum/rw_xenogene/gene = GLOB.all_rw_xenogenes[gene_id]
		if(!gene)
			continue
		rows += list(list(
			"id" = gene.id,
			"name" = gene.name,
			"desc" = gene.desc,
			"category" = gene.category,
			"effects" = gene.compile_effect_lines(),
			"complexity" = gene.complexity,
			"metabolicEfficiency" = gene.metabolic_efficiency,
			"negative" = gene.negative,
			"iconSrc" = gene.compile_icon_png(gene.icon_state),
			"iconBgSrc" = gene.compile_icon_png(gene.icon_bg),
		))
	return rows

/datum/controller/subsystem/processing/xenogenes/proc/open_browser(mob/user, admin_manager = FALSE)
	if(!istype(user) || !user.client)
		return
	var/datum/rw_xenotype_browser/browser = new(user.client, admin_manager)
	browser.ui_interact(user)


/datum/controller/subsystem/processing/xenogenes/ui_interact(mob/user, datum/tgui/ui)
	open_browser(user, TRUE)


/datum/controller/subsystem/processing/xenogenes/ui_state(mob/user)
	return ADMIN_STATE(R_ADMIN)


/datum/controller/subsystem/processing/xenogenes/ui_data(mob/user)
	return list(
		"xenotypes" = compile_xenotypes(),
		"isXenotypeAdmin" = check_rights_for(user?.client, R_ADMIN),
	)


/datum/controller/subsystem/processing/xenogenes/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(!check_rights_for(usr?.client, R_ADMIN))
		return TRUE
	switch(action)
		if("delete_xenotype")
			delete_xenotype(params["id"])
			return TRUE
		if("toggle_xenotype_favorite")
			toggle_xenotype_favorite(params["id"])
			return TRUE
		if("save_xenotype")
			var/client/admin_client = usr?.client
			if(!admin_client)
				return TRUE
			if(!admin_client.rw_prefs)
				admin_client.rw_prefs = new /datum/rimworld_preferences(admin_client)
			if(!save_from_preferences(admin_client.rw_prefs, usr, params["name"]))
				to_chat(usr, span_warning("Could not save this xenotype. Check its name and try again."))
			return TRUE
	return FALSE


ADMIN_VERB(open_rw_xenotype_manager, R_ADMIN, "\[RW\] Xenotype Manager", "Manage shared Rimworld xenotype presets.", ADMIN_CATEGORY_EVENTS)
	SSxenogenes.ui_interact(user.mob)


/datum/rw_xenotype_browser
	var/client/owner
	var/admin_manager = FALSE

/datum/rw_xenotype_browser/New(client/new_owner, new_admin_manager = FALSE)
	owner = new_owner
	admin_manager = new_admin_manager

/datum/rw_xenotype_browser/Destroy(force)
	owner = null
	return ..()

/datum/rw_xenotype_browser/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RimworldXenotypeBrowser", admin_manager ? "Xenotype Manager" : "Xenotype Browser")
		ui.open()

/datum/rw_xenotype_browser/ui_state(mob/user)
	return GLOB.always_state

/datum/rw_xenotype_browser/ui_close(mob/user)
	qdel(src)

/datum/rw_xenotype_browser/ui_data(mob/user)
	var/list/data = list(
		"xenotypes" = SSxenogenes.compile_xenotypes(),
		"xenogeneDefs" = SSxenogenes.compile_gene_catalog(),
		"pinnedGenes" = SSxenogenes.pinned_genes,
		"canManage" = check_rights_for(user?.client, R_ADMIN),
		"isAdminManager" = admin_manager,
	)
	if(ishuman(user))
		var/mob/living/carbon/human/human_user = user
		data["currentXenotype"] = human_user.dna?.rw_xenotype?.compile_ui_data()
	if(owner?.rw_prefs)
		var/list/current_gene_ids = list()
		for(var/gene_id in owner.rw_prefs.xenogenes)
			current_gene_ids += gene_id
		data["currentGeneIds"] = current_gene_ids
		data["currentXenotypeName"] = owner.rw_prefs.xenotype_name
	return data

/datum/rw_xenotype_browser/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(!owner || owner != usr?.client)
		return TRUE
	switch(action)
		if("apply_xenotype")
			if(!owner.rw_prefs)
				owner.rw_prefs = new /datum/rimworld_preferences(owner)
			if(owner.rw_prefs && SSxenogenes.apply_to_preferences(owner.rw_prefs, params["id"]))
				var/datum/tgui/editor_ui = SStgui.get_open_ui(owner.mob, owner.rw_prefs)
				owner.rw_prefs.update_static_data(owner.mob, editor_ui, TRUE)
				return TRUE
			to_chat(usr, span_warning("This xenotype could not be applied; it may exceed your character point budget."))
			return TRUE
		if("toggle_gene_pin", "toggle_xenotype_favorite", "toggle_xenotype_pin", "delete_xenotype", "save_xenotype")
			if(!check_rights_for(owner, R_ADMIN))
				return TRUE
			switch(action)
				if("toggle_gene_pin")
					SSxenogenes.toggle_gene_pin(params["id"])
				if("toggle_xenotype_favorite")
					SSxenogenes.toggle_xenotype_favorite(params["id"])
				if("toggle_xenotype_pin")
					SSxenogenes.toggle_xenotype_pin(params["id"])
				if("delete_xenotype")
					SSxenogenes.delete_xenotype(params["id"])
				if("save_xenotype")
					if(!owner.rw_prefs)
						owner.rw_prefs = new /datum/rimworld_preferences(owner)
					if(!SSxenogenes.save_from_preferences(owner.rw_prefs, usr, params["name"], params["description"], params["iconGene"]))
						to_chat(usr, span_warning("Could not save this xenotype. Check its name and try again."))
			return TRUE
	return FALSE

