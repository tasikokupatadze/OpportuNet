// One-time cleanup: removes the old `email` field from every users/{uid}
// profile. Sign-in emails stay in Firebase Auth; only the copy that other
// signed-in users could read is removed.
//
// Run from the project root (D:\OpportuNet_V1.0.0):
//   set GOOGLE_APPLICATION_CREDENTIALS=C:\path\to\service-account.json
//   node tools\remove-profile-emails.js           (dry run: only counts)
//   node tools\remove-profile-emails.js --apply   (removes the field)
//
// Lives outside functions/ so it is never deployed or linted.
const admin = require("../functions/node_modules/firebase-admin");

admin.initializeApp({projectId: "opportunet-bd7b8"});
const db = admin.firestore();

(async () => {
  const apply = process.argv.includes("--apply");
  const snap = await db.collection("users").get();
  const withEmail = snap.docs.filter((d) => d.get("email") !== undefined);

  console.log(
      `${withEmail.length} of ${snap.size} profiles still have an email field.`,
  );
  if (!apply) {
    console.log("Dry run, nothing changed. Re-run with --apply to remove them.");
    return;
  }

  for (let i = 0; i < withEmail.length; i += 400) {
    const batch = db.batch();
    for (const doc of withEmail.slice(i, i + 400)) {
      batch.update(doc.ref, {email: admin.firestore.FieldValue.delete()});
    }
    await batch.commit();
  }
  console.log(`Removed the email field from ${withEmail.length} profiles.`);
})().catch((err) => {
  console.error(err);
  process.exit(1);
});
