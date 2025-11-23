# Walk-In Services Debugging Guide

## 🔍 Troubleshooting Steps

### Issue: "No Walk-In Customers" shows all the time

#### Step 1: Check Firestore Collection
1. Open Firebase Console
2. Navigate to Firestore Database
3. Look for a collection named **`walkins`**
   - ❌ If it doesn't exist, create it manually
   - ✅ If it exists, check if it has any documents

#### Step 2: Verify Collection Has Documents
1. In Firebase Console, click on `walkins` collection
2. Check if there are any documents
   - ❌ If empty, use the debug feature in the app OR add test data manually
   - ✅ If documents exist, move to Step 3

#### Step 3: Verify Document Structure
Each document in `walkins` should have these fields:

```json
{
  "userId": "test-user-123",
  "serviceNames": ["Hydrophobic & Engine Wash"],
  "bookingDate": "2025-11-24",
  "bookingTime": "10:30",
  "status": "Pending",
  "price": 150.0,
  "carName": "Honda Civic",
  "carType": "Sedan",
  "plateNumber": "ABC-1234",
  "phoneNumber": "+1234567890",
  "technician": "John Doe",
  "paymentMethod": "Cash",
  "progress": "approved"
}
```

**Important:** Status must be exactly one of:
- `Pending`
- `In Progress`
- `Completed`

#### Step 4: Check Firestore Security Rules
1. In Firebase Console, go to Firestore → Rules
2. Ensure the `walkins` collection allows reading:

```firestore
match /walkins/{document=**} {
  allow read: if request.auth != null;
  allow create, update, delete: if request.auth.uid == resource.data.userId || request.auth == null;
}
```

---

## ✨ How to Add Test Data

### Method 1: Using the App (Easiest)
1. Open the app and go to Home screen
2. Look for "Ongoing Onsite Services" section
3. Find the small info icon (ℹ️) next to the title
4. **Long-press** the info icon
5. A snackbar will appear saying "Test data added!"
6. The UI should refresh within 2-3 seconds

### Method 2: Manual Firestore Entry
1. Open Firebase Console
2. Go to Firestore Database
3. Click on `walkins` collection (create if missing)
4. Click "Add document"
5. Copy-paste this JSON (replace document ID with auto):
```json
{
  "userId": "walk-in-customer-1",
  "serviceNames": ["Hydrophobic & Engine Wash"],
  "bookingDate": "2025-11-24",
  "bookingTime": "14:30",
  "status": "Pending",
  "price": 150.0,
  "carName": "Honda Civic",
  "carType": "Sedan",
  "plateNumber": "ABC-1234",
  "phoneNumber": "+1234567890",
  "technician": "Awaiting",
  "paymentMethod": "Cash",
  "progress": "approved"
}
```
6. Click Save
7. The app should show the new booking within 2-3 seconds (real-time update)

---

## 🐛 Common Issues & Solutions

### "No Walk-In Customers" persists after adding data
**Possible Causes:**
- Status is not exactly "Pending", "In Progress", or "Completed" (case-sensitive!)
- Document is missing required fields
- Collection name is wrong (should be lowercase `walkins`)

**Solution:**
1. Check the exact status value in your document
2. Add all required fields from the template above
3. Verify collection name is `walkins`

### Card shows loading spinner indefinitely
**Possible Causes:**
- Internet connection issue
- Firestore security rules blocking access
- Firebase not initialized properly

**Solution:**
1. Check internet connection
2. Review Firestore security rules
3. Restart the app
4. Check browser console for errors (if testing on web)

### Click on card doesn't show dialog
**Possible Causes:**
- Card may not be in tap zone
- Dialog might be loading behind
- Widget not rendering properly

**Solution:**
1. Try double-tapping the card
2. Check if dialog is appearing off-screen
3. Restart the app
4. Check console for any errors

### Service card shows data but dialog is empty
**Possible Causes:**
- Some required fields are missing in Firestore
- Fields don't match the expected data types

**Solution:**
1. Verify all fields are present in Firestore document
2. Check that `serviceNames` is an array, not a string
3. Check that `bookingDate` and `bookingTime` are strings

---

## 🔧 Checking Console Logs

### Android (via Android Studio or logcat)
```
flutter logs
```
Look for messages starting with:
- `OnsiteServices Error:` - Stream error
- `Error fetching walk-in bookings:` - Fetch error
- `Error updating booking status:` - Update error

### iOS (via Xcode)
1. Open project in Xcode
2. Run the app
3. Check Console output for logs

### Web/Chrome DevTools
1. Press `F12` to open DevTools
2. Go to Console tab
3. Look for similar error messages

---

## ✅ Verification Checklist

- [ ] Firestore collection `walkins` exists
- [ ] At least one document exists in `walkins`
- [ ] Document has all required fields
- [ ] Status field is "Pending", "In Progress", or "Completed"
- [ ] Firebase Security Rules allow reading from `walkins`
- [ ] App is connected to internet
- [ ] No errors in console logs

---

## 🆘 Still Having Issues?

### Debug Information to Collect:
1. Screenshot of Firestore `walkins` collection
2. Full error message from console logs
3. Firebase Security Rules configuration
4. App logs (via `flutter logs`)

### Quick Restart
1. Stop the app
2. Run `flutter clean`
3. Run `flutter pub get`
4. Run the app again

---

## 📱 Testing Real-Time Updates

1. Add a document to `walkins` collection
2. Watch the Home screen
3. New booking should appear **within 2-3 seconds** without manual refresh
4. Update the document status (Pending → In Progress)
5. Badge color should change automatically

---

## 🎯 Expected Behavior

### When Data Exists:
- Cards show service names
- Status badges display with appropriate colors
- Clicking a card shows full booking details dialog
- Real-time updates when Firestore data changes

### When No Data:
- Shows "No Walk-In Customers" message
- Cards still display but with placeholder text
- No errors in console

---

## 📞 Support

If you continue to have issues, collect the above information and review:
- `IMPLEMENTATION_COMPLETE.md` - What was implemented
- `WALK_IN_SERVICES_GUIDE.md` - Implementation details
- `CODE_EXAMPLES.md` - Code reference
