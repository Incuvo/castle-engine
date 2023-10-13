db = db.getSiblingDB('castle-temp');

balconomy = db.balconomy.findOne({version: "0.84"});
roomParams = balconomy.balance.roomParams;

//printjson(roomParams);

cur = db.users.find();
users = cur.toArray();

header = 'playerId, display_name, throne_level, gold, mana, max_gold, max_mana, percent_gold, percent_mana, cid';
print(header);

resolveRoomId = function(type) {
	switch(type) {
		case "THRONE":
			 return "throneHall";
		break;
		case "MANA_POTION_STORAGE":
			return "manaPotionStorage";
		break;
                case "TREASURY_VAULT":
                        return "treasuryVault";
                break;
		default:
			print("Room type: " + type + " not found");
			return null;
		break;
	}
}

getRoomParams = function(roomType, level) {
	var id = resolveRoomId(roomType);
	for (var i=0; i < balconomy.balance.roomParams.length; i++) {
		var room = balconomy.balance.roomParams[i];
		if (room.id == id) {
			for(var j=0; j < room.roomLevels.length; j++) {
				var roomLevel = room.roomLevels[j];
				if (roomLevel.level == level)
                        		return roomLevel
			}
		}
	}

        print('[ERROR] Couldnt find room params for roomType ' + roomType + ' level ' + level)

        return null
}

getThroneResourceLimit = function(throneLevel) {
	for (var i=0; i< balconomy.balance.throneResource.length; i++) {
		var limit = balconomy.balance.throneResource[i];
		if (limit.level == throneLevel)
                	return limit
	}

	return null;
}

for (i=0; i < users.length; i++) {
	user = users[i];
	roomsList = user.castle.roomsList;

	var udata = user.username + ',';
	udata += user.display_name + ',';
	var gold = user.castle.resourcesList[0].resourceType == 'GOLD' ? user.castle.resourcesList[0].quantity : user.castle.resourcesList[1].quantity;
	var mana = user.castle.resourcesList[0].resourceType == 'MANA' ? user.castle.resourcesList[0].quantity : user.castle.resourcesList[1].quantity;
	var maxGold = 0;
	var maxMana = 0;
	for (var k=0; k < roomsList.length; k++) {
		var room = roomsList[k];
		if ((room.roomType == 'TREASURY_VAULT') || (room.roomType == 'MANA_POTION_STORAGE')) {
			var roomParams = getRoomParams(room.roomType, room.roomLevel);

			if (room.roomType == 'TREASURY_VAULT') {
				if (user.display_name == 'TheLegend27') {
//					print(roomParams.capacity + ' ' + room.roomLevel);
				}
				maxGold += roomParams.capacity;
			}

			if (room.roomType == 'MANA_POTION_STORAGE') {
				maxMana += roomParams.capacity;
			}
		}

		if (room.roomType == 'THRONE') {
			var throneLimit = getThroneResourceLimit(room.roomLevel);
			udata += room.roomLevel + ',';
			if (user.display_name == 'TheLegend27') {
//				print(throneLimit.GOLD);
                        }
			//print(throneLimit.GOLD);
			maxGold += throneLimit.GOLD;
			maxMana += throneLimit.MANA;
		}
	}

	udata += gold + ',';
        udata += mana + ',';
	udata += maxGold + ',';
	udata += maxMana + ',';
	udata += parseInt(gold/maxGold * 100) + ',';
	udata += parseInt(mana/maxMana * 100) + ',';
	udata += user.password;
	print(udata);
}
