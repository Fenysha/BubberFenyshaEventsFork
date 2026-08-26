/**
 * # Runechat Cyrillic font
 *
 * Runechat renders through the `.maptext` class, which skin.dmf defines as
 * 6pt Grand9K Pixel. That font contains **no Cyrillic glyphs at all** - I
 * checked the cmap table of every font in interface/fonts/ and all six are
 * 0/64 on basic Cyrillic. Whispers are worse: `.italics` and `.small` map to
 * Spess Font, which has 97 glyphs total.
 *
 * So every Russian character in a bubble is a missing glyph. BYOND
 * substitutes something from the system, which is a different typeface with
 * different metrics - and since MeasureText() sizes the box against the
 * declared font, the box can come out wrong and clip the text.
 *
 * The fix is to render any body containing non-ASCII in a font that covers
 * both scripts, chosen per line so an all-English station looks exactly as it
 * did before, and so a mixed line does not switch typeface mid-sentence.
 *
 * ## Changing the font
 *
 * Two things have to agree:
 *  - RUNECHAT_CYRILLIC_FONT must be the font's *internal family name*, not
 *    its filename. Ubuntu-Medium.ttf reports "Ubuntu Medium", for instance.
 *  - /datum/font/runechat_cyrillic must point at the file, so the resource
 *    literal packs it into the .rsc and it reaches clients.
 *
 * Setting RUNECHAT_CYRILLIC_FONT to "" disables the swap entirely and
 * restores the previous (broken for Cyrillic) behaviour.
 */

/**
 * Internal family name of the font used for non-ASCII runechat bodies.
 *
 * Pix Cyrillic (https://github.com/lotva/pix-cyrillic) is a fork of Pixellari
 * with Russian, Ukrainian and Belarusian coverage - verified here at 64/64 on
 * basic Cyrillic plus Ё/ё. Pixellari is already one of the stock maptext
 * fonts, so this matches the existing pixel look rather than fighting it.
 *
 * bossbar.dm has asked for "Pix Cyrillic" by name since long before this
 * module existed, without the file ever being committed - so it was silently
 * falling back to a system face for everyone who did not happen to have the
 * font installed. Vendoring it here fixes that too.
 */
#define RUNECHAT_CYRILLIC_FONT "Pix Cyrillic"

/**
 * Point size for that font.
 *
 * Chosen to match Grand9K's rendered height rather than Pix Cyrillic's native
 * grid. Measured metrics:
 *
 *   Grand9K      upem 2048, ascender 2560 = 1.25 em  -> 7.5pt tall at 6pt
 *   Pix Cyrillic upem 1024, ascender  768 = 0.75 em  -> 7.5pt tall at 10pt
 *
 * So 10pt is the size at which Cyrillic sits level with the English around
 * it. The tradeoff is that Pixellari-family faces are a 16px design (native
 * 12pt), so 10pt is a non-integer downscale and will be slightly softer than
 * a pixel-aligned size.
 *
 * The only pixel-aligned alternatives are 12pt (native, ~20% taller than
 * Grand9K) and 6pt (exact 2:1 downscale, smaller than Grand9K and half the
 * detail). If 10pt looks too soft, LanaPixel is designed small rather than
 * downscaled and would be the better swap.
 */
#define RUNECHAT_CYRILLIC_FONT_SIZE "8pt"

/// Registers the font as a resource so it ships to clients, matching how
/// interface/fonts/*.dm declare the stock maptext fonts.
/datum/font/runechat_cyrillic
	name = RUNECHAT_CYRILLIC_FONT
	font_family = 'fenysha_events/interface/fonts/PixCyrillic.ttf'

/**
 * Wraps text in the Cyrillic-capable font if it needs it.
 *
 * Returns the text untouched when it is pure ASCII, so English speech keeps
 * the stock pixel font and nothing about the station's look changes.
 *
 * Note this triggers on any multi-byte character, not strictly Cyrillic -
 * the singing notes that say() adds are multi-byte too. Those are not in
 * Grand9K either, so they were already falling back to a substitute; sending
 * them to a font that actually has them is no worse.
 */
/proc/runechat_apply_script_font(text)
	if(!length(RUNECHAT_CYRILLIC_FONT) || !text_has_non_ascii(text))
		return text
	return "<span style='font-family: \"[RUNECHAT_CYRILLIC_FONT]\"; font-size: [RUNECHAT_CYRILLIC_FONT_SIZE]'>[text]</span>"
