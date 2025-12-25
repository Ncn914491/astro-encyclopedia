# Search & Explore Feature - Testing Guide

## 🧪 Manual Testing Checklist

### 1. **Navigation to Search Screen**

#### Test Case 1.1: Open Search from Home
- [ ] Open the app
- [ ] Tap the search icon (🔍) in the AppBar
- [ ] **Expected**: Navigate to SearchScreen
- [ ] **Expected**: Search field is auto-focused (keyboard appears)
- [ ] **Expected**: Empty state shows "Popular Categories"

---

### 2. **Empty State Testing**

#### Test Case 2.1: Popular Categories Display
- [ ] Open search screen
- [ ] **Expected**: See "Popular Categories" header
- [ ] **Expected**: See 6 category chips:
  - 🪐 Planets (Blue)
  - 🌌 Galaxies (Purple)
  - ✨ Nebulae (Pink)
  - ⭐ Stars (Amber)
  - 🕳️ Black Holes (Grey)
  - 🌙 Moon (Blue Grey)

#### Test Case 2.2: Category Chip Interaction
- [ ] Tap "Planets" chip
- [ ] **Expected**: Search field updates to "Planets"
- [ ] **Expected**: Search executes after 500ms
- [ ] **Expected**: Results appear (or loading state)

#### Test Case 2.3: Recent Searches Placeholder
- [ ] Open search screen
- [ ] **Expected**: See "Recent Searches" section
- [ ] **Expected**: See placeholder text and history icon

---

### 3. **Search Input Testing**

#### Test Case 3.1: Basic Text Input
- [ ] Type "Mars" in search field
- [ ] **Expected**: Text appears in field
- [ ] **Expected**: Clear button (X) appears
- [ ] **Expected**: No search triggered yet (debouncing)

#### Test Case 3.2: Debouncing (500ms)
- [ ] Type "M"
- [ ] Wait 200ms
- [ ] Type "a"
- [ ] Wait 200ms
- [ ] Type "r"
- [ ] **Expected**: No API call yet
- [ ] Wait 500ms
- [ ] **Expected**: Loading state appears
- [ ] **Expected**: Single API call to `/lookup?q=Mar`

#### Test Case 3.3: Clear Button
- [ ] Type "Jupiter"
- [ ] Tap the clear button (X)
- [ ] **Expected**: Search field clears
- [ ] **Expected**: Results clear
- [ ] **Expected**: Empty state returns
- [ ] **Expected**: Clear button disappears

---

### 4. **Loading State Testing**

#### Test Case 4.1: Loading Indicator
- [ ] Type "Saturn" and wait 500ms
- [ ] **Expected**: Circular progress indicator appears
- [ ] **Expected**: Text "Searching the universe..." appears
- [ ] **Expected**: Centered on screen

---

### 5. **Online Search Results Testing**

#### Test Case 5.1: Successful Search (Online)
- [ ] Ensure device has internet connection
- [ ] Type "Earth" and wait 500ms
- [ ] **Expected**: Loading state appears
- [ ] **Expected**: Results appear within 15 seconds
- [ ] **Expected**: Result count header shows (e.g., "1 result for 'Earth'")
- [ ] **Expected**: No "Local" badge visible

#### Test Case 5.2: Result Card Display
- [ ] Search for "Mars"
- [ ] **Expected**: Result card shows:
  - Thumbnail image (100x100px, left side)
  - Type badge (e.g., "🪐 PLANET" in blue)
  - Title "Mars" in white, bold
  - Description preview (if available)
  - Forward arrow (right side)

#### Test Case 5.3: Result Card Interaction
- [ ] Search for "Venus"
- [ ] Tap the result card
- [ ] **Expected**: Navigate to `/details/venus`
- [ ] **Expected**: Details screen appears (or placeholder)

#### Test Case 5.4: Multiple Results
- [ ] Search for "Galaxy"
- [ ] **Expected**: Multiple result cards appear
- [ ] **Expected**: Scrollable list
- [ ] **Expected**: Each card is distinct

---

### 6. **Offline Mode Testing**

#### Test Case 6.1: Offline Detection
- [ ] Turn off WiFi and mobile data
- [ ] Type "Moon" and wait 500ms
- [ ] **Expected**: Loading state appears briefly
- [ ] **Expected**: Orange "Offline" chip appears in AppBar
- [ ] **Expected**: Results from local library appear
- [ ] **Expected**: "Local" badge appears in results header

#### Test Case 6.2: Offline Search Filtering
- [ ] Stay offline
- [ ] Type "Earth"
- [ ] **Expected**: Local objects filtered by "earth" in title/type/id
- [ ] **Expected**: Results appear instantly (no network delay)

#### Test Case 6.3: No Local Results
- [ ] Stay offline
- [ ] Type "XYZ123NonExistent"
- [ ] **Expected**: Error state appears
- [ ] **Expected**: Message: "No local results found for 'XYZ123NonExistent'"
- [ ] **Expected**: Retry button visible

#### Test Case 6.4: Offline Banner
- [ ] Stay offline
- [ ] Open search screen
- [ ] **Expected**: Orange banner at top of empty state
- [ ] **Expected**: Text: "Offline Mode: Searching local library only"
- [ ] **Expected**: WiFi-off icon visible

