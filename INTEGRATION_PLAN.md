# iOS App → Supabase Backend Integration Plan

## Current Analysis

### Web App (Supabase Backend)
**Technology**: React + TypeScript + Supabase (PostgreSQL)
**Authentication**: Supabase Auth (JWT tokens)
**Database**: PostgreSQL with RLS (Row Level Security)

**Key Tables**:
- `user_portfolio_settings` - Base currency settings per user
- `portfolio_cash_accounts` - Cash accounts per currency
- `transaction_groups` - Wrapper for multi-leg transactions
- `cash_transactions` - Cash transaction legs (deposits, withdrawals, FX, etc.)
- `stock_transactions` - Stock trades (buy/sell/dividend)
- `portfolio_positions` - Running position snapshots
- `stocks_master` - Stock ticker master data
- `historical_prices` - Historical price data
- `portfolio_holdings` - User holdings with cost basis

### Current iOS App (Local UserDefaults)
**Technology**: SwiftUI + UserDefaults
**Models**:
- `Capital` - Simple capital operations (initial deposit, deposit, withdrawal, interest)
- `StockTicker` - Basic ticker info (name, code, market, currency)
- `Transaction` - Simple buy/sell/dividend
- `Holding` - Basic holdings with average cost

## Schema Mapping

### iOS Model → Supabase Table Mapping

| iOS Model | Supabase Tables | Notes |
|-----------|----------------|-------|
| `Capital` | `cash_transactions` + `transaction_groups` | Web app uses multi-leg transaction system |
| `StockTicker` | `stocks_master` or `stocks` | Web has richer stock metadata |
| `Transaction` | `stock_transactions` + `cash_transactions` + `transaction_groups` | Web uses double-entry system |
| `Holding` | `portfolio_positions` + `portfolio_holdings` | Web tracks positions with snapshots |

### Key Differences

**Web App (More Complex)**:
1. **Multi-currency support** - Separate cash accounts per currency
2. **Double-entry accounting** - Transaction groups with multiple legs
3. **FX tracking** - Foreign exchange rates and conversions
4. **Cost basis tracking** - Detailed lot-level tracking
5. **Realized P&L** - Profit/loss calculations on sales
6. **Transaction status** - Pending/Settled/Void states
7. **Settlement dates** - Trade date vs settlement date

**iOS App (Simpler)**:
1. Single-currency assumption
2. Simple transaction model
3. Basic average cost calculation
4. No FX support
5. No transaction status tracking

## Integration Strategy

### Option 1: Full Migration (Recommended)
**Redesign iOS models to match Supabase schema exactly**
- Pros: Full feature parity, consistent data model
- Cons: More complex, requires significant refactoring

### Option 2: Simplified API Layer
**Keep simple iOS models, map to/from Supabase on API calls**
- Pros: Simpler iOS code, gradual migration
- Cons: Feature limitations, mapping complexity

### Option 3: Hybrid Approach (Best Balance)
**Keep iOS models simple, use Supabase views/functions for aggregation**
- Pros: Best of both worlds, clean separation
- Cons: Requires backend views/functions

## Recommended Implementation Plan

### Phase 1: Authentication & Setup
1. Add Supabase Swift SDK to iOS project
2. Implement authentication flow (email/password, social login)
3. Store JWT tokens securely in Keychain
4. Create API client wrapper for Supabase calls

### Phase 2: Read-Only Integration
1. Fetch user's existing portfolio data from Supabase
2. Map complex Supabase schema → Simple iOS models
3. Display data in existing iOS UI (no changes needed)
4. Cache data locally for offline viewing

### Phase 3: Write Operations
1. Map iOS transactions → Supabase transaction groups
2. Handle multi-leg transaction creation
3. Update portfolio positions automatically
4. Sync local cache with remote data

### Phase 4: Advanced Features
1. Multi-currency support (optional)
2. Real-time price updates
3. Push notifications
4. Conflict resolution for offline edits

## Technical Implementation

### 1. Add Dependencies

**Package.swift** or **SPM**:
```swift
dependencies: [
    .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0")
]
```

### 2. Create Supabase Models (Matching DB Schema)

```swift
// Models/API/SupabaseModels.swift

struct SupabaseStockTransaction: Codable {
    let id: UUID
    let userId: UUID
    let groupId: UUID
    let stockId: UUID
    let symbol: String
    let tradeType: String // buy, sell, dividend
    let tradeDate: Date
    let quantity: Decimal
    let pricePerShare: Decimal
    let grossAmount: Decimal
    let fees: Decimal
    let currency: String
    let fxRate: Decimal
    // ... etc
}

struct SupabaseCashTransaction: Codable {
    let id: UUID
    let userId: UUID
    let groupId: UUID
    let cashAccountId: UUID
    let legType: String
    let direction: String
    let amount: Decimal
    let currency: String
    // ... etc
}

struct SupabaseTransactionGroup: Codable {
    let id: UUID
    let userId: UUID
    let groupType: String
    let status: String
    let occurredAt: Date
    let notes: String?
}
```

### 3. Create API Client

