use castle-staging;

var players = {
    player2: {
        nid: 2,
        display_name: 'Ned',
        resourcesList : [
            {
                "resourceType" : "GOLD",
                "quantity" : 1000
            },
            {
                "resourceType" : "MANA",
                "quantity" : 1000
            }
        ]
    },
    player3: {
        nid: 3,
        display_name: 'John',
        resourcesList : [
            {
                "resourceType" : "GOLD",
                "quantity" : 2000
            },
            {
                "resourceType" : "MANA",
                "quantity" : 2000
            }
        ]
    },
    player4: {
        nid: -4,
        display_name: 'Gary',
        resourcesList : [
            {
                "resourceType" : "GOLD",
                "quantity" : 2500
            },
            {
                "resourceType" : "MANA",
                "quantity" : 2500
            }
        ]
    }
};

for (var username in players) {
    print(username);
    data = players[username];
    db.usersProfiles.find({username: username}).forEach(function(doc){
        doc.username = 'player' + data.nid;
        doc.nid = data.nid;
        doc.email = data.nid + '@emptyemail.org';
        doc.profileType = 'NPC';
        doc.castle.resourcesList = data.resourcesList;
        doc.display_name = data.display_name;
        db.usersProfiles.save(doc);
    });
}