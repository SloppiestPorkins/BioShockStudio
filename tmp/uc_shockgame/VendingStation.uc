class VendingStation extends DispenserMachine
	native
	config(Machines)
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced);

var(Machine) private name VendingTableName;
var(Machine) private bool IsBandito;
var private VendingLootTable VendingTable;
var private config localized string VendingExpertMessage;
var private config localized string VendingExpertTwoMessage;
var private config localized string DiscountedMessage;

function PreBeginPlay()
{
	super(ShockMachine).PreBeginPlay();
	VendingTable = Class'ShockGame.VendingLootTable'.static.Allocate(self,, string(VendingTableName)).;
	Construct_Void();
	assert(__NFUN_119__(VendingTable, none));
	return;
	@NULL
	Item
	Item
	@NULL
}

function PostBeginPlay()
{
	super(ShockMachine).PostBeginPlay();
	TriggerEffectEvent('AliveNotBeingUsed');
	return;
	@NULL
}

function Destroyed()
{
	UnTriggerEffectEvent('AliveNotBeingUsed');
	super(ShockMachine).Destroyed();
	return;
	@NULL
}

// Export UVendingStation::execBeginVending(FFrame&, void* const)
native function BeginVending();

function AllVendingTableNames(LevelInfo Level, out array<name> S)
{
	local int i;
	local TableList TableList;

	TableList = Class'ShockGame.TableList'.static.Allocate(self).;
	Construct_Void();
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xA3
	/*@Error*/
	S[i] = TableList.VendingTableName[i];
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x3C;
	TableList.__NFUN_200__();
	return;
	@NULL
	Item
	Item
	@NULL
}

function HackInfo OnHackSucceeded(ShockPlayer Player, string HackResult)
{
	super(ShockMachine).OnHackSucceeded(Player, HackResult);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x88
	/*@Error*/
	ShockPlayerController(CurrentPlayer.Controller).SetPause(true);
	BeginVending();
	return GetHackInfo();
	return;
	@NULL
	Item
	Item
	@NULL
}

state Interacting
{	stop;
}

defaultproperties
{
	VendingExpertMessage="Vending Expert: Prices reduced by 8%"
	VendingExpertTwoMessage="Vending Expert v2: Prices reduced by 12%"
	DiscountedMessage="(HACK ONLY) "
	PickupSpawnOffset=(X=28.0000000,Y=12.0000000,Z=74.0000000)
	HackInfoName="VendingStationDefault"
	HackingSuccessFeedbackText="RESULT OF SUCCESSFUL HACK:  More items available, and all prices reduced."
	FriendlyName="Vending Station"
	DrawType=8
	StaticMesh=StaticMesh'ShockGame.MA_Vending.VendingWide'
	HavokDataClass=Class'ShockGame.ShockDesignerClasses.VendingStationRigidBody'
}