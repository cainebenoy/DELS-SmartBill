# DELS SmartBill - Test Plan

## 🚀 App is Running Successfully!
The app has been launched on Windows with no compilation errors. All Riverpod state management has been implemented for Products, Customers, and Invoices.

---

## 📋 Manual Testing Checklist

### 1. **Products Feature Testing**
Navigate to: **Products tab** (2nd icon in bottom navigation)

#### Test Cases:
- [ ] **View Products**
  - Products list should load with loading indicator
  - Existing products should display correctly
  - Each product should show: name, category, price

- [ ] **Search Products**
  - Type in search box
  - Results should filter in real-time
  - Test search by: name, category
  - Clear search should show all products

- [ ] **Add Product**
  - Click FAB (+) button
  - Fill in: Name, Category, Price
  - Submit form
  - Should see "Product added" snackbar
  - New product should appear in list
  - **Check sync logs** in console

- [ ] **Edit Product**
  - Click edit icon on any product
  - Modify fields
  - Save changes
  - Should see "Product updated" snackbar
  - Changes should reflect immediately
  - **Check sync logs**

- [ ] **Delete Product**
  - Click delete icon
  - Confirm deletion dialog
  - Should see "Product deleted" snackbar with UNDO action
  - Product should disappear from list
  - **Test UNDO**: Click undo before it disappears
  - **Check sync logs**

---

### 2. **Customers Feature Testing**
Navigate to: **Customers tab** (3rd icon in bottom navigation)

#### Test Cases:
- [ ] **View Customers**
  - Customers list should load
  - Each customer should show: name, phone, email, address (if set)
  - Avatar with first letter of name

- [ ] **Search Customers**
  - Type in search box
  - Test search by: name, phone, email
  - Results should filter in real-time

- [ ] **Add Customer**
  - Click FAB (+) button
  - Fill required fields: Name*, Phone*, Email*
  - Optional: Address
  - Email validation should work (requires @)
  - Submit form
  - Should see "Customer added" snackbar
  - **Check sync logs**

- [ ] **Edit Customer**
  - Click edit icon on any customer
  - Modify fields
  - Save changes
  - Should see "Customer updated" snackbar
  - **Check sync logs**

- [ ] **Delete Customer**
  - Click delete icon
  - Confirm deletion
  - Should see "Customer deleted" snackbar with UNDO
  - **Test UNDO** functionality
  - **Check sync logs**

---

### 3. **Invoices Feature Testing**

#### **View Invoices List**
Navigate to: **Invoice tab** (4th icon) → You'll see the invoice creation page

*Note: InvoicesListPage was created but not yet integrated into navigation. You can test it by temporarily updating the navigation.*

#### Test Cases for Invoice Creation:
- [ ] **Create Invoice**
  - Should see customer autocomplete field
  - Should see list of products
  - Add customer (or create new)
  - Add products to cart (click "Add" button)
  - Adjust quantities with +/- buttons
  - Verify total calculation
  - Click "Save Invoice"
  - Should see "Invoice saved!" snackbar
  - Cart should clear
  - **Check sync logs**

#### Test Cases for InvoicesListPage (when integrated):
- [ ] **View Invoices**
  - Invoice list with: invoice number, customer name, date, item count, total
  - Search by invoice number or customer name
  - Delete invoice with confirmation
  - **Check sync logs**

---

### 4. **Sync Testing**

#### Monitor Console Logs:
Watch for these log messages after each CRUD operation:

```
💡 [AutoSync] Starting automatic sync...
💡 [SyncService] Starting push sync...
💡 [SyncService] Push sync completed successfully
💡 [SyncService] Starting pull sync...
💡 [SyncService] Pull sync completed successfully
```

#### Test Cases:
- [ ] **Auto-sync after Add**
  - Add a product/customer
  - Check console for sync logs
  - Verify no errors

- [ ] **Auto-sync after Update**
  - Edit a product/customer
  - Check console for sync logs

- [ ] **Auto-sync after Delete**
  - Delete a product/customer
  - Check console for sync logs

- [ ] **Background Sync on Resume**
  - Minimize app, then restore
  - Should see: "App resumed, triggering sync..."

---

### 5. **Error Handling Testing**

#### Test Cases:
- [ ] **Invalid Product Price**
  - Try adding product with negative/zero price
  - Should show validation error

- [ ] **Invalid Customer Email**
  - Try adding customer without @ in email
  - Should show "Enter a valid email"

- [ ] **Empty Required Fields**
  - Try submitting forms with empty required fields
  - Should show "field is required" errors

- [ ] **Network Error Simulation**
  - Disconnect internet
  - Try adding/editing items
  - Should see error state
  - Reconnect and retry
  - Should work after reconnection

---

### 6. **UI/UX Testing**

#### Test Cases:
- [ ] **Loading States**
  - Products page shows CircularProgressIndicator while loading
  - Customers page shows loader
  - AsyncValue.when() handles loading state

- [ ] **Error States**
  - If data fails to load, should show error message
  - Should show "Retry" button
  - Click retry should reload data

- [ ] **Empty States**
  - Navigate to Products (if empty): "No products found. Tap + to add..."
  - Navigate to Customers (if empty): "No customers found. Tap + to add..."

- [ ] **Dark Mode**
  - Toggle dark mode (if available)
  - Check colors adapt properly
  - Cards should have proper contrast

- [ ] **Navigation**
  - Bottom navigation should have 6 tabs:
    1. Dashboard
    2. Products
    3. Customers
    4. Invoice
    5. Reports
    6. Settings
  - Active tab should be highlighted

---

### 7. **Performance Testing**

#### Test Cases:
- [ ] **Smooth Scrolling**
  - Add 20+ products
  - Scroll through list smoothly
  - No lag or jank

- [ ] **Search Performance**
  - Type quickly in search box
  - Results should update smoothly without lag

- [ ] **Hot Reload**
  - Make a minor UI change in code
  - Press 'r' in terminal for hot reload
  - Changes should apply instantly

---

## 🐛 Bug Reporting

If you find any issues, note:
1. **Steps to reproduce**
2. **Expected behavior**
3. **Actual behavior**
4. **Error messages** (check console logs)
5. **Screenshots** (if UI issue)

---

## ✅ Testing Status

### What's Working:
- ✅ App compiles and runs
- ✅ No compilation errors
- ✅ Supabase connection established
- ✅ Sync service operational
- ✅ Riverpod providers created for all features

### To Test:
- ⏳ All CRUD operations for Products
- ⏳ All CRUD operations for Customers
- ⏳ Invoice creation workflow
- ⏳ Search functionality
- ⏳ Sync logs verification
- ⏳ Error handling
- ⏳ UI responsiveness

---

## 📝 Notes

- **Current Navigation:** Dashboard, Products, Customers, Invoice, Reports, Settings (6 tabs)
- **Invoice List Page:** Created but needs to be integrated into navigation
- **Sync Logs:** Monitor console for detailed sync information
- **Hot Reload:** Press 'r' in terminal to hot reload after code changes
- **DevTools:** Available at http://127.0.0.1:9101 for debugging

---

## 🔄 Next Steps After Testing

1. **Fix any bugs found**
2. **Integrate InvoicesListPage into navigation**
3. **Add more error handling**
4. **Improve loading states**
5. **Polish UI/UX**
6. **Add form validation improvements**
7. **Test on Android/iOS** (if needed)

---

**Happy Testing! 🎉**
