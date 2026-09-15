#define DOLLAR_NAME_AUTOPURAL(amount) "dollar[##amount == 1 ? "" : "s"]"

/obj/item/stack/dollar
	name = "Dollar"
	singular_name = "Dollar"
	icon = 'icons/obj/economy.dmi'
	icon_state = "spacecash20"
	worn_icon_state = "nothing"
	amount = 1
	max_amount = INFINITY
	throwforce = 0
	throw_speed = 2
	throw_range = 2
	w_class = WEIGHT_CLASS_TINY
	full_w_class = WEIGHT_CLASS_TINY
	resistance_flags = FLAMMABLE
	var/value = 1

/obj/item/stack/dollar/Initialize(mapload, new_amount, merge = TRUE, list/mat_override=null, mat_amt=1)
	. = ..()
	add_traits(list(TRAIT_FISHING_BAIT, TRAIT_BAIT_ALLOW_FISHING_DUD), INNATE_TRAIT)
	update_desc()

/obj/item/stack/dollar/grind_results()
	return list(/datum/reagent/cellulose = 10)

/obj/item/stack/dollar/update_desc()
	. = ..()
	var/total_worth = get_item_credit_value()
	desc = "It's worth [total_worth] [DOLLAR_NAME_AUTOPURAL(total_worth)] in total."

/obj/item/stack/dollar/get_item_credit_value()
	return (amount*value)

/obj/item/stack/dollar/merge(obj/item/stack/target_stack, limit)
	. = ..()
	update_desc()

/obj/item/stack/dollar/use(used, transfer = FALSE, check = TRUE)
	. = ..()
	update_desc()

/obj/item/stack/dollar/update_icon_state()
	. = ..()
	switch(amount)
		if(1)
			icon_state = initial(icon_state)
		if(2 to 9)
			icon_state = "[initial(icon_state)]_2"
		if(10 to 24)
			icon_state = "[initial(icon_state)]_3"
		if(25 to INFINITY)
			icon_state = "[initial(icon_state)]_4"



#define TRADER_OFFER_SELL 1
#define TRADER_OFFER_BUY 2

#define TRADER_MIN_DISTANCE 3

/*
 * NPC_TRADE(
 *     ITEM,
 *     ITEM_AMOUNT,
 *     PRICE,
 *     STOCK,
 *     DIRECTION,
 *     DESCRIPTION
 * )
 *
 * ITEM         - Item type
 * ITEM_AMOUNT  - Amount of items per trade
 * PRICE        - Price in dollars
 * STOCK        - Amount of stocks, INFINITY for unlimited trades.
 * DIRECTION    - TRADER_OFFER_SELL / TRADER_OFFER_BUY.
 * DESCRIPTION  - Decription of trade.
 */
/proc/NPC_TRADE(
	item_type,
	item_amount = 1,
	price = 1,
	stock = INFINITY,
	direction = TRADER_OFFER_SELL,
	description = null,
)
	var/obj/item/I = new item_type(null)

	var/item_name = I.name
	var/item_desc = description || I.desc

	qdel(I)

	return new /datum/trader_offer(
		item_type,
		item_name,
		item_desc,
		price,
		item_amount,
		stock,
		direction,
	)


/datum/trader_offer
	var/static/next_id = 0

	var/id
	var/display_name
	var/description

	var/obj/item/item_type
	var/item_amount = 1

	var/price = 1
	var/stock = INFINITY

	var/direction = TRADER_OFFER_SELL


/datum/trader_offer/New(
	new_item_type,
	new_display_name,
	new_description,
	new_price,
	new_item_amount = 1,
	new_stock = INFINITY,
	new_direction = TRADER_OFFER_SELL,
)
	. = ..()

	id = ++next_id

	item_type = new_item_type
	display_name = new_display_name
	description = new_description

	price = new_price
	item_amount = new_item_amount
	stock = new_stock
	direction = new_direction

/mob/living/basic/npc/trader
	name = "Trader"
	desc = "A person willing to trade."
	ghost_controlable = FALSE

	/// The player currently trading with this NPC.
	var/mob/trading_with

	/// All available trades.
	var/list/datum/trader_offer/trades = list()

	/// Dialogue available to this trader.
	var/list/trader_dialogue = list()
	var/current_dialogue = ""

	/// Chance for a dialogue line to also be spoken aloud.
	var/trader_say_chance = 35

	var/ui_theme = "default"
	var/trader_tier

