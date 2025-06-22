````
# Coin List Screen Specification

## 1. Overview
- **Purpose**: The initial screen where users can view and select coins to trade, displaying real-time prices and indicators (MFI, RSI).
- **Target Users**: Beginner and intermediate traders.
- **Key Features**:
  - List of all coins available on Bithumb.
  - Real-time price, 24-hour change, MFI/RSI preview.
  - Search, favorites, and navigation to detailed coin view.

## 2. Functional Requirements

### 2.1 Coin List Display
- **Data per Coin**:
  - Symbol (e.g., BTC)
  - Name (e.g., Bitcoin)
  - Current price in KRW
  - 24-hour percentage change (%)
  - MFI (14 hourly candles)
  - RSI (14 hourly candles)
  - Favorite status (star icon)
- **Behavior**:
  - Fetch initial data from Bithumb API `/public/ticker/ALL`.
  - Calculate MFI/RSI using the last 14 hourly candles from `/public/candlestick/{market}/1h`.
  - Update prices and percentage changes in real-time via WebSocket `/public/ws`.
  - Update MFI/RSI hourly when a new candle closes.
  - Sort list: Favorite coins at the top, then alphabetically by symbol.

### 2.2 Search Functionality
- **Behavior**:
  - Filter coins by symbol or name (case-insensitive) as the user types.
  - Display "No coins found" if no matches.
  - Show all coins when search bar is empty.
  - Include a "Clear" button to reset the search.

### 2.3 Favorites
- **Behavior**:
  - Toggle favorite status by tapping the star icon.
  - Store favorites in UserDefaults using market codes (e.g., "KRW-BTC").
  - Favorite coins appear at the top of the list.

### 2.4 Coin Selection
- **Behavior**:
  - Tapping a coin row (except the star) navigates to the main screen.
  - Pass the selected coin’s market code (e.g., "KRW-BTC") to load detailed data.

### 2.5 Real-Time Updates
- **Behavior**:
  - Use WebSocket for real-time price and percentage change updates.
  - Update MFI/RSI every hour in the background.
  - Ensure updates don’t disrupt the UI (e.g., use diffable data source).

### 2.6 Error Handling
- **Behavior**:
  - If data fetch fails: Show "Unable to load coin list. Check your connection and try again." with a "Retry" button.
  - If WebSocket fails: Auto-reconnect silently.

### 2.7 Loading States
- **Behavior**:
  - Show a loading indicator (e.g., ProgressView) during initial data fetch.
  - Display "MFI: --" and "RSI: --" as placeholders while indicators are calculated.
  - Replace placeholders with values once calculated.

## 3. UI/UX Requirements
- **Theme**: Dark mode with white text.
- **Layout**:
  - **Navigation Bar**: Title "Coin List".
  - **Search Bar**: Fixed at the top, always visible.
  - **Coin Row**:
    - **Left**: Symbol (bold), Name (regular).
    - **Right**: Price (bold), 24h Change (smaller, green if positive, red if negative).
    - **Below**: "MFI: [value]" and "RSI: [value]" (smaller font, color-coded).
    - **Far Right**: Star icon (filled if favorite, outlined if not).
  - Subtle divider lines between rows.
- **Color Coding**:
  - MFI: Green (≤20), Red (≥80), White (else).
  - RSI: Green (≤30), Red (≥70), White (else).
- **Typography**: System font, bold for symbol/price, regular elsewhere.
- **Spacing**: 10pt padding between elements, 60pt row height.

## 4. Performance Requirements
- **Initial Load**: Display basic info (symbol, name, price, change) quickly, calculate indicators asynchronously.
- **Real-Time Updates**: Efficiently update only changed items.
- **Scalability**: Handle hundreds of coins without lag (no pagination unless API limits require it).

## 5. Data Model
```swift
struct Coin: Identifiable {
    let id = UUID()
    let market: String  // e.g., "KRW-BTC"
    let symbol: String  // e.g., "BTC"
    let name: String    // e.g., "Bitcoin"
    var price: Double
    var changePercent: Double
    var mfi: Double?
    var rsi: Double?
    var isFavorite: Bool
}
```

## 6. API & WebSocket Integration
- **Initial Fetch**: `/public/ticker/ALL` for all coin data.
- **Indicators**: `/public/candlestick/{market}/1h` for 14 hourly candles.
- **Real-Time**: WebSocket `/public/ws` for price updates.

## 7. Developer Notes
- **SwiftUI**: Use `@State` or `@ObservedObject` for coin list, `NavigationLink` for main screen navigation.
- **Async**: Calculate MFI/RSI in background threads, update UI via main thread.
- **Optimization**: Use diffable data source for efficient list updates.

## 8. Designer Notes
- **Color Palette**:
  - Background: #121212
  - Text: #FFFFFF
  - Positive Change: #00FF00
  - Negative Change: #FF0000
- **Visual Feedback**: Highlight row on tap, subtle animation for favorite toggle.

This specification provides a clear blueprint for implementing the coin list screen with all necessary details.
````