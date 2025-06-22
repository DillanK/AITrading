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
- **SwiftData**: Primary data persistence layer using `@Model` classes
- **Combine**: Reactive programming for search functionality and async operations
- **Alamofire**: HTTP networking library for API calls

### Key Directories
- `Models/`: Data models (`Coin`, `BithumbTickerResponse`, `Item`)
- `Views/`: SwiftUI views (`CoinListView`, `ContentView`)
- `ViewModels/`: Business logic (`CoinListViewModel`)
- `Services/`: API and network services (`BithumbAPI`)
- `MockData/`: Test data generators (`MockCoinData`)

### Data Flow
1. `CoinListViewModel` manages coin data and search state
2. Uses `BithumbAPI` for fetching real-time data (currently stubbed)
3. `MockCoinData` provides test data during development
4. SwiftData handles persistence with `ModelContainer` and `ModelContext`
5. Views observe ViewModels using `@StateObject` and `@Published`

### Key Patterns
- **Dependency Injection**: `ModelContainer` injected via environment
- **Error Handling**: ViewModels expose `errorMessage` and `isLoading` state
- **Search**: Debounced search with Combine publishers
- **Favorites**: Toggle functionality with SwiftData persistence
- **Async/Await**: Modern Swift concurrency in API calls

### Current State
- API integration is partially implemented (stubbed in `BithumbAPI`)
- Using mock data for development
- Basic UI established with coin list, search, and favorites
- SwiftData models configured for persistence

### Dependencies
- Alamofire 5.10.2 for networking
- SwiftData for data persistence
- Combine for reactive programming