---

### 7. **Caching Testing**

#### Test Case 7.1: Cache New Results
- [ ] Go online
- [ ] Search for "Andromeda"
- [ ] **Expected**: Result appears from API
- [ ] Go offline
- [ ] Search for "Andromeda" again
- [ ] **Expected**: Result still appears (from Hive cache)

#### Test Case 7.2: Cache Persistence
- [ ] Go online
- [ ] Search for "Orion"
- [ ] Close app completely
- [ ] Reopen app
- [ ] Go offline
- [ ] Search for "Orion"
- [ ] **Expected**: Result appears from cache

---

### 8. **Error Handling Testing**

#### Test Case 8.1: Network Timeout
- [ ] Use slow/unstable connection
- [ ] Search for "Neptune"
- [ ] **Expected**: If timeout (15s), error state appears
- [ ] **Expected**: Fallback to offline mode
- [ ] **Expected**: Retry button available

#### Test Case 8.2: Retry Functionality
- [ ] Trigger an error (go offline, search)
- [ ] Tap "Retry" button
- [ ] **Expected**: Search re-executes
- [ ] **Expected**: Loading state appears

#### Test Case 8.3: API Error (404)
- [ ] Search for something that returns 404
- [ ] **Expected**: Error state appears
- [ ] **Expected**: Fallback to offline search

---

### 9. **UI/UX Testing**

#### Test Case 9.1: Dark Theme Consistency
- [ ] Open search screen
- [ ] **Expected**: Background color is `#0B0D17`
- [ ] **Expected**: Cards are `#1A1D2E`
- [ ] **Expected**: Text is white/white70

#### Test Case 9.2: Type Badge Colors
- [ ] Search for different types
- [ ] **Expected**: Planet = Blue (`0xFF42A5F5`)
- [ ] **Expected**: Star = Amber (`0xFFFFD54F`)
- [ ] **Expected**: Galaxy = Purple (`0xFF7C4DFF`)
- [ ] **Expected**: Nebula = Pink (`0xFFE91E63`)

#### Test Case 9.3: Smooth Animations
- [ ] Type and clear search multiple times
- [ ] **Expected**: Smooth transitions between states
- [ ] **Expected**: No jank or lag

#### Test Case 9.4: Keyboard Behavior
- [ ] Open search screen
- [ ] **Expected**: Keyboard auto-opens
- [ ] Tap outside search field
- [ ] **Expected**: Keyboard dismisses
- [ ] Tap search field again
- [ ] **Expected**: Keyboard re-opens

---

### 10. **Edge Cases Testing**

#### Test Case 10.1: Empty Query
- [ ] Type "   " (spaces only)
- [ ] **Expected**: No search triggered
- [ ] **Expected**: Empty state remains

#### Test Case 10.2: Very Long Query
- [ ] Type a 100+ character query
- [ ] **Expected**: Search executes
- [ ] **Expected**: No UI overflow
- [ ] **Expected**: Text truncates gracefully

#### Test Case 10.3: Special Characters
- [ ] Type "M@rs!" 
- [ ] **Expected**: Search executes
- [ ] **Expected**: No crashes
- [ ] **Expected**: Results or no results message

#### Test Case 10.4: Rapid Typing
- [ ] Type "abcdefghijklmnop" very quickly
- [ ] **Expected**: Only ONE API call after 500ms
- [ ] **Expected**: Debouncing works correctly

#### Test Case 10.5: Back Navigation
- [ ] Search for "Jupiter"
- [ ] Tap a result
- [ ] Press back button
- [ ] **Expected**: Return to search screen
- [ ] **Expected**: Search query still in field
- [ ] **Expected**: Results still visible

---

## 🎯 Performance Benchmarks

### Timing Tests:
- [ ] **Debounce Delay**: Verify exactly 500ms delay
- [ ] **Network Timeout**: Verify 15s timeout triggers
- [ ] **Local Search**: Should be < 100ms
- [ ] **Screen Load**: Should be < 1s

### Memory Tests:
- [ ] Search 10+ different queries
- [ ] **Expected**: No memory leaks
- [ ] **Expected**: Smooth performance

---

## 🐛 Known Issues / Limitations

- Recent searches not yet persisted (placeholder only)
- No search suggestions/autocomplete
- No advanced filters
- Single result per query (Worker limitation)

---

## ✅ Sign-Off Checklist

- [ ] All navigation tests pass
- [ ] All empty state tests pass
- [ ] All search input tests pass
- [ ] All loading state tests pass
- [ ] All online search tests pass
- [ ] All offline mode tests pass
- [ ] All caching tests pass
- [ ] All error handling tests pass
- [ ] All UI/UX tests pass
- [ ] All edge case tests pass
- [ ] Performance benchmarks met
- [ ] No crashes or ANRs
- [ ] Build succeeds (`flutter build apk`)
- [ ] Analysis passes (`flutter analyze`)

---

**Tester**: _______________  
**Date**: _______________  
**Build Version**: _______________  
**Device**: _______________  
**OS Version**: _______________  

**Overall Status**: [ ] PASS / [ ] FAIL  
**Notes**: _______________________________________________
