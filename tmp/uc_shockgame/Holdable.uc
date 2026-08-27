class Holdable extends Actor
	native
	config(Weapons)
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced);

var private travel Hands Hands;
var travel ShockPawn Holder;
var config travel array<name> IdlingHandsAnim;
var config travel array<float> IdlingHandsAnimWeight;
var private config travel name IdlingAnim;
var private config travel name AdditiveHandBobAnim;
var private config travel name EquippingHandsAnim;
var private config travel name EquippingAnim;
var private config travel name UnEquippingHandsAnim;
var private config travel name UnEquippingAnim;
var private config travel bool bHideWhileUnequipped;
var private config travel bool bHideWhileEquipped;
var private config travel name AttachBone;
var private int EquippingAnimationHandle;
var private int UnEquippingAnimationHandle;
var private int EquippingAnimationHandsHandle;
var private int UnEquippingAnimationHandsHandle;
var private float PlaybackRate;

function float GetIdlingHandsAnimTweenTime()
{
	return 0.0000000;
	return;
}

function name GetIdlingHandsAnim()
{
	local int i;
	local float TotalWeight, SelectedWeight;

	AssertWithDescription(__NFUN_154__(IdlingHandsAnim.Length, IdlingHandsAnimWeight.Length), __NFUN_112__(__NFUN_112__("The number of IdlingHandsAnim and IdlingHandsAnimWeight for weapon '", string(self.Name)), "' must be the same in Weapons.ini"));
	i = 0;
	// End:0xEC
	if(__NFUN_150__(i, IdlingHandsAnimWeight.Length))
	{
		__NFUN_184__(TotalWeight, IdlingHandsAnimWeight[i]);
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0xA8;
		SelectedWeight = __NFUN_171__(__NFUN_195__(), TotalWeight);
		i = 0;
		// End:0x179
		if(__NFUN_150__(i, IdlingHandsAnim.Length))
		{
			__NFUN_185__(SelectedWeight, IdlingHandsAnimWeight[i]);
		}
		// End:0x16B
		if(__NFUN_178__(SelectedWeight, 0.0000000))
		{
			return IdlingHandsAnim[i];
			__NFUN_163__(i);
			// [Loop Continue]
			goto J0x10E;
			AssertWithDescription(false, __NFUN_112__(__NFUN_112__(__NFUN_112__("SelectedWeight = ", string(SelectedWeight)), ", TotalWeight = "), string(TotalWeight)));
			return IdlingHandsAnim[__NFUN_167__(IdlingHandsAnim.Length)];
		}
		return;
		@NULL
		Item
		Item
	}
	@NULL
}

function name GetIdlingAnim()
{
	return IdlingAnim;
	return;
	@NULL
}

function name GetAdditiveHandBobAnim()
{
	return AdditiveHandBobAnim;
	return;
	@NULL
}

function name GetEquippingHandsAnim()
{
	return EquippingHandsAnim;
	return;
	@NULL
}

function name GetEquippingAnim()
{
	return EquippingAnim;
	return;
	@NULL
}

function name GetUnEquippingHandsAnim()
{
	return UnEquippingHandsAnim;
	return;
	@NULL
}

function name GetUnEquippingAnim()
{
	return UnEquippingAnim;
	return;
	@NULL
}

function int GetDesiredAnimationCapabilities()
{
	// End:0x1D
	if(__NFUN_119__(Base, none))
	{
		return super.GetDesiredAnimationCapabilities();
		goto J0x2F;
		return __NFUN_158__(super.GetDesiredAnimationCapabilities(), 256);
	}
	return;
	@NULL
	Item
	J0x2F:

	stop;
	default.@NULL
}

function SetHolder(ShockPawn inHolder)
{
	assert(__NFUN_119__(inHolder, none));
	Holder = inHolder;
	return;
	@NULL
	Item
	Item
}

function SetHands(Hands inHands)
{
	assert(__NFUN_119__(inHands, none));
	Hands = inHands;
	return;
	@NULL
	Item
	Item
}

function Equip(ShockPawn inHolder, optional bool bInstant)
{
	log('Weapons', 3, " Equip called in Holdable ");
	Holder = inHolder;
	OnEquippingStarted();
	OnEquippingFinished();
	return;
	@NULL
	Item
}

function UnEquip(optional bool bInstant)
{
	OnUnEquippingStarted();
	OnUnEquippingFinished();
	return;
}

function OnEquippingStarted()
{
	log('Hands', 4, __NFUN_112__(string(self), " called OnEquippingStarted "));
	UnHideHoldable();
	// End:0x63
	if(__NFUN_119__(Hands, none))
	{
		Hands.OnEquippingStarted(self);
		Holder.OnEquippingStarted(self);
	}
	return;
	@NULL
	Item
	Item
}

function OnEquippingFinished()
{
	log('Hands', 4, __NFUN_112__(string(self), " called OnEquippingFinished "));
	Holder.OnEquippingFinished(self);
	return;
	@NULL
}

function OnEquippingInterrupted()
{
	log('Hands', 4, __NFUN_112__(string(self), " called OnEquippingInterrupted "));
	HideHoldable();
	return;
}

function OnUnEquippingStarted()
{
	log('Hands', 4, __NFUN_112__(string(self), " called OnUnEquippingStarted "));
	Holder.OnUnEquippingStarted(self);
	return;
	@NULL
}

function OnUnEquippingFinished()
{
	log('Hands', 4, __NFUN_112__(string(self), " called OnUnEquippingFinished "));
	HideHoldable();
	// End:0x66
	if(__NFUN_119__(Hands, none))
	{
		Hands.OnUnEquippingFinished(self);
		Holder.OnUnEquippingFinished(self);
	}
	return;
	@NULL
	Item
	Item
}

function OnUnEquippingInterrupted()
{
	log('Hands', 4, __NFUN_112__(string(self), " called OnUnEquippingInterrupted "));
	return;
}

function UnHideHoldable()
{
	// End:0x1A
	if(__NFUN_129__(bHideWhileEquipped))
	{
		SetHidden(false);
		// End:0x4C
		if(Holder.__NFUN_303__('ShockPlayer'))
		{
		}
		DrawPriority = 1;
		UpdateRenderRevision();
		TriggerEffectEvent('UnHidden');
		return;
	}
	@NULL
	Item
	Item
	@NULL
}

function HideHoldable()
{
	// End:0x18
	if(bHideWhileUnequipped)
	{
		SetHidden(true);
		DrawPriority = 0;
	}
	UpdateRenderRevision();
	UnTriggerEffectEvent('UnHidden');
	return;
	@NULL
	Item
	Item
	@NULL
}

event OnAnimationEnded(int AnimationInstanceHandle)
{
	return;
}

function bool IsAvailable()
{
	return true;
	return;
}

function name GetAttachBone(ShockPawn inHolder)
{
	return AttachBone;
	return;
	@NULL
}

defaultproperties
{
	bHideWhileUnequipped=true
	AttachBone="R_Grip"
	bHidden=true
	bAcceptsProjectors=true
	bInGameRenderable=true
}