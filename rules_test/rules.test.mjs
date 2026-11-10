// Firestore security-rules tests for firestore.rules, run against the emulator.
import { readFileSync } from 'node:fs';
import {
  initializeTestEnvironment, assertSucceeds, assertFails,
} from '@firebase/rules-unit-testing';
import {
  doc, setDoc, getDoc, updateDoc, deleteDoc, writeBatch, Bytes, serverTimestamp,
  arrayUnion,
} from 'firebase/firestore';

const env = await initializeTestEnvironment({
  projectId: 'demo-incident-rules',
  firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'), host: '127.0.0.1', port: 8085 },
});

const as = (uid, email, verified) =>
  env.authenticatedContext(uid, { email, email_verified: verified }).firestore();

const student = as('stu', 'stu@alustudent.com', true);
const unverifiedStudent = as('unv', 'unv@alustudent.com', false);
const educ = as('edu', 'edu@alueducation.com', true);
const staff = as('stf', 'stf@aluedu.com', false); // staff domain, never verified
const fakeStaff = as('fake', 'fake@alustudent.com', true); // student who claims staff
const gmail = as('gm', 'gm@gmail.com', true);
const anon = env.unauthenticatedContext().firestore();

const report = (id, uid, extra = {}) => ({
  id, title: 'Leaking tap', description: 'Water is running all night long.',
  category: 'Water', location: 'Library', status: 'Submitted',
  reportedByUid: uid, reportedByName: 'Someone', isAnonymous: false, hasPhoto: false,
  createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
  statusHistory: [], ...extra,
});

let passed = 0, failed = 0;
async function check(name, fn) {
  try { await fn(); passed++; console.log('  ok   ' + name); }
  catch (e) { failed++; console.log('  FAIL ' + name + '\n       ' + (e.message || e).split('\n')[0]); }
}

async function seed() {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users/stu'), { uid: 'stu', role: 'student', email: 'stu@alustudent.com' });
    await setDoc(doc(db, 'users/stf'), { uid: 'stf', role: 'staff', email: 'stf@aluedu.com' });
    await setDoc(doc(db, 'users/fake'), { uid: 'fake', role: 'student', email: 'fake@alustudent.com' });
    await setDoc(doc(db, 'incidents/sub'), report('sub', 'stu'));
    await setDoc(doc(db, 'incidents/prog'), report('prog', 'stu', { status: 'In Progress' }));
    await setDoc(doc(db, 'incident_photos/sub'), { ownerUid: 'stu', data: Bytes.fromUint8Array(new Uint8Array([1, 2])) });
  });
}

console.log('\nAuthentication / users');
await seed();
await check('student creates own student profile', () =>
  assertSucceeds(setDoc(doc(as('n1', 'n1@alustudent.com', false), 'users/n1'), { uid: 'n1', role: 'student', email: 'n1@alustudent.com' })));
await check('student-domain user cannot create a staff profile', () =>
  assertFails(setDoc(doc(as('n2', 'n2@alustudent.com', false), 'users/n2'), { uid: 'n2', role: 'staff' })));
await check('alueducation.com user cannot create a staff profile', () =>
  assertFails(setDoc(doc(as('n5', 'n5@alueducation.com', true), 'users/n5'), { uid: 'n5', role: 'staff' })));
await check('unverified @aluedu.com user creates a staff profile', () =>
  assertSucceeds(setDoc(doc(as('n3', 'n3@aluedu.com', false), 'users/n3'), { uid: 'n3', role: 'staff', email: 'n3@aluedu.com' })));
await check('gmail user cannot create a profile', () =>
  assertFails(setDoc(doc(as('n4', 'n4@gmail.com', true), 'users/n4'), { uid: 'n4', role: 'student' })));
await check('lookalike domain aluedu.com.evil.com is rejected', () =>
  assertFails(setDoc(doc(as('n6', 'n6@aluedu.com.evil.com', true), 'users/n6'), { uid: 'n6', role: 'staff' })));
await check('user reads own profile', () => assertSucceeds(getDoc(doc(student, 'users/stu'))));
await check("user cannot read someone else's profile", () => assertFails(getDoc(doc(student, 'users/stf'))));
await check('student cannot promote self to staff', () =>
  assertFails(updateDoc(doc(student, 'users/stu'), { role: 'staff' })));
await check('user cannot change own email field', () =>
  assertFails(updateDoc(doc(student, 'users/stu'), { email: 'x@alustudent.com' })));
await check('signed-out visitor cannot read profiles', () => assertFails(getDoc(doc(anon, 'users/stu'))));

console.log('\nIncidents: read');
await check('verified student reads reports', () => assertSucceeds(getDoc(doc(student, 'incidents/sub'))));
await check('verified alueducation.com user reads reports', () => assertSucceeds(getDoc(doc(educ, 'incidents/sub'))));
await check('unverified staff-domain user reads reports', () => assertSucceeds(getDoc(doc(staff, 'incidents/sub'))));
await check('unverified student cannot read reports', () => assertFails(getDoc(doc(unverifiedStudent, 'incidents/sub'))));
await check('verified gmail user cannot read reports', () => assertFails(getDoc(doc(gmail, 'incidents/sub'))));
await check('signed-out visitor cannot read reports', () => assertFails(getDoc(doc(anon, 'incidents/sub'))));

console.log('\nIncidents: create');
await check('verified student creates a valid report', () =>
  assertSucceeds(setDoc(doc(student, 'incidents/c1'), report('c1', 'stu'))));
await check('anonymous report is accepted', () =>
  assertSucceeds(setDoc(doc(student, 'incidents/c9'), report('c9', 'stu', { isAnonymous: true, reportedByName: 'Anonymous' }))));