/mob/living/basic/npc/trader/Initialize(mapload)
	trades = list()
	InitializeTrade()
	return ..()


/*
 * Override this in child trader types.
 *
 * Example:
 *
 * /mob/living/basic/npc/trader/fisherman/InitializeTrade()
 *     trades += list(
 *         NPC_TRADE(
 *             "fish",
 *             /obj/item/food/fish,
 *             1,
 *             25,
 *             INFINITY,
 *             TRADER_OFFER_SELL,
 *             "Freshly caught fish.",
 *         ),
 *     )
 */

/mob/living/basic/npc/trader/proc/InitializeTrade()
	return


/mob/living/basic/npc/trader/Destroy()
	trading_with = null

	return ..()


/mob/living/basic/npc/trader/examine(mob/user)
	. = ..()

	if(!user)
		return

	INVOKE_ASYNC(src, PROC_REF(open_trader_menu), user)


/mob/living/basic/npc/trader/proc/open_trader_menu(mob/user)
	if(!can_interact_with_trader(user))
		return

	var/list/options = list(
		"examine" = image(
			icon = 'icons/hud/radial.dmi',
			icon_state = "radial_examine",
		),
		"trade" = image(
			icon = 'icons/hud/radial.dmi',
			icon_state = "radial_talk",
		),
	)

	var/choice = show_radial_menu(
		user,
		src,
		options,
		require_near = FALSE,
	)

	if(QDELETED(src) || QDELETED(user))
		return

	if(!can_interact_with_trader(user))
		return

	switch(choice)
		if("examine")
			user.examinate(src)

		if("trade")
			start_trade(user)


/mob/living/basic/npc/trader/proc/can_interact_with_trader(mob/user)
	if(!user)
		return FALSE

	if(QDELETED(user))
		return FALSE

	if(stat == DEAD)
		return FALSE

	if(user.incapacitated)
		return FALSE

	if(!can_see(user, src, TRADER_MIN_DISTANCE))
		return FALSE

	return TRUE


/mob/living/basic/npc/trader/proc/start_trade(mob/user)
	if(!can_interact_with_trader(user) || trader_should_interrupt_trade(user))
		return FALSE

	if(trading_with && trading_with != user)
		to_chat(user, span_warning("[src] is currently busy trading with someone else."))
		return FALSE

	trading_with = user

	speak_trade_line()
	ui_interact(user)

	return TRUE


/mob/living/basic/npc/trader/proc/end_trade(mob/user)
	if(trading_with != user)
		return

	trading_with = null

	if(user?.client)
		SStgui.close_uis(user)


/mob/living/basic/npc/trader/proc/is_valid_trader_user(mob/user)
	if(trading_with != user)
		return FALSE

	if(!can_interact_with_trader(user))
		return FALSE

	return TRUE


/*
 *
 * - trader got a hostile target
 * - trader AI wants to flee
 * - trader entered combat
 * - special event started
 *
 * Return TRUE to immediately terminate the trade.
 */

/mob/living/basic/npc/trader/proc/trader_should_interrupt_trade(mob/user)
	if(!ai_controller || ai_controller.ai_status == AI_IDLE)
		return FALSE

	var/list/allowed_factions = ai_controller.blackboard[BB_NPC_TRAIDER_TRAID_FACTION]
	if((allowed_factions && length(allowed_factions)) && !faction_check(allowed_factions, user.get_faction()))
		return TRUE

	return FALSE


/mob/living/basic/npc/trader/proc/away_from_shop()
	if(!ai_controller || ai_controller.ai_status == AI_IDLE)
		return FALSE
	var/turf/shop = ai_controller.blackboard[BB_NPC_TRAIDER_SHOP]
	if(shop && get_dist(shop, get_turf(src)) > 3)
		return TRUE
	return FALSE

/*
 * Every Life() tick we verify the current customer.
 *
 * This means the UI can disappear immediately after:
 *
 * - walking too close
 * - walking too far
 * - losing line of sight
 * - becoming incapacitated
 * - NPC dying
 * - AI deciding to interrupt the trade
 */

/mob/living/basic/npc/trader/Life(seconds_per_tick, times_fired)
	. = ..()

	if(!trading_with)
		return .

	var/mob/user = trading_with
	if(user && away_from_shop())
		npc_say("Let me return to my shop first!")
		end_trade(user)
		return

	if(QDELETED(user) \
		|| !can_interact_with_trader(user) \
		|| trader_should_interrupt_trade(user) \
	)
		end_trade(user)


