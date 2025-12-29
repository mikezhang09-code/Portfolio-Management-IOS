# Portfolio Management System - iOS App User Reference Guide

## Table of Contents
1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [App Overview](#app-overview)
4. [Tab-by-Tab Guide](#tab-by-tab-guide)
5. [Managing Your Portfolio](#managing-your-portfolio)
6. [Transaction Management](#transaction-management)
7. [Analysis & Historical Data](#analysis--historical-data)
8. [Cash Account Management](#cash-account-management)
9. [Settings & Account](#settings--account)
10. [Tips & Best Practices](#tips--best-practices)
11. [Troubleshooting](#troubleshooting)
12. [Frequently Asked Questions](#frequently-asked-questions)

---

## Introduction

The Portfolio Management System is a comprehensive iOS application for tracking your investments, managing transactions, and analyzing portfolio performance. The app features both local data storage and cloud synchronization via Supabase, allowing you to access your portfolio from multiple devices.

### Key Features
- ✅ Cloud-based portfolio tracking with Supabase integration
- ✅ Multi-currency support (USD, EUR, GBP, JPY, CAD, AUD, HKD, CNY)
- ✅ Real-time stock price updates
- ✅ Comprehensive transaction management (Buy, Sell, Dividends, Deposits, Withdrawals)
- ✅ Historical performance analysis with charts
- ✅ Portfolio sorting and filtering
- ✅ Transaction history with advanced filters
- ✅ Cost basis and gain/loss tracking
- ✅ Secure authentication

---

## Getting Started

### First Launch
1. **Launch the app** - You'll see the authentication screen
2. **Sign up or Sign in:**
   - Create a new account with your email
   - Or sign in if you already have an account
3. **Grant permissions** - Allow the app to sync data to the cloud

### Initial Setup Workflow
After signing in, follow this recommended sequence:

1. **Set up your base currency** (Settings → Base Currency)
2. **Add your first cash account** (Cash tab → Add Account)
3. **Register your stock tickers** (Stocks tab → Add Stock)
4. **Record your initial capital** (Transactions → Cash Deposit)
5. **Add historical transactions** (Transactions → Add Transaction)

---

## App Overview

### Navigation Structure
The app uses a **TabView** interface with 6 main tabs:

| Tab | Icon | Purpose |
|-----|------|---------|
| **My Portfolio** | 📊 | Overview of your entire portfolio |
| **Stocks** | 📈 | Manage stock/ETF holdings |
| **Transactions** | 🔄 | View and add all transactions |
| **Analysis** | 📉 | Historical performance analysis |
| **Cash** | 💰 | Manage cash accounts and balances |
| **Settings** | ⚙️ | App settings and account management |

### Data Storage
- **Cloud Sync**: All data is synchronized to Supabase cloud database
- **Local Cache**: Recent data is cached on device for fast access
- **Auto-refresh**: Prices and data refresh automatically (or manually)

---

## Tab-by-Tab Guide

### 1. My Portfolio Tab 📊

**Purpose**: Complete portfolio overview at a glance

**What you'll see**:
- **Total Portfolio Value** - Sum of all holdings + cash (in USD)
- **Today's Change** - Day's gain/loss excluding cash flows
- **Total Gain/Loss** - Overall profit/loss since inception
- **Cash vs. Holdings breakdown**
- **Sorted list of all positions** with:
  - Stock symbol and name
  - Current market value
  - Day's gain/loss (absolute and percentage)
  - Total gain/loss (absolute and percentage)
  - Shares owned
  - Average cost per share

**Features**:
- **Sort positions** by tapping the sort button (ticker, market value, gains, etc.)
- **Toggle sort direction** (ascending/descending)
- **Expandable details** - tap any position for more info
- **Real-time updates** - prices refresh automatically
- **Multi-currency conversion** - all values shown in USD

**Key Metrics Explained**:
- **Today's Change**: Isolates market performance from cash movements
  - Formula: Current Value - Yesterday's Value - Today's External Cash Flow
  - External cash flows = deposits, withdrawals, dividends (excludes buy/sell)
- **Total Gain/Loss**: 
  - Formula: Current Holdings Value - Total Cost Basis
  - Shows unrealized gains (positions still held)

---

### 2. Stocks Tab 📈

**Purpose**: Manage your stock/ETF registry

**What you can do**:

#### Add a New Stock
1. Tap the **+** button
2. Enter stock details:
   - **Symbol** (e.g., AAPL, TSLA)
   - **Name** (e.g., Apple Inc.)
   - **Market** (US, HK, CN, etc.)
   - **Exchange** (optional, e.g., NASDAQ, NYSE)
3. Tap **Save**

#### Edit an Existing Stock
1. Tap on any stock in the list
2. Modify the details
3. Tap **Save**

#### Delete a Stock
1. Swipe left on the stock
2. Tap **Delete**
3. ⚠️ **Warning**: Deleting a stock will remove all its transactions

**Important Notes**:
- Symbols must be unique
- Register all stocks before creating transactions
- Market field is used for currency conversion
- Stock list is shared across all tabs

---

### 3. Transactions Tab 🔄

**Purpose**: View and manage all your investment transactions

**Viewing Transactions**:

**Filter Options**:
- **All Tickers** or select a specific stock
- **All Types** or filter by:
  - Buy
  - Sell
  - Dividend

**Transaction List Shows**:
- Date and time
- Stock symbol
- Transaction type (Buy/Sell/Dividend)
- Quantity
- Price per share
- Total amount
- Currency
- Notes (if any)

**Adding Transactions**:

1. Tap the **+** button
2. Select transaction type:
   - **Stock Buy** - Purchase shares
   - **Stock Sell** - Sell shares
   - **Stock Dividend** - Dividend income
   - **Cash Deposit** - Add funds
   - **Cash Withdrawal** - Remove funds
   - **Cash Interest** - Interest earned
   - **Currency Exchange** - FX transfer

3. Fill in the details:
   - **Date** - Transaction date
   - **Stock** (if applicable)
   - **Cash Account** (source)
   - **Quantity** (for stock trades)
   - **Price per Share** (for stock trades)
   - **Fees** (optional)
   - **Notes** (optional)

4. Tap **Save**

**Transaction Types Explained**:

| Type | Effect on Cash | Effect on Holdings | Use For |
|------|---------------|-------------------|---------|
| **Stock Buy** | Decreases | Increases shares | Purchasing stocks |
| **Stock Sell** | Increases | Decreases shares | Selling stocks |
| **Stock Dividend** | Increases | No change | Dividend income |
| **Cash Deposit** | Increases | No change | Adding funds |
| **Cash Withdrawal** | Decreases | No change | Removing funds |
| **Cash Interest** | Increases | No change | Interest income |
| **Currency Exchange** | No net change | No change | Currency conversion |

**Deleting Transactions**:
- Swipe left on any transaction
- Tap **Delete**
- Holdings and cash will be recalculated automatically

---

### 4. Analysis Tab 📉

**Purpose**: Analyze historical performance with charts and metrics

**Features**:

#### Time Range Selection
- 1M, 3M, 6M, 1Y, 3Y, 5Y, All
- Tap any range to update analysis

#### Benchmark Comparison
- Compare your portfolio against market indices:
  - S&P 500 (SPX)
  - NASDAQ Composite (IXIC)
  - Dow Jones (DJI)
  - And more
- Select benchmark from dropdown menu

#### What You'll See:
- **Performance Chart** - Your portfolio vs. benchmark over time
- **Risk Metrics**:
  - Volatility
  - Sharpe Ratio
  - Maximum Drawdown
  - Beta (vs. benchmark)
- **Correlation Analysis** - How your portfolio correlates with benchmark
- **Return Distribution** - Frequency of returns
- **Rolling Returns** - Performance across different periods

**Refresh Data**:
- Tap the refresh button (↻) in top-right
- Data will reload from cloud

**Use Cases**:
- Track long-term performance vs. market
- Identify periods of outperformance/underperformance
- Analyze risk-adjusted returns
- Compare against major indices

---

### 5. Cash Tab 💰

**Purpose**: Manage your cash accounts and view balances

**What You'll See**:
- **Total Cash Balance** - Sum of all accounts (in USD)
- **List of Cash Accounts** with:
  - Account name
  - Native balance (in account currency)
  - USD value
  - Currency

**Features**:
- View multiple cash accounts
- Support for different currencies
- Automatic FX conversion to USD
- Track cash flows across accounts

**Adding Cash Operations**:
Use the Transactions tab to add:
- Deposits
- Withdrawals
- Interest income
- Currency exchanges

---

### 6. Settings Tab ⚙️

**Purpose**: Configure app and manage your account

**Account Section**:
- **Email** - Your account email
- **User ID** - Unique identifier
- **Sign Out** - Log out (data remains in cloud)

**Data Section**:
- **Sync Settings** - Configure sync preferences
- **Export Data** - Export your portfolio data

**About Section**:
- **Version** - App version number
- **Privacy Policy** - Link to privacy policy
- **Terms of Service** - Link to terms

---

## Managing Your Portfolio

### Step-by-Step Portfolio Setup

#### Step 1: Set Up Base Currency
1. Go to **Settings**
2. Select your preferred base currency (default: USD)
3. All portfolio values will be converted to this currency

#### Step 2: Add Cash Accounts
1. Go to **Cash** tab
2. Add accounts for different currencies if needed
3. Name them descriptively (e.g., "US Brokerage USD", "HK Savings HKD")

#### Step 3: Register Your Stocks
1. Go to **Stocks** tab
2. Add all stocks you own or plan to own
3. Include market information for accurate FX conversion

#### Step 4: Record Initial Capital
1. Go to **Transactions** tab
2. Tap **+**
3. Select **Cash Deposit**
4. Enter the amount you're starting with
5. Add note: "Initial capital"

#### Step 5: Add Historical Transactions
1. For each stock you own:
   - Add Buy transactions in chronological order
   - Add Dividend transactions
   - Add Sell transactions if you've sold any
2. Include all relevant details (quantity, price, fees)

#### Step 6: Verify Your Portfolio
1. Go to **My Portfolio** tab
2. Check that:
   - Total value looks correct
   - Cash balance matches your records
   - Holdings match your actual positions
   - All stocks are listed

### Portfolio Maintenance

#### Daily Tasks
- Check **My Portfolio** for updates
- Review **Today's Change** to see market performance

#### Weekly Tasks
- Add new transactions (dividends, trades)
- Review transaction history for accuracy

#### Monthly Tasks
- Review performance in **Analysis** tab
- Check for data sync issues
- Verify cash balances

#### After Each Trade
1. Record the transaction immediately
2. Verify it appears correctly in your portfolio
3. Check that cash and holdings are updated

---

## Transaction Management

### Transaction Groups

The app uses **transaction groups** to link related transactions:

**Example: Stock Purchase**
```
Transaction Group: Buy AAPL
├── Stock Transaction: Buy 10 shares @ $150
└── Cash Transaction: Outflow $1,500 from USD account
```

**Example: Dividend**
```
Transaction Group: Dividend AAPL
├── Stock Transaction: Dividend $15
└── Cash Transaction: Inflow $15 to USD account
```

### Average Cost Basis Calculation

**How it works**:
When you buy shares, your average cost is recalculated:

```
New Average Cost = (Previous Total Cost + New Purchase Cost) / Total Quantity
```

**Example**:
- Buy 10 shares at $100 = $1,000 total (avg: $100)
- Buy 5 shares at $120 = $600 additional (avg: $106.67)
- New average = ($1,000 + $600) / 15 = $106.67

**Why this matters**:
- Used to calculate unrealized gains/losses
- Important for tax reporting
- Helps track true cost of your positions

### Cash Balance Calculation

Your cash balance is calculated as:

```
Current Cash = 
  Initial Capital 
  + Total Deposits 
  - Total Withdrawals 
  + Total Interest 
  + Sell Proceeds 
  + Dividend Income 
  - Buy Expenses
  - Fees
```

**Verification**:
Always ensure your calculated cash matches your actual account balance.

---

## Analysis & Historical Data

### Understanding the Charts

#### Performance Chart
- **Blue line**: Your portfolio value over time
- **Green line**: Selected benchmark index
- **Y-axis**: Value (in base currency)
- **X-axis**: Time

**How to read**:
- Rising lines = gains
- Falling lines = losses
- Steeper slope = higher return
- Wider gap = outperformance vs. benchmark

#### Risk Metrics

**Volatility**:
- Measures price fluctuation
- Higher = more risky
- Standard deviation of returns

**Sharpe Ratio**:
- Risk-adjusted return
- Higher = better risk/reward
- Formula: (Return - Risk-free rate) / Volatility

**Maximum Drawdown**:
- Largest peak-to-trough decline
- Measures downside risk
- Important for understanding worst-case scenarios

**Beta**:
- Sensitivity to market movements
- 1.0 = moves with market
- > 1.0 = more volatile than market
- < 1.0 = less volatile than market

### Using Analysis for Decision Making

**When evaluating performance**:
1. Compare against appropriate benchmark
2. Look at multiple time periods
3. Consider risk-adjusted returns (Sharpe ratio)
4. Analyze during different market conditions

**When rebalancing**:
1. Check allocation across different time ranges
2. Identify overweight/underweight positions
3. Consider correlation with benchmark
4. Review risk metrics

---

## Cash Account Management

### Multi-Currency Support

**Supported Currencies**:
- USD (US Dollar)
- EUR (Euro)
- GBP (British Pound)
- JPY (Japanese Yen)
- CAD (Canadian Dollar)
- AUD (Australian Dollar)
- HKD (Hong Kong Dollar)
- CNY (Chinese Yuan)
- And more

**How FX Conversion Works**:
1. Set base currency (usually USD)
2. App fetches daily FX rates
3. All values converted to base currency
4. Display shows both native and USD values

### Managing Multiple Accounts

**Best Practices**:
1. Create separate accounts for:
   - Different brokers
   - Different currencies
   - Tax accounts
   - Retirement accounts

2. Use descriptive names:
   - "Interactive Brokers USD"
   - "Charles Schwab IRA"
   - "HSBC HK Savings HKD"

3. Track cash flows between accounts using Currency Exchange transactions

---

## Tips & Best Practices

### Data Entry

#### Accuracy First
- Double-check all numbers before saving
- Use exact transaction dates
- Include fees in transaction records
- Add descriptive notes

#### Chronological Order
- Enter transactions in date order
- Critical for accurate cost basis
- Makes review and audit easier

#### Complete Records
- Include all transaction types
- Don't forget dividends and interest
- Record fees separately
- Track currency exchanges

### Portfolio Tracking

#### Regular Updates
- Record transactions immediately
- Don't let data pile up
- Review weekly for accuracy
- Sync across devices

#### Verification
- Compare app totals with broker statements
- Check cash balances match
- Verify share quantities
- Reconcile differences promptly

#### Performance Monitoring
- Review Analysis tab monthly
- Check benchmark comparisons
- Monitor risk metrics
- Identify trends and patterns

### Security

#### Authentication
- Use a strong password
- Enable two-factor authentication if available
- Don't share login credentials
- Sign out on shared devices

#### Data Backup
- Cloud sync is automatic
- Regularly export data
- Keep local backups
- Verify sync status

---

## Troubleshooting

### Common Issues

#### "Error Loading Portfolio"
**Causes**:
- Network connectivity issues
- Authentication expired
- Server temporarily unavailable

**Solutions**:
1. Check internet connection
2. Force refresh (pull down or refresh button)
3. Sign out and sign back in
4. Try again later

#### Data Not Syncing
**Causes**:
- No internet connection
- Sync disabled in settings
- Account issues

**Solutions**:
1. Enable Wi-Fi or cellular data
2. Check sync settings in Settings tab
3. Verify you're signed in
4. Force refresh from any tab

#### Incorrect Cash Balance
**Causes**:
- Missing transactions
- Incorrect transaction amounts
- Deleted transactions affecting balance

**Solutions**:
1. Review all cash transactions
2. Check transaction history for accuracy
3. Re-add any missing transactions
4. Verify deposit/withdrawal amounts

#### Missing Stocks/Positions
**Causes**:
- Stocks not registered in Stocks tab
- No transactions for the stock
- Stock was deleted

**Solutions**:
1. Check Stocks tab - register missing tickers
2. Add transactions for the stock
3. If stock was deleted, re-add and re-enter transactions

#### Prices Not Updating
**Causes**:
- Market closed (prices update during market hours)
- Network issues
- Symbol not recognized

**Solutions**:
1. Check if market is open
2. Force refresh prices
3. Verify stock symbol is correct
4. Try again during market hours

#### Can't Add Transactions
**Possible Causes**:
1. **No stocks registered**
   - Solution: Add stocks in Stocks tab first

2. **No cash accounts**
   - Solution: Add a cash account or deposit funds

3. **Form validation errors**
   - Solution: Fill all required fields
   - Check for negative values where not allowed

4. **Network issues**
   - Solution: Check internet connection

#### Historical Analysis Empty
**Causes**:
- No historical snapshots yet
- Data still syncing

**Solutions**:
1. Wait for automatic daily snapshots
2. Manually trigger analysis refresh
3. Check if you have transactions recorded
4. Verify account has permission for analysis

### Getting Help

If you continue to experience issues:

1. **Check the app version** (Settings → About)
2. **Note any error messages** (take screenshot)
3. **Describe the steps** that led to the problem
4. **Try the troubleshooting steps** above
5. **Contact support** with details

---

## Frequently Asked Questions

### General Questions

**Q: Is my data secure?**
A: Yes. All data is encrypted and stored securely in Supabase cloud. You can sign out anytime and your data remains safe.

**Q: Can I use the app offline?**
A: Yes, recently viewed data is cached locally. However, real-time prices and new transactions require internet connectivity.

**Q: How often does data sync?**
A: Data syncs automatically when you make changes and when you refresh. Prices update in real-time during market hours.

**Q: Can I access my data from multiple devices?**
A: Yes! Sign in with the same account on any device and your data will sync automatically.

**Q: What happens if I delete the app?**
A: Your data is stored in the cloud, not on the device. Reinstall the app and sign in to restore all your data.

### Portfolio Questions

**Q: How is my portfolio value calculated?**
A: Total Portfolio Value = Cash Balance + (Sum of all Holdings at Current Market Price)

**Q: What does "Today's Change" show?**
A: It shows the day's market performance excluding cash flows (deposits/withdrawals). This isolates true market movement.

**Q: How do you calculate average cost basis?**
A: We use a weighted average: (Previous Total Cost + New Purchase Cost) / Total Quantity

**Q: Why is my cost basis different from my broker?**
A: Different brokers use different methods (FIFO, LIFO, Specific ID). This app uses weighted average cost.

**Q: How are dividends handled?**
A: Dividends are recorded as both a stock transaction (dividend type) and a cash transaction (inflow), increasing your cash balance.

### Transaction Questions

**Q: Can I edit a transaction after saving?**
A: Currently, transactions cannot be edited after creation. You can delete and re-add with correct details.

**Q: What happens if I delete a transaction?**
A: The transaction is permanently removed and all related calculations (cash, holdings, cost basis) are automatically recalculated.

**Q: How far back can I record transactions?**
A: There's no limit. You can record transactions from any date in the past.

**Q: Do I need to record every transaction?**
A: Yes, for accurate tracking. Include all buys, sells, dividends, deposits, and withdrawals.

### Analysis Questions

**Q: How often is historical data updated?**
A: Historical snapshots are taken daily. Analysis data reflects your portfolio's performance over time.

**Q: Which benchmarks can I compare against?**
A: Major indices like S&P 500, NASDAQ, Dow Jones, and others. The full list is available in the Analysis tab.

**Q: How is volatility calculated?**
A: Using standard deviation of daily returns over the selected time period.

**Q: What is a good Sharpe ratio?**
A: Generally, above 1.0 is considered good, above 2.0 is very good, and above 3.0 is excellent.

### Technical Questions

**Q: What iOS versions are supported?**
A: The app supports iOS 14.0 and later.

**Q: Can I export my data?**
A: Yes, use Settings → Export Data to export your portfolio data.

**Q: How do I change my base currency?**
A: Go to Settings → Base Currency and select your preferred currency. Note: This changes display currency, not historical data.

**Q: Why do I need to sign in?**
A: Signing in enables cloud sync, allowing you to access your data from any device and never lose your information.

**Q: Can I use the app without signing in?**
A: No, authentication is required for cloud sync and data security.

---

## Quick Reference

### Transaction Types
| Type | Tab | Affects | Purpose |
|------|-----|---------|---------|
| Stock Buy | Transactions | Cash ↓, Holdings ↑ | Purchase shares |
| Stock Sell | Transactions | Cash ↑, Holdings ↓ | Sell shares |
| Stock Dividend | Transactions | Cash ↑ | Dividend income |
| Cash Deposit | Transactions | Cash ↑ | Add funds |
| Cash Withdrawal | Transactions | Cash ↓ | Remove funds |
| Cash Interest | Transactions | Cash ↑ | Interest income |
| Currency Exchange | Transactions | Between accounts | FX transfer |

### Key Metrics Formulas
```
Total Portfolio Value = Cash + Holdings Value

Today's Change = Current Value - Yesterday's Value - Today's Cash Flow

Total Gain/Loss = Current Holdings Value - Total Cost Basis

Average Cost = Total Cost Basis / Total Shares

Portfolio Return % = Total Gain/Loss / Total Cost Basis × 100
```

### Common Workflows

**Add New Stock Position**:
1. Stocks tab → Add Stock
2. Transactions tab → Add Transaction → Stock Buy
3. My Portfolio tab → Verify

**Record Dividend**:
1. Transactions tab → Add Transaction → Stock Dividend
2. Cash tab → Verify cash increase
3. My Portfolio tab → Check updated value

**Deposit Funds**:
1. Transactions tab → Add Transaction → Cash Deposit
2. Cash tab → Verify balance
3. My Portfolio tab → Check updated total

---

## Support & Feedback

### Getting Help
- Check this guide first
- Review troubleshooting section
- Try force refreshing the app
- Sign out and sign back in

### Reporting Issues
When reporting bugs, please include:
1. App version (Settings → About)
2. iOS version
3. Steps to reproduce
4. Expected vs. actual behavior
5. Screenshots if relevant

---

**Last Updated**: December 2025  
**App Version**: 1.0.0

---

*Happy Investing! 📈💰*
