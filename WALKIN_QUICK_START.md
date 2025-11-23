# Quick Start - Walk-In Services Testing

## 🎯 Quick Test (2 minutes)

### Step 1: Add Test Data
1. Open the app
2. Go to **Home Screen**
3. Find **"Ongoing Onsite Services"** section
4. Long-press the **ℹ️ icon** next to the title
5. See "Test data added!" message

### Step 2: Verify Display
- Wait 2-3 seconds
- Service card should show:
  - Service name: "Hydrophobic & Engine Wash"
  - Status badge: "Pending" (Orange color)
  - Service #1, #2, etc.

### Step 3: Click to See Details
- Click any service card
- Dialog appears showing:
  - Booking ID
  - Service Name
  - Status
  - Date & Time
  - Price
  - Car details (Name, Type, Plate)
  - Phone & Technician

---

## 🔧 Manual Test (5 minutes)

### Alternative: Add Data via Firebase Console

1. **Open Firebase Console**
   - Go to https://console.firebase.google.com
   - Select your project

2. **Navigate to Firestore**
   - Go to Firestore Database

3. **Create/Open `walkins` Collection**
   - Click "+ Add collection"
   - Name it: `walkins`
   - Click "Auto ID"

4. **Add Test Document**
   - Copy-paste this exact data:
   ```
   Field: userId          | Type: string  | Value: test-user-1
   Field: serviceNames    | Type: array   | Value: ["Hydrophobic & Engine Wash"]
   Field: bookingDate     | Type: string  | Value: 2025-11-24
   Field: bookingTime     | Type: string  | Value: 10:30
   Field: status          | Type: string  | Value: Pending
   Field: price           | Type: number  | Value: 150
   Field: carName         | Type: string  | Value: Honda Civic
   Field: carType         | Type: string  | Value: Sedan
   Field: plateNumber     | Type: string  | Value: ABC-1234
   Field: phoneNumber     | Type: string  | Value: +1234567890
   Field: technician      | Type: string  | Value: John Doe
   Field: paymentMethod   | Type: string  | Value: Cash
   Field: progress        | Type: string  | Value: approved
   ```

5. **Click Save**
   - Document is created

6. **Check App**
   - Go back to app
   - Service card should appear in 2-3 seconds
   - No manual refresh needed!

---

## 🧪 Real-Time Test

1. **Add Document via Firestore (as above)**
2. **Watch Home Screen**
   - New booking appears automatically
   - No refresh needed!
3. **Update Status in Firestore**
   - Open document
   - Change `status` from "Pending" to "In Progress"
   - Watch badge color change (Orange → Blue)
   - Automatic!

---

## ❌ If It Doesn't Work

### Check 1: Collection Name
- Firestore collection must be named: **`walkins`** (lowercase)
- Not: walkin, walk-ins, walkinsCollection, etc.

### Check 2: Status Field
- Must be exactly: **"Pending"**, **"In Progress"**, or **"Completed"**
- Not: "pending", "pending ", "in-progress", etc. (case-sensitive!)

### Check 3: Field Names
- All field names must match exactly (case-sensitive!)
- Missing fields will cause errors

### Check 4: Data Types
- `serviceNames` must be an ARRAY, not a string
- `price` must be a NUMBER, not a string
- All other fields are strings

### Check 5: Firestore Rules
- Ensure you can read from `walkins` collection
- Go to Firestore → Rules
- Should allow: `allow read;` at minimum

### Check 6: Internet Connection
- Ensure app has internet
- Check console logs for errors

---

## 📋 Expected Results

### Before Adding Data
```
Ongoing Onsite Services
┌─────────────┬─────────────┐
│ Service #1  │ Service #2  │
│ No Walk-In  │ No Walk-In  │
│ Customers   │ Customers   │
└─────────────┴─────────────┘
```

### After Adding Data
```
Ongoing Onsite Services
┌─────────────────────────────────────┬─────────────────────────────────────┐
│ Service #1                          │ Service #2                          │
│ Hydrophobic & Engine Wash           │ No Walk-In Customers                │
│ ┌─────────────────────────────────┐ │                                     │
│ │ Pending                         │ │                                     │
│ └─────────────────────────────────┘ │                                     │
└─────────────────────────────────────┴─────────────────────────────────────┘
```

### When Clicked
```
Booking Details Dialog
┌──────────────────────────────────────┐
│ Booking ID: xxxx                     │
│ Service: Hydrophobic & Engine Wash   │
│ Status: Pending                      │
│ Date: 2025-11-24                     │
│ Time: 10:30                          │
│ Price: $150.00                       │
│ Car: Honda Civic                     │
│ Plate: ABC-1234                      │
│ Phone: +1234567890                   │
│ Technician: John Doe                 │
│              [OK]                    │
└──────────────────────────────────────┘
```

---

## 🎨 Status Badge Colors

| Status | Color | Meaning |
|--------|-------|---------|
| Pending | Orange 🟠 | Waiting to start |
| In Progress | Blue 🔵 | Currently being worked on |
| Completed | Green 🟢 | Finished |

---

## 💡 Troubleshooting Console

Open terminal and run:
```bash
flutter logs
```

Look for:
- ✅ `Test data added successfully` = Test data worked
- ❌ `OnsiteServices Error:` = Stream error (check Firestore)
- ❌ `Error fetching walk-in bookings:` = Fetch error (check rules)

---

## 📱 Screen Navigation

```
Home Screen
    ↓
Scroll down to "Ongoing Onsite Services"
    ↓
[Long-press ℹ️ icon to add test data]
    ↓
[Click any service card to see details]
```

---

## ⏱️ Expected Timing

- **Test data addition**: Instant
- **Data appearing on screen**: 2-3 seconds
- **Real-time updates**: <1 second
- **Dialog open**: Instant

---

## 🎯 Success Checklist

- [ ] Info icon visible in title bar
- [ ] Long-press adds test data (see "Test data added!" message)
- [ ] Service cards populate with data
- [ ] Status badges show with correct colors
- [ ] Clicking card shows booking details
- [ ] Real-time updates work (update in Firestore → see change instantly)
- [ ] Dark mode colors work properly
- [ ] No console errors

---

**You're ready to test! Long-press that info icon now! 🚀**
