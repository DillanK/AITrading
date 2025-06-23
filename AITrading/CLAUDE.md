# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Building and Running
- Open project: `open AITrading.xcodeproj`
- Build via Xcode: Cmd+B
- Run via Xcode: Cmd+R
- Run tests: Cmd+U

### Xcode Command Line Tools
- Build from command line: `xcodebuild -project AITrading.xcodeproj -scheme AITrading build`
- Run tests from command line: `xcodebuild -project AITrading.xcodeproj -scheme AITrading test`

## Architecture Overview

This is a SwiftUI-based iOS cryptocurrency trading application with the following architecture:

### Core Components
- **MVVM Pattern**: Views use ViewModels for business logic, with Models for data representation
- **SwiftData + CloudKit**: Primary data persistence layer using `@Model` classes with iCloud synchronization
- **Combine**: Reactive programming for search functionality and async operations
- **Alamofire**: HTTP networking library for API calls

### Key Directories
- `Models/`: Data models (`Coin`, `TradingStrategy`, `Candle`, `CandleDataModel`, `Item`)
- `Views/`: SwiftUI views (`CoinListView`, `TradingStrategyView`, `MainChartView`, `BacktestDataView`, `CollectedDataView`)
- `ViewModels/`: Business logic (`CoinListViewModel`, `TradingStrategyViewModel`, `MainChartViewModel`)
- `Services/`: API and network services (`BithumbAPI`, `BacktestDataService`)
- `MockData/`: Test data generators (`MockCoinData`)
- `Utils/`: Utility classes (`TechnicalIndicators`)

### Data Flow
1. `CoinListViewModel` manages coin data and search state with cache-first loading
2. Uses `BithumbAPI` for fetching real-time data (currently stubbed)
3. `MockCoinData` provides test data during development
4. SwiftData handles persistence with CloudKit synchronization
5. Views observe ViewModels using `@StateObject` and `@Published`
6. Background data refresh preserves user favorites and preferences

### Key Patterns
- **Dependency Injection**: `ModelContainer` injected via environment
- **Error Handling**: ViewModels expose `errorMessage` and `isLoading` state
- **Search**: Debounced search with Combine publishers
- **Favorites**: Toggle functionality with SwiftData persistence
- **Async/Await**: Modern Swift concurrency in API calls
- **Cache-First Loading**: Show cached data immediately, refresh in background
- **CloudKit Integration**: Automatic data synchronization across devices

## Current Features

### ✅ Implemented Features
1. **Coin List Management**
   - Cache-first data loading with background refresh
   - Real-time price display with change indicators
   - Favorites system with heart icon toggle
   - Search functionality with debounced input
   - Pull-to-refresh and manual refresh options

2. **Data Persistence & Sync**
   - SwiftData integration with CloudKit synchronization
   - Cross-device data sync for favorites and preferences
   - Offline data caching with graceful fallback

3. **Trading Strategy System**
   - Multiple technical indicators (MFI, RSI, MACD)
   - Strategy templates (Conservative, Aggressive, Combined)
   - Customizable buy/sell thresholds and parameters
   - Risk management with stop-loss and take-profit settings

4. **Backtesting Infrastructure**
   - Historical candle data collection from Upbit API
   - 1-minute resolution OHLCV data storage
   - Background data collection with progress tracking

5. **Technical Analysis**
   - MFI (Money Flow Index) calculation
   - RSI (Relative Strength Index) calculation  
   - MACD (Moving Average Convergence Divergence) calculation
   - Configurable periods for all indicators

6. **User Interface**
   - Modern SwiftUI design with gradient backgrounds
   - Loading states with progress indicators
   - Error handling with retry mechanisms
   - Responsive layout for different screen sizes

### 🚧 Partially Implemented
- **API Integration**: Bithumb API structure ready but using mock data
- **Chart Visualization**: Basic mini charts, full chart view in progress
- **Real-time Updates**: Framework ready, live data pending API completion

### Dependencies
- Alamofire 5.10.2 for networking
- SwiftData for data persistence with CloudKit
- Combine for reactive programming

---

## Development History

### 2025-06-23 23:30 - CloudKit Integration & Cache-First Loading
**Added:**
- CloudKit integration for SwiftData models
- Cache-first loading strategy in CoinListViewModel
- Background data refresh while showing cached data
- Enhanced UI states (loading, refreshing, error, empty)
- Favorite button with animation in coin rows
- Manual refresh functionality

**Modified Files:**
- `AITradingApp.swift`: Added CloudKit database configuration
- `Models/`: Added `@Attribute(.unique)` to all model IDs for CloudKit sync
- `CoinListViewModel.swift`: Implemented cache-first loading and background refresh
- `CoinListView.swift`: Enhanced UI with multiple loading states and refresh button

**Technical Details:**
- ModelConfiguration now includes `cloudKitDatabase: .private("iCloud.com.beakbig.ai.trading")`
- All SwiftData models have unique attributes for CloudKit record management
- Cache-first pattern: show stored data immediately → refresh in background → update UI
- Favorites state preserved during data updates

### 2025-06-24 00:15 - Fixed Backtest Data Storage Issues
**Fixed:**
- CandleDataModel missing `@Attribute(.unique)` for CloudKit sync
- BacktestDataService using incorrect Bithumb API URL instead of Upbit
- Predicate syntax errors in Swift 6 concurrency model
- Duplicate data checking approach optimized for CloudKit

**Modified Files:**
- `Models/CandleData.swift`: Added missing `@Attribute(.unique)` to ID field
- `Services/BacktestDataService.swift`: Fixed API URL and removed complex duplicate checking

**Technical Details:**
- Changed API base URL from `https://api.bithumb.com/v1` to `https://api.upbit.com/v1`
- Removed manual duplicate checking in favor of CloudKit's unique constraint handling
- Fixed Swift 6 Sendable compliance issues with Predicate usage
- Data storage now relies on CloudKit's built-in duplicate prevention