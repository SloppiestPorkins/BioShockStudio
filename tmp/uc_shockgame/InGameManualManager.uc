class InGameManualManager extends DeletableObject
	native
	config(Manual);

var config array<name> ManualTopicName;
var travel ShockPlayer PlayerOwner;
var travel array<ManualTopic> Topics;
var private const noexport TMap_Padding TopicMap;

function DumpManualTopics(optional bool bShowHidden, optional bool bShowCompleted)
{
	local int i;

	log(,, "********************************************************");
	log(,, "*** Dumping Manual Topics ***");
	log(,, "");
	i = 0;
	// End:0xFA
	if(__NFUN_150__(i, Topics.Length))
	{
		Topics[i].DumpTopic(PlayerOwner.Level.TimeSeconds, 0, bShowHidden, bShowCompleted);
		__NFUN_165__(i);
		// [Loop Continue]
		goto J0x7B;
		log(,, "********************************************************");
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function bool UnhideManualTopic(name TopicName)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xAA
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x9C
	/*@Error*/
	Topics[i].bHidden = false;
	return true;
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x0B;
	return false;
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function HideManualTopic(name TopicName)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x82
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x74
	/*@Error*/
	Topics[i].bHidden = true;
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	Item
	default.Item
	@NULL
}

function ShowAllManualTopics()
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x78
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x6A
	/*@Error*/
	Topics[i].bHidden = false;
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	Item
	default.Item
	@NULL
}

defaultproperties
{
	ManualTopicName[0]="PlasmidPack_1"
	ManualTopicName[1]="DLC_1"
	ManualTopicName[2]="Firing"
	ManualTopicName[3]="UsingAbilities"
	ManualTopicName[4]="ChangingWeapons"
	ManualTopicName[5]="ChangingAbilities"
	ManualTopicName[6]="DamageTypes"
	ManualTopicName[7]="Research"
	ManualTopicName[8]="ActivePlasmidOverview"
	ManualTopicName[9]="PhysicalPlasmidOverview"
	ManualTopicName[10]="EngineeringPlasmidOverview"
	ManualTopicName[11]="WeaponsPlasmidOverview"
	ManualTopicName[12]="Machines"
	ManualTopicName[13]="ADAM"
	ManualTopicName[14]="AmmoVending"
	ManualTopicName[15]="AutoHackDevice"
	ManualTopicName[16]="Container"
	ManualTopicName[17]="Log"
	ManualTopicName[18]="EveHypo"
	ManualTopicName[19]="Gin"
	ManualTopicName[20]="MedHypo"
	ManualTopicName[21]="GrowthStation"
	ManualTopicName[22]="PlasmidEquip"
	ManualTopicName[23]="Health"
	ManualTopicName[24]="CraftingMachine"
	ManualTopicName[25]="Money"
	ManualTopicName[26]="Radio"
	ManualTopicName[27]="Present"
	ManualTopicName[28]="safe"
	ManualTopicName[29]="Security"
	ManualTopicName[30]="Vending"
	ManualTopicName[31]="Resurrection"
	ManualTopicName[32]="WeaponUpgrade"
	ManualTopicName[33]="Absinthe"
	ManualTopicName[34]="bandages"
	ManualTopicName[35]="Beer"
	ManualTopicName[36]="brandy"
	ManualTopicName[37]="chips"
	ManualTopicName[38]="cigarettes"
	ManualTopicName[39]="Coffee"
	ManualTopicName[40]="Twinkie"
	ManualTopicName[41]="Powerbar"
	ManualTopicName[42]="scotch"
	ManualTopicName[43]="Vodka"
	ManualTopicName[44]="Whiskey"
	ManualTopicName[45]="Wine"
	ManualTopicName[46]="Protector"
	ManualTopicName[47]="Assassin"
	ManualTopicName[48]="RangedAggressor"
	ManualTopicName[49]="Gatherer"
	ManualTopicName[50]="Grenadier"
	ManualTopicName[51]="CeilingCrawler"
	ManualTopicName[52]="MeleeThug"
	ManualTopicName[53]="Wrench"
	ManualTopicName[54]="Pistol"
	ManualTopicName[55]="MachineGun"
	ManualTopicName[56]="Shotgun"
	ManualTopicName[57]="GrenadeLauncher"
	ManualTopicName[58]="ChemicalThrower"
	ManualTopicName[59]="Crossbow"
	ManualTopicName[60]="ResearchCamera"
	ManualTopicName[61]="StandardBullet"
	ManualTopicName[62]="ArmorPiercingBullet"
	ManualTopicName[63]="AntiPersonnelBullet"
	ManualTopicName[64]="MachineGunBullet"
	ManualTopicName[65]="MachineGunFrozenBullet"
	ManualTopicName[66]="MachineGunArmorPiercingBullet"
	ManualTopicName[67]="StandardBuckshot"
	ManualTopicName[68]="IonicBuckshot"
	ManualTopicName[69]="HighExplosiveBuckshot"
	ManualTopicName[70]="FragGrenade"
	ManualTopicName[71]="ProximityGrenade"
	ManualTopicName[72]="RPG"
	ManualTopicName[73]="FlameChemical"
	ManualTopicName[74]="FreezeChemical"
	ManualTopicName[75]="IonicChemical"
	ManualTopicName[76]="StandardBolt"
	ManualTopicName[77]="SearingBolt"
	ManualTopicName[78]="TrapBolt"
	ManualTopicName[79]="Film"
	ManualTopicName[80]="SecurityOverview"
	ManualTopicName[81]="SecurityCamera"
	ManualTopicName[82]="SecurityBot"
	ManualTopicName[83]="Turret"
	ManualTopicName[84]="HackingSecurity"
}