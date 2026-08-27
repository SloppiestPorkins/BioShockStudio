interface ICanBeHacked extends ICanBeFocused implements ICanBeFocused
	native
	parseconfig;

function bool IsHacked()
{
	return;
}

function bool CanBeHackedNow(ShockPlayer Player)
{
	return;
}

function HackInfo GetHackInfo()
{
	return;
}

function OnHackAttempted(ShockPlayer Player)
{
	return;
}

function HackInfo OnHackSucceeded(ShockPlayer Player, string HackResult)
{
	return;
}

function HackInfo OnHackFailed(ShockPlayer Player, string HackResult)
{
	return;
}

function string GetHUDMessageForHackFocusAttained(ICanBeHacked HackableObject)
{
	return HackableObject.GetHackVerbText();
	return;
	@NULL
}

function string GetHackVerbText()
{
	return;
}

function string GetHackButtonText()
{
	// End:0x4A
	if(__NFUN_132__(__NFUN_132__(__NFUN_154__(int(GetPlatform()), int(1)), __NFUN_154__(int(GetPlatform()), int(3))), __NFUN_154__(int(GetPlatform()), int(4))))
	{
		return "Y";
		goto J0x50;
		return "-H-";
		return;
		@NULL
	}
	Freebie
	J0x50:

	Class'ShockGame.Item'
}