await check('staff (unverified @aluedu.com) creates a report', () =>
  assertSucceeds(setDoc(doc(staff, 'incidents/c2'), report('c2', 'stf'))));
await check('unverified student cannot create', () =>
  assertFails(setDoc(doc(unverifiedStudent, 'incidents/c3'), report('c3', 'unv'))));
await check('cannot report as another user', () =>
  assertFails(setDoc(doc(student, 'incidents/c4'), report('c4', 'stf'))));
await check('new report must start as Submitted', () =>
  assertFails(setDoc(doc(student, 'incidents/c5'), report('c5', 'stu', { status: 'Resolved' }))));
await check('title shorter than 5 chars rejected', () =>
  assertFails(setDoc(doc(student, 'incidents/c6'), report('c6', 'stu', { title: 'Tap' }))));
await check('description shorter than 15 chars rejected', () =>
  assertFails(setDoc(doc(student, 'incidents/c7'), report('c7', 'stu', { description: 'too short' }))));
await check('unknown category rejected', () =>
  assertFails(setDoc(doc(student, 'incidents/c8'), report('c8', 'stu', { category: 'Gossip' }))));
await check('id field must match document id', () =>
  assertFails(setDoc(doc(student, 'incidents/c10'), report('other', 'stu'))));

console.log('\nIncidents: update');
await seed();
await check('student cannot change status', () =>
  assertFails(updateDoc(doc(student, 'incidents/sub'), { status: 'Resolved', updatedAt: serverTimestamp() })));
await check('student who is not staff (role check) cannot change status', () =>
  assertFails(updateDoc(doc(fakeStaff, 'incidents/sub'), { status: 'In Progress' })));
await check('staff changes status with history entry', () =>
  assertSucceeds(updateDoc(doc(staff, 'incidents/prog'), {
    status: 'Resolved', updatedAt: serverTimestamp(),
    statusHistory: arrayUnion({ status: 'Resolved', changedByUid: 'stf' }),
  })));
await check('staff cannot set an unknown status', () =>
  assertFails(updateDoc(doc(staff, 'incidents/sub'), { status: 'Closed', updatedAt: serverTimestamp() })));
await check('staff cannot rewrite the title', () =>
  assertFails(updateDoc(doc(staff, 'incidents/sub'), { title: 'Changed by staff' })));
await seed();
await check('owner edits content while Submitted', () =>
  assertSucceeds(updateDoc(doc(student, 'incidents/sub'), {
    title: 'Leaking tap in library', description: 'Still running all night long.',
    category: 'Water', location: 'Library', updatedAt: serverTimestamp(),
  })));
await check('owner edit with invalid content rejected', () =>
  assertFails(updateDoc(doc(student, 'incidents/sub'), { title: 'X', updatedAt: serverTimestamp() })));
await check('owner cannot edit once In Progress', () =>
  assertFails(updateDoc(doc(student, 'incidents/prog'), { title: 'Changed later on', updatedAt: serverTimestamp() })));
await check('owner cannot change status via edit', () =>
  assertFails(updateDoc(doc(student, 'incidents/sub'), { status: 'Resolved' })));
await check('owner cannot flip the anonymous flag', () =>
  assertFails(updateDoc(doc(student, 'incidents/sub'), { isAnonymous: true })));
await check("another student cannot edit someone's report", () =>
  assertFails(updateDoc(doc(as('oth', 'oth@alustudent.com', true), 'incidents/sub'), { title: 'Hijacked title', updatedAt: serverTimestamp() })));

console.log('\nIncidents: delete');
await seed();
await check('staff cannot delete reports', () => assertFails(deleteDoc(doc(staff, 'incidents/sub'))));
await check('owner cannot delete once In Progress', () => assertFails(deleteDoc(doc(student, 'incidents/prog'))));
await check('other student cannot delete', () =>
  assertFails(deleteDoc(doc(as('oth', 'oth@alustudent.com', true), 'incidents/sub'))));
await check('owner deletes Submitted report and its photo in one batch', () => {
  const b = writeBatch(student);
  b.delete(doc(student, 'incidents/sub'));
  b.delete(doc(student, 'incident_photos/sub'));
  return assertSucceeds(b.commit());
});

console.log('\nPhotos');
await seed();
const bytes = (n) => Bytes.fromUint8Array(new Uint8Array(n));
await check('report + photo written in one batch', () => {
  const b = writeBatch(student);
  b.set(doc(student, 'incidents/p1'), report('p1', 'stu', { hasPhoto: true }));
  b.set(doc(student, 'incident_photos/p1'), { ownerUid: 'stu', data: bytes(200 * 1024), createdAt: serverTimestamp() });
  return assertSucceeds(b.commit());
});
await check('photo over 700 KB rejected', () => {
  const b = writeBatch(student);
  b.set(doc(student, 'incidents/p2'), report('p2', 'stu', { hasPhoto: true }));
  b.set(doc(student, 'incident_photos/p2'), { ownerUid: 'stu', data: bytes(700 * 1024 + 1), createdAt: serverTimestamp() });
  return assertFails(b.commit());
});
await check("photo cannot be attached to someone else's report", () =>
  assertFails(setDoc(doc(staff, 'incident_photos/sub'), { ownerUid: 'stf', data: bytes(10) })));
await check('photo cannot be replaced', () =>
  assertFails(setDoc(doc(student, 'incident_photos/sub'), { ownerUid: 'stu', data: bytes(10) })));
await check('verified user reads a photo', () => assertSucceeds(getDoc(doc(educ, 'incident_photos/sub'))));
await check('gmail user cannot read a photo', () => assertFails(getDoc(doc(gmail, 'incident_photos/sub'))));

await env.cleanup();
console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed ? 1 : 0);
