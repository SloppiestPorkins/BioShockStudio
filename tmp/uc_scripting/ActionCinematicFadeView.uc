class ActionCinematicFadeView extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var /*0x00000000-0x00100000*/ travel Color fadeStart;
var /*0x00000000-0x00100000*/ travel Color fadeEnd;
var /*0x00000000-0x00100000*/ travel float fadeAlphaStart;
var /*0x00000000-0x00100000*/ travel float fadeAlphaEnd;
var travel float Duration;
var travel float holdDuration;
var travel bool bRestoreFadeControl;
var travel float StartTime;

function Variable latentExecute()
{
	local PlayerController PC;
	local Vector fadeDiff;
	local float Alpha;

	resolveParameters();
	PC = parentScript.Level.GetLocalPlayerController();
	PC.bManualFogUpdate = true;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x468
	/*@Error*/
	fadeDiff.X = float(__NFUN_147__(int(fadeEnd.R), int(fadeStart.R)));
	fadeDiff.Y = float(__NFUN_147__(int(fadeEnd.G), int(fadeStart.G)));
	fadeDiff.Z = float(__NFUN_147__(int(fadeEnd.B), int(fadeStart.B)));
	StartTime = parentScript.Level.TimeSeconds;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x468
	/*@Error*/
	Alpha = __NFUN_172__(__NFUN_175__(parentScript.Level.TimeSeconds, StartTime), Duration);
	PC.FlashFog.X = __NFUN_172__(__NFUN_174__(float(fadeStart.R), __NFUN_171__(fadeDiff.X, Alpha)), float(255));
	J0x194:

	PC.FlashFog.Y = __NFUN_172__(__NFUN_174__(float(fadeStart.G), __NFUN_171__(fadeDiff.Y, Alpha)), float(255));
	PC.FlashFog.Z = __NFUN_172__(__NFUN_174__(float(fadeStart.B), __NFUN_171__(fadeDiff.Z, Alpha)), float(255));
	PC.FlashScale.X = __NFUN_175__(1.0000000, __NFUN_174__(fadeAlphaStart, __NFUN_171__(__NFUN_175__(fadeAlphaEnd, fadeAlphaStart), Alpha)));
	PC.FlashScale.Y = PC.FlashScale.X;
	PC.FlashScale.Z = PC.FlashScale.X;
	__NFUN_256__(0.0000000);
	// [Loop Continue]
	goto J0x194;
	PC.FlashFog.X = float(__NFUN_145__(int(fadeEnd.R), 255));
	PC.FlashFog.Y = float(__NFUN_145__(int(fadeEnd.G), 255));
	PC.FlashFog.Z = float(__NFUN_145__(int(fadeEnd.B), 255));
	PC.FlashScale.X = __NFUN_175__(1.0000000, fadeAlphaEnd);
	PC.FlashScale.Y = PC.FlashScale.X;
	PC.FlashScale.Z = PC.FlashScale.X;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x639
	/*@Error*/
	__NFUN_256__(holdDuration);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x6E6
	/*@Error*/
	PC.bManualFogUpdate = false;
	PC.FlashScale.X = 1.0000000;
	PC.FlashScale.Y = 1.0000000;
	PC.FlashScale.Z = 1.0000000;
	return none;
	return;
	@NULL
	MessageTriggerVolume
	Variable
	@NULL
}

function Variable execute()
{
	super.execute();
	return none;
	return;
	@NULL
}

function editorDisplayString(out string S)
{
	S = "Fade view";
	return;
	@NULL
}

defaultproperties
{
	fadeAlphaEnd=1.0000000
	Duration=2.0000000
	bRestoreFadeControl=true
	actionDisplayName="Fade View"
	actionHelp="Fades the view. Does not finish until the fade is completed."
	Category="Cinematic"
	bIsGameCritical=false
}