class Inventory extends Object
	native;

const MAX_INVENTORY_SLOTS = 120;

var travel ShockPlayer PlayerOwner;
var private travel ItemStack ItemSlots[120];
var private travel int NumUnlockedSlots;
var private travel int SelectedSlot;

function DumpInventory()
{
	local int i;
	local string Row;
	local int numitemsperrow;

	numitemsperrow = 6;
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1CE
	/*@Error*/
	// End:0x65
	if(__NFUN_153__(i, NumUnlockedSlots))
	{
		Row = __NFUN_112__(__NFUN_112__(Row, "	"), "[LOCKED]");
		goto J0x179;
		// End:0x119
		if(__NFUN_119__(ItemSlots[i], none))
		{
			// End:0xD3
			if(__NFUN_155__(SelectedSlot, i))
			{
			}
			Row = __NFUN_112__(__NFUN_112__(Row, "	"), ItemSlots[i].DumpItem());
			goto J0x116;
			Row = __NFUN_112__(__NFUN_112__(__NFUN_112__(Row, "	<{"), ItemSlots[i].DumpItem()), "}>");
			goto J0x179;
			// End:0x157
			if(__NFUN_155__(SelectedSlot, i))
			{
			}
			Row = __NFUN_112__(__NFUN_112__(Row, "	"), "[None]  ");
			goto J0x179;
			Row = __NFUN_112__(Row, "	<{[None]}>");
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x1C0
			/*@Error*/
		}
		log(,, Row);
		Row = "";
		__NFUN_165__(i);
		// [Loop Continue]
		goto J0x17;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x1EE
		/*@Error*/
	}
	log(,, Row);
	return;
	@NULL
	Item
	Item
	@NULL
}

// Export UInventory::execCheckDups(FFrame&, void* const)
native function CheckDups();