/*
 * Immediate interruption when the customer attacks the trader.
 */

/mob/living/basic/npc/trader/attack_hand(mob/living/carbon/human/user, list/modifiers)
	. = ..()
	if(trading_with)
		end_trade(trading_with)

/mob/living/basic/npc/trader/attacked_by(obj/item/attacking_item, mob/living/user, list/modifiers, list/attack_modifiers)
	. = ..()
	if(trading_with)
		end_trade(trading_with)

/mob/living/basic/npc/trader/bullet_act(obj/projectile/proj, def_zone, piercing_hit, blocked)
	. = ..()
	if(trading_with)
		end_trade(trading_with)


/*
 * Returns total dollar value currently present in the player's inventory.
 */

/mob/living/basic/npc/trader/proc/get_money(mob/user)
	var/total = 0

	for(var/obj/item/stack/dollar/D in user.get_all_contents())
		if(D.value <= 0)
			continue

		if(D.amount <= 0)
			continue

		total += D.get_item_credit_value()

	return total


/mob/living/basic/npc/trader/proc/can_afford(mob/user, required)
	if(required <= 0)
		return TRUE

	return get_money(user) >= required


/*
 * Finds the first matching item in the player's inventory.
 */

/mob/living/basic/npc/trader/proc/find_item_for_trade(
	mob/user,
	datum/trader_offer/offer,
)
	if(!offer?.item_type)
		return null

	for(var/obj/item/I in user.get_all_contents())
		if(istype(I, offer.item_type))
			return I

	return null


/*
 * Removes exact amount of money from the player's inventory.
 *
 * This uses the largest available denomination first.
 *
 */

/mob/living/basic/npc/trader/proc/spend_money(mob/user, required)
	if(required <= 0)
		return TRUE

	if(get_money(user) < required)
		return FALSE

	var/remaining = required

	var/list/obj/item/stack/dollar/money = list()

	for(var/obj/item/stack/dollar/D in user.get_all_contents())
		if(D.value <= 0)
			continue

		if(D.amount <= 0)
			continue

		money += D


	while(remaining > 0)
		var/obj/item/stack/dollar/best_stack
		var/best_value = 0

		for(var/obj/item/stack/dollar/D in money)
			if(D.value > best_value && D.value <= remaining)
				best_stack = D
				best_value = D.value

		if(!best_stack)
			return FALSE

		var/to_spend = min(
			best_stack.amount,
			floor(remaining / best_stack.value),
		)

		if(to_spend <= 0)
			return FALSE

		best_stack.use(to_spend)

		remaining -= to_spend * best_stack.value

		if(best_stack.amount <= 0)
			money -= best_stack

	return remaining <= 0


/*
 * Player buys an item from the trader.
 */

/mob/living/basic/npc/trader/proc/buy_from_trader(
	mob/user,
	datum/trader_offer/offer,
)
	if(!is_valid_trader_user(user))
		return FALSE

	if(!offer)
		return FALSE

	if(offer.direction != TRADER_OFFER_SELL)
		return FALSE

	if(offer.stock <= 0)
		to_chat(user, span_warning("[offer.display_name] is out of stock."))
		return FALSE

	if(!can_afford(user, offer.price))
		to_chat(user,span_warning("You do not have enough money."))

		return FALSE

	if(!spend_money(user, offer.price))
		to_chat(user,span_warning("You cannot pay that exact amount."))

		return FALSE

	for(var/i in 1 to offer.item_amount)
		var/obj/item/I = new offer.item_type(get_turf(src))

		if(!user.put_in_hands(I))
			I.forceMove(get_turf(user))

	if(offer.stock != INFINITY)
		offer.stock--

	to_chat(user, span_notice("You buy [offer.display_name] for [offer.price] dollars."))

	return TRUE


/*
 * Player sells an item to the trader.
 */

