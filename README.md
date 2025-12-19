# Portfolio Management System

A comprehensive personal portfolio management iOS app built with SwiftUI. Track your stocks, ETFs, cash balance, and investment transactions all in one place.

## Features

### 1. **Capital Management**
- Record an initial capital amount to establish your portfolio's starting point
- Log deposits, withdrawals, and interest earned at any time
- View your current cash balance at a glance
- Maintain a detailed history of all capital operations

### 2. **Stock Ticker Management**
- Register new stock tickers with details (name, code, market, currency)
- Edit ticker information if details change
- Remove tickers if they're delisted or no longer relevant
- Support for stocks, ETFs, and other investment instruments

### 3. **Transaction Management**
- Record daily trades: Buy, Sell, and Dividend transactions
- Automatically update holdings and cash balance with each transaction
- Track transaction details including price per unit and notes
- View transaction history filtered by ticker

### 4. **Portfolio Overview**
- See your total portfolio value at a glance
- View breakdown of cash and holdings value
- Review all current holdings with average cost basis
- Summary of capital operations and balances

## Architecture

### Project Structure

```
Portfolio-Management-System/
├── Models/
│   ├── Capital.swift          # Capital operations data model
│   ├── StockTicker.swift      # Stock/ETF ticker data model
│   ├── Transaction.swift      # Buy/Sell/Dividend transaction model
│   └── Holding.swift          # Current holdings with cost basis
├── ViewModels/
│   └── PortfolioViewModel.swift # State management & business logic
├── Views/
│   ├── ContentView.swift      # Main TabView container
│   ├── CapitalView.swift      # Capital management view
│   ├── AddCapitalOperationView.swift
│   ├── TickerManagementView.swift
│   ├── AddTickerView.swift
│   ├── EditTickerView.swift
│   ├── TransactionManagementView.swift
│   ├── AddTransactionView.swift
│   └── PortfolioOverviewView.swift
└── App Files
    └── Portfolio_Management_SystemApp.swift
```

### Data Models

#### Capital
- **Properties**: id, date, type, amount, description
- **Types**: Initial Deposit, Deposit, Withdrawal, Interest
- **Purpose**: Track all cash inflows and outflows

#### StockTicker
- **Properties**: id, name, code, market, currency, createdDate
- **Purpose**: Registry of all stocks/ETFs in your portfolio

#### Transaction
- **Properties**: id, tickerId, date, type, quantity, pricePerUnit, notes
- **Types**: Buy, Sell, Dividend
- **Purpose**: Record all investment transactions

#### Holding
- **Properties**: tickerId, quantity, averageCostPerUnit, totalCostBasis
- **Purpose**: Track current positions and cost basis

### ViewModel Pattern

`PortfolioViewModel` is the single source of truth for your portfolio data:
- Manages all CRUD operations for capitals, tickers, and transactions
- Calculates derived values (cash balance, holdings, portfolio metrics)
- Handles data persistence using UserDefaults
- Provides helper methods for queries and validations

## How to Use

### Getting Started

1. **Launch the app** - You'll see a TabView with 4 tabs
2. **Go to Capital tab** - Add your initial capital
3. **Go to Tickers tab** - Register your first stock ticker
4. **Go to Transactions tab** - Record your first buy transaction
5. **View Portfolio Overview** - See your portfolio summary

### Workflow Examples

#### Recording a Stock Purchase
1. Ensure the stock ticker is registered in "Tickers" tab
2. Go to "Transactions" tab
3. Tap "+" button
4. Select the stock ticker
5. Choose "Buy" transaction type
6. Enter quantity and price per unit
7. Tap "Save"
- Cash balance automatically decreases
- Holdings quantity increases with average cost basis updated

#### Adding Capital
1. Go to "Capital" tab
2. Tap "+" button
3. Select operation type (Deposit, Withdrawal, Interest, etc.)
4. Enter amount and optional description
5. Tap "Save"
- Current cash balance updates automatically

#### Managing Tickers
1. Go to "Tickers" tab
2. Tap on a ticker to edit, or swipe left to delete
3. Edit ticker information as needed
4. Tap "Save"

## Key Calculations

### Current Cash Balance
```
Initial Capital + Total Deposits - Total Withdrawals + Total Interest + Transaction Impact
```

### Transaction Impact on Cash
- **Buy**: Decreases cash by (quantity × pricePerUnit)
- **Sell**: Increases cash by (quantity × pricePerUnit)
- **Dividend**: Increases cash by (quantity × pricePerUnit)

### Average Cost Basis
When you buy stock, the average cost per unit is calculated as:
```
(Previous Total Cost + New Purchase Cost) / Total Quantity
```

### Total Portfolio Value
```
Current Cash Balance + (Sum of all Holdings Value)
```
where Holdings Value = quantity × averageCostPerUnit

## Data Persistence

All data is automatically saved to UserDefaults:
- Capital operations
- Stock tickers
- Transactions
- Holdings

Data persists across app launches automatically.

## Supported Currencies

- USD (US Dollar)
- EUR (Euro)
- GBP (British Pound)
- JPY (Japanese Yen)
- CAD (Canadian Dollar)
- AUD (Australian Dollar)

## Supported Markets

Any market can be added when registering tickers. Common examples:
- NASDAQ, NYSE (US)
- LSE (London Stock Exchange)
- TSE (Tokyo Stock Exchange)
- TSX (Toronto Stock Exchange)
- ASX (Australian Stock Exchange)

## Tips & Best Practices

1. **Register tickers first** - Add all your stocks before recording transactions
2. **Use descriptive notes** - Add context to transactions for future reference
3. **Check your cash balance** - Ensure it matches your actual cash position
4. **Review holdings regularly** - Use Portfolio Overview to track performance
5. **Keep accurate dates** - Transactions are sorted by date

## Future Enhancement Ideas

- Real-time stock price integration
- Unrealized gains/losses calculation
- Performance metrics and charts
- Export portfolio data
- Multiple portfolios
- Tax reporting features
- Dividend tracking and history
- Cost basis tracking for tax purposes

## Technical Details

- **Language**: Swift
- **UI Framework**: SwiftUI
- **Architecture**: MVVM (Model-View-ViewModel)
- **Data Storage**: UserDefaults with JSON encoding
- **iOS Version**: iOS 14+ (adjust as needed)

## Support

For any issues or questions about using the app:
1. Check that all required fields are filled in forms
2. Verify ticker codes don't have duplicates
3. Ensure transactions don't violate business rules (negative values, etc.)
4. Review your capital operations for accuracy
