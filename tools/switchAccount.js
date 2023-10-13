//set database
db = db.getSiblingDB('castle-staging');
//set destination username
dest = 'player33730';
//set source username
src = 'player43948';
destinationAccount = db.usersProfiles.findOne({username: dest});
sourceAccount = db.usersProfiles.findOne({username: src});

if (destinationAccount && sourceAccount) {
    destinationAccount.username =  src;
    sourceAccount.username = dest;

    tmpPassword = sourceAccount.password;
    tmpNid = sourceAccount.nid;
    tmp_id = sourceAccount._id;
    tmpEmail = sourceAccount.email;
    tmpDisplay = sourceAccount.display_name;

    sourceAccount.password = destinationAccount.password;
    sourceAccount.nid = destinationAccount.nid;
    sourceAccount._id = destinationAccount._id;
    sourceAccount.email = destinationAccount.email;
    sourceAccount.display_name = destinationAccount.display_name;

    destinationAccount.password = tmpPassword;
    destinationAccount.nid = tmpNid;
    destinationAccount._id = tmp_id;
    destinationAccount.email = tmpEmail;
    destinationAccount.display_name = tmpDisplay;


    destinationAccount.resetRequired = true;
    destinationAccount.resetMessage = "Your account has been restored";

    sourceAccount.resetRequired = true;
    sourceAccount.resetMessage = "Your account has been restored";

    db.usersProfiles.remove({username: src});
    db.usersProfiles.remove({username: dest});

    print(db.usersProfiles.save(destinationAccount));
    print(db.usersProfiles.save(sourceAccount));

} else {
    console.log("Destination or source account not found");
}