/mob/living/basic/npc/trader/proc/sell_to_trader(
	mob/user,
	datum/trader_offer/offer,
)
	if(!is_valid_trader_user(user))
		return FALSE

	if(!offer)
		return FALSE

	if(offer.direction != TRADER_OFFER_BUY)
		return FALSE

	if(offer.stock <= 0)
		to_chat(user, span_warning("[src] is no longer interested in buying this."))

		return FALSE

	var/obj/item/I = find_item_for_trade(user, offer)

	if(!I)
		to_chat(user,span_warning("You do not have [offer.display_name]."))
		return FALSE


	var/is_stack = isstack(I)
	if(is_stack)
		var/obj/item/stack/S = I
		if(S.amount < offer.item_amount)
			to_chat(user, span_warning( "You don't have enough [S] for trade."))
			return FALSE
		if(!S.use(offer.item_amount))
			to_chat(user, span_warning("You cannot hand that item over."))
			return FALSE
	else if(!user.dropItemToGround(I))
		to_chat(user, span_warning("You cannot hand that item over."))
		return FALSE
	else
		qdel(I)

	if(offer.stock != INFINITY)
		offer.stock--

	give_money(user, offer.price)

	to_chat(user, span_notice("You sell [offer.display_name] for [offer.price] dollars."))

	return TRUE


/*
 * Gives money to the player.
 *
 * Current implementation creates one dollar stack with the desired value.
 * Replace this later with denomination generation.
 */

/mob/living/basic/npc/trader/proc/give_money(mob/user, value)
	if(value <= 0)
		return

	var/obj/item/stack/dollar/D = new(get_turf(user))

	D.amount = value

	D.update_appearance()

	if(!user.put_in_hands(D))
		D.forceMove(get_turf(user))

	return D


/*
 * Trader dialogue.
 *
 * The returned line can also be used by the TGUI.
 */

/mob/living/basic/npc/trader/proc/speak_trade_line()
	if(!length(trader_dialogue))
		current_dialogue = ""
		SStgui.update_uis(src)
		return

	current_dialogue = pick(trader_dialogue)

	if(prob(trader_say_chance))
		say(current_dialogue)

	SStgui.update_uis(src)



/mob/living/basic/npc/trader/ui_interact(mob/user, datum/tgui/ui)
	if(!is_valid_trader_user(user))
		return

	ui = SStgui.try_update_ui(user, src, ui)

	if(!ui)
		ui = new(user, src, "NpcTrader", name)
		ui.open()


/mob/living/basic/npc/trader/ui_data(mob/user)
	var/list/data = list()

	data["npc_name"] = name
	data["money"] = get_money(user)

	data["ui_theme"] = ui_theme

	data["dialogue"] = current_dialogue

	data["trader_portrait"] = icon2base64(
		getFlatIcon(src, SOUTH, start = FALSE),
	)

	data["user_portrait"] = icon2base64(
		getFlatIcon(user, SOUTH, start = FALSE),
	)

	var/list/sell = list()
	var/list/buy = list()

	for(var/datum/trader_offer/offer as anything in trades)
		var/list/entry = list(
			"id" = offer.id,
			"name" = offer.display_name,
			"description" = offer.description,
			"price" = offer.price,
			"stock" = offer.stock,
			"item_amount" = offer.item_amount,
		)

		switch(offer.direction)
			if(TRADER_OFFER_SELL)
				sell += list(entry)

			if(TRADER_OFFER_BUY)
				buy += list(entry)

	data["sell"] = sell
	data["buy"] = buy

	return data


GLOBAL_DATUM_INIT(npc_trader_state, /datum/ui_state/remote, new)

/datum/ui_state/remote

/datum/ui_state/remote/can_use_topic(src_object, mob/user)
	if(!user)
		return UI_CLOSE

	if(!user.client)
		return UI_CLOSE

	if(user.stat)
		return UI_DISABLED

	return UI_INTERACTIVE


/mob/living/basic/npc/trader/ui_state(mob/user)
	return GLOB.npc_trader_state

/mob/living/basic/npc/trader/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()

	if(.)
		return

	var/mob/user = usr

	if(!is_valid_trader_user(user))
		end_trade(user)
		return FALSE

	switch(action)

		if("buy", "sell")
			var/offer_id = params["id"]

			var/datum/trader_offer/selected_offer

			for(var/datum/trader_offer/offer as anything in trades)
				if(offer.id == offer_id)
					selected_offer = offer
					break

			if(!selected_offer)
				return FALSE

			if(action == "buy")
				buy_from_trader(
					user,
					selected_offer,
				)
			else
				sell_to_trader(
					user,
					selected_offer,
				)

			return TRUE


		if("close")
			end_trade(user)
			return TRUE

	return FALSE


/mob/living/basic/npc/trader/ui_close(mob/user)
	. = ..()

	if(trading_with == user)
		end_trade(user)



