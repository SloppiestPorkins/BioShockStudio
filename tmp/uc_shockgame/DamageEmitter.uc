class DamageEmitter extends Emitter implements ICanPropagateFire
	native
	config(Weapons)
	hidecategories(DrawScale3D);

var export editinline SimpleDamageData SimpleDamageData;
var bool ShouldDestroyWhenHittingFireExtinguisher;
var edfindable array<edfindable Actor> AssociatedActor;
var private IProvideDamageData EmitterData;
var private transient DamageFactory DamageFactory;
var private int InfernoID;
var private bool InitiatedFromWeapon;

function PostBeginPlay()
{
	// End:0x22
	if(__NFUN_119__(SimpleDamageData, none))
	{
		EmitterData = SimpleDamageData;
		super(Actor).PostBeginPlay();
		Damager = Level.GetLocalPlayerController().Pawn;
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

// Export UDamageEmitter::execGetInfernoID(FFrame&, void* const)
native final function int GetInfernoID();

function SetInfernoID(int id)
{
	//native.id;	
	@NULL
}

function Actor GetFireInstigator()
{
	return Damager;
	return;
	@NULL
}

function BaseChange()
{
	super(Actor).BaseChange();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xC7
	/*@Error*/
	Damager = Base;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xC7
	/*@Error*/
	Damager = ICanPropagateFire(Damager).GetFireInstigator();
	return;
	@NULL
	Item
	Item
	@NULL
}

function Destroyed()
{
	local int i;

	super(Actor).Destroyed();
	i = __NFUN_147__(AssociatedActor.Length, 1);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xDD
	/*@Error*/
	AssociatedActor[i].SetLightType(0);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xBB
	/*@Error*/
	AssociatedActor[i].__NFUN_279__();
	AssociatedActor.Remove(i, 1);
	__NFUN_164__(i);
	// [Loop Continue]
	goto J0x21;
	EmitterData = none;
	DestroyManagedObjects();
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

// Export UDamageEmitter::execDestroyManagedObjects(FFrame&, void* const)
native function DestroyManagedObjects();
