class AnimNotify_SetOrUnsetInputContext extends AnimNotify_Scripted
	native
	editinlinenew
	collapsecategories
	hidecategories(Object);

var name InputContext;
var bool Unset;

function Notify(Actor Owner, int AnimationHandle, float Time)
{
	// End:0x6B
	if(Unset)
	{
		ShockPlayerController(Owner.Level.GetLocalPlayerController()).ConsoleCommand(__NFUN_112__("POPINPUTCONTEXT ", string(InputContext)));
		goto J0xC7;
		ShockPlayerController(Owner.Level.GetLocalPlayerController()).ConsoleCommand(__NFUN_112__("PUSHINPUTCONTEXT ", string(InputContext)));
	}
	return;
	@NULL
	Item
	stop;
	default.@NULL
}
