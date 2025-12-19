# Portfolio Management System - Quick Start Guide

## ✅ Build Status
The project has been successfully created and builds without errors!

## 🚀 Getting Started

### 1. **Open the Project**
- Open `Portfolio-Management-System.xcodeproj` in Xcode

### 2. **Build & Run**
- Select an iPhone simulator (iPhone 17 or later)
- Press `Cmd + R` to build and run
- The app will launch with the main TabView interface

## 📋 Feature Walkthrough

### **Tab 1: Portfolio Overview** 📊
Your portfolio dashboard showing:
- **Total Portfolio Value** = Cash Balance + Holdings Value
- **Cash Balance** - Available cash after all transactions
- **Holdings** - List of all current positions with quantities and values
- **Capital Summary** - Breakdown of capital operations

**How to use:**
- View your complete portfolio at a glance
- See detailed breakdown by ticker
- Check capital history summary

---

### **Tab 2: Capital Management** 💰
Manage your cash and account balance:

**Available Operations:**
- **Initial Deposit** - Set your starting capital
- **Deposit** - Add funds to your account
- **Withdrawal** - Remove funds from your account  
- **Interest** - Record earned interest

**How to use:**
1. Tap the **+** button in the top-right
2. Select operation type
3. Enter amount and optional description
4. Tap "Save"

Your **Current Cash Balance** is automatically calculated as:
```
Initial Capital + Deposits - Withdrawals + Interest - (Buy Amount) + (Sell Amount) + (Dividends)
```

**Features:**
- Swipe left to delete any capital operation
- View complete history of all operations
- All data is automatically saved

---

### **Tab 3: Stock Tickers** 📈
Register and manage your investment instruments:

**How to add a ticker:**
1. Tap the **+** button
2. Enter ticker code (e.g., AAPL)
3. Enter company/fund name
4. Enter market (e.g., NASDAQ)
5. Select currency
6. Tap "Save"

**How to edit a ticker:**
- Tap on any ticker to edit its details

**How to delete a ticker:**
- Swipe left on a ticker and tap delete

**Important:**
- Ticker codes must be unique
- Register all tickers before creating transactions
- Deleting a ticker will also delete its holdings

---

### **Tab 4: Transactions** 🔄
Record all your trades:

**Transaction Types:**

**🔴 Buy**
- Decreases your cash balance
- Increases holdings quantity
- Updates average cost basis

**🟢 Sell**
- Increases your cash balance
- Decreases holdings quantity
- Maintains average cost basis

**🔵 Dividend**
- Increases your cash balance
- Does not affect holdings quantity
- Good for recording dividend income

**How to add a transaction:**
1. Tap the **+** button (only enabled if you have tickers)
2. Select the stock ticker
3. Choose transaction type (Buy, Sell, or Dividend)
4. Enter quantity
5. Enter price per unit
6. Add optional notes
7. Tap "Save"

**Total value calculation:**
```
Total = Quantity × Price Per Unit
```

**Features:**
- View total transaction amount instantly
- Filter by ticker using the segmented picker
- Swipe left to delete transactions
- Transactions auto-update your holdings

---

## 🧮 How It Works Behind The Scenes

### **Average Cost Basis Calculation**
When you buy stock, your average cost is recalculated:
```
New Average Cost = (Previous Total Cost + New Purchase Cost) / Total Quantity
```

Example:
- You buy 10 shares at $100 = $1000 total cost
- You buy 5 more shares at $120 = $600 additional cost
- New average cost = ($1000 + $600) / 15 = $106.67 per share

### **Holdings Tracking**
Your holdings automatically track:
- **Quantity** - Number of shares you own
- **Average Cost** - Weighted average price paid
- **Total Cost Basis** - Quantity × Average Cost

### **Cash Balance Calculation**
```
Current Cash = 
  Initial Capital 
  + Total Deposits 
  - Total Withdrawals 
  + Total Interest 
  + Sell Proceeds 
  + Dividend Income 
  - Buy Expenses
```

---

## 💡 Pro Tips

### **Setting Up Your Portfolio**
1. Start by adding your initial capital in the "Capital" tab
2. Add all your stock tickers in the "Tickers" tab
3. Record all historical transactions (buy/sell/dividend) in chronological order
4. Check the "Portfolio Overview" to verify everything looks correct

### **Recording Transactions**
- Enter transactions in chronological order for accurate cost basis tracking
- Use the "notes" field to add context (e.g., "IPO", "Bonus shares", etc.)
- Double-check quantities and prices before saving

### **Checking Your Balance**
- The cash balance in the Portfolio Overview should match your actual available cash
- If it doesn't match, review your capital operations and transactions
- Common issues: Forgotten deposits/withdrawals, incorrect transaction prices

### **Managing Tickers**
- Use standardized ticker codes (uppercase)
- Include the market name in the ticker notes if needed
- Don't duplicate ticker codes

---

## 📱 Data Storage

All your data is automatically saved to your device using UserDefaults:
- **Capitals** - All capital operations
- **Tickers** - Stock/ETF registry
- **Transactions** - All buy/sell/dividend records
- **Holdings** - Current positions

Your data persists across app launches and stays on your device.

---

## ❌ Troubleshooting

### "Can't add transactions" ❓
- Make sure you've registered at least one ticker first

### "Ticker already exists" ❓
- Ticker codes must be unique (case-insensitive)
- Check if you already added this ticker

### "Cash balance doesn't match" ❓
- Verify all capital operations are recorded
- Check that all transactions are entered correctly
- Ensure buy/sell amounts are calculated correctly (qty × price)

### "Holdings quantity is wrong" ❓
- Holdings are recalculated when you delete a transaction
- Try deleting and re-adding the transaction in correct order

---

## 🔐 Safety Notes

- Your data is stored locally on your device
- No data is sent to external servers
- You control all your portfolio information
- Data survives app updates and device restarts

---

## 🎯 Next Steps

### Try This First:
1. Add initial capital of $10,000
2. Add ticker "AAPL" (Apple Inc., NASDAQ, USD)
3. Record a buy: 10 shares at $150 = $1,500
4. Record a sell: 3 shares at $160 = $480
5. Check Portfolio Overview
   - Cash should be: $10,000 - $1,500 + $480 = $8,980
   - Holdings should show: 7 shares of AAPL at avg cost ~$150

### Advanced Features to Explore:
- Record dividends from your holdings
- Add multiple stock tickers and build a diversified portfolio
- Use the notes field to document your investment thesis
- Track capital operations over time
- Monitor your portfolio performance

---

## 📞 Support

If you encounter any issues:
1. Check the troubleshooting section above
2. Verify all inputs are valid (no negative numbers, etc.)
3. Try force-quitting and relaunching the app
4. Check Xcode console for any error messages

Happy investing! 🚀

