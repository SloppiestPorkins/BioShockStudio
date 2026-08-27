class AnimNotify_ChangeInputContext extends AnimNotify_Scripted
	editinlinenew
	collapsecategories
	hidecategories(Object);

var name InputContext;

function Notify(Actor Owner, int AnimationHandle, float Time)
{
	AssertWithDescription(false, "AnimNotify_ChangeInputContext has been deprecated and should be replaced with AnimNotify_PushOrPopInputContext");
	ShockPlayerController(Owner.Level.GetLocalPlayerController()).ConsoleCommand(__NFUN_112__("SETDEFAULTINPUTCONTEXTOVERRIDE ", string(InputContext)));
	return;
	@NULL
	Item
	stop;
	default.@NULL
}