```swift
// Services/SupabaseClient.swift

import Supabase

class SupabaseClient {
    static let shared = SupabaseClient()
    
    private let client: SupabaseClient
    
    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "YOUR_SUPABASE_URL")!,
            supabaseKey: "YOUR_SUPABASE_ANON_KEY"
        )
    }
    
    // Auth
    func signIn(email: String, password: String) async throws -> Session
    func signOut() async throws
    func getCurrentUser() async throws -> User?
    
    // Transactions
    func fetchTransactions() async throws -> [SupabaseTransactionGroup]
    func createTransaction(_ transaction: Transaction) async throws
    
    // Positions
    func fetchPositions() async throws -> [SupabasePosition]
    
    // Cash Accounts
    func fetchCashAccounts() async throws -> [SupabaseCashAccount]
}
```

### 4. Create Mapper Layer

```swift
// Services/DataMapper.swift

class SupabaseDataMapper {
    // Map Supabase → iOS models
    static func mapToTransaction(_ supabase: SupabaseTransactionGroup) -> Transaction {
        // Logic to flatten complex transaction group into simple Transaction
    }
    
    static func mapToHolding(_ position: SupabasePosition) -> Holding {
        // Map portfolio_positions to Holding
    }
    
    // Map iOS → Supabase models
    static func mapToSupabaseTransaction(_ transaction: Transaction) -> (
        group: SupabaseTransactionGroup,
        stockTx: SupabaseStockTransaction?,
        cashTx: SupabaseCashTransaction?
    ) {
        // Logic to expand simple Transaction into transaction group with legs
    }
}
```

### 5. Update ViewModel to Use API

```swift
// ViewModels/PortfolioViewModel.swift

class PortfolioViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var syncStatus: SyncStatus = .offline
    
    private let supabaseClient = SupabaseClient.shared
    private let localStorage = LocalStorageService.shared
    
    // Fetch from Supabase
    func syncWithBackend() async {
        isLoading = true
        syncStatus = .syncing
        
        do {
            // Fetch from Supabase
            let supabaseGroups = try await supabaseClient.fetchTransactions()
            
            // Map to iOS models
            let mappedTransactions = supabaseGroups.map { 
                SupabaseDataMapper.mapToTransaction($0) 
            }
            
            // Update local state
            await MainActor.run {
                self.transactions = mappedTransactions
                self.syncStatus = .synced
            }
            
            // Cache locally
            localStorage.save(transactions: mappedTransactions)
            
        } catch {
            syncStatus = .error(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    // Create transaction (sync to backend)
    func addTransaction(_ transaction: Transaction) async throws {
        // Map to Supabase format
        let (group, stockTx, cashTx) = SupabaseDataMapper.mapToSupabaseTransaction(transaction)
        
        // Create on backend
        try await supabaseClient.createTransactionGroup(group, stockTx: stockTx, cashTx: cashTx)
        
        // Update local state
        transactions.append(transaction)
        
        // Refresh positions
        try await syncWithBackend()
    }
}
```

## Data Flow Diagrams

### Read Flow (Fetch Portfolio)
```
User Opens App
    ↓
Check Auth (Supabase JWT)
    ↓
Fetch transaction_groups + joined tables
    ↓
Map complex schema → Simple iOS models
    ↓
Update @Published properties
    ↓
SwiftUI renders UI
    ↓
Cache locally (offline support)
```

### Write Flow (Create Transaction)
```
User adds transaction in iOS
    ↓
Create simple Transaction model
    ↓
Map to Supabase schema:
  - transaction_groups (wrapper)
  - stock_transactions (if stock trade)
  - cash_transactions (cash leg)
    ↓
POST to Supabase via API
    ↓
Supabase triggers update portfolio_positions
    ↓
Fetch updated positions
    ↓
Update iOS UI
```

## Authentication Flow

```swift
// Views/LoginView.swift

struct LoginView: View {
    @StateObject private var authManager = AuthenticationManager()
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack {
            TextField("Email", text: $email)
            SecureField("Password", text: $password)
            
            Button("Sign In") {
                Task {
                    try await authManager.signIn(email: email, password: password)
                }
            }
        }
    }
}

// Services/AuthenticationManager.swift

class AuthenticationManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    func signIn(email: String, password: String) async throws {
        let session = try await SupabaseClient.shared.signIn(email: email, password: password)
        
        // Store JWT securely
        try KeychainHelper.save(token: session.accessToken)
        
        await MainActor.run {
            self.currentUser = session.user
            self.isAuthenticated = true
        }
    }
}
```

## Migration Path

### Step 1: Keep Both Systems Running
- iOS app continues using UserDefaults
- Add "Sync to Cloud" button
- User can manually trigger sync

### Step 2: Gradual Migration
- On first sync, upload all local data to Supabase
- Mark local data as "synced"
- New transactions go to both local + cloud

### Step 3: Cloud-First
- Switch to cloud-first mode
- Local storage becomes cache only
- Offline changes sync when online

## Security Considerations

1. **JWT Storage**: Store in Keychain, not UserDefaults
2. **API Keys**: Use environment variables, not hardcoded
3. **RLS Policies**: Supabase already has user_id-based RLS
4. **HTTPS Only**: All API calls over HTTPS
5. **Token Refresh**: Implement automatic token refresh

## Next Steps

1. **Review web app API endpoints** - Are there REST endpoints or only direct DB access?
2. **Confirm Supabase URL & keys** - Get from .env file
3. **Decide on integration approach** - Full migration vs hybrid
4. **Start with auth implementation** - Get login working first

Would you like me to proceed with implementing the Supabase integration? I can start with:
1. Adding Supabase SDK to the iOS project
2. Creating the API client layer
3. Implementing authentication flow
4. Or any other specific part you'd like to focus on first?
