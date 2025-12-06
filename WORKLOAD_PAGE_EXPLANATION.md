# Workload Page - Complete Working Explanation

## 📋 Overview
The Workload page displays a grid-based view of team members' assigned task hours over a configurable date range (7, 14, or 30 days). It shows daily scheduled hours per team member and allows filtering, searching, and task management.

---

## 🏗️ Architecture & Data Flow

### 1. **Component Structure**
```
TeamDetailPage (StatefulWidget)
  └── _buildWorkloadTab()
      └── Consumer<DashboardProvider> ← Listens to provider changes
          ├── Gets team data from provider.teams
          ├── Gets members from provider.allUsers
          ├── Gets tasks from provider.tasks
          └── Builds UI with filtered/processed data
```

### 2. **Data Sources**
- **Teams**: `provider.teams` (from `TeamController.fetchTeams()`)
- **Users/Members**: `provider.allUsers` (from `TeamController.fetchUsers()`)
- **Tasks**: `provider.tasks` (from `TaskController.fetchTasks()`)

### 3. **Data Flow Path**
```
User Action → DashboardProvider → TaskController → FirebaseService → Firestore
                                                              ↓
UI Update ← notifyListeners() ← DashboardProvider ← TaskController ← Firestore Response
```

---

## 🔄 How It Currently Works

### **Step-by-Step Process:**

1. **Initial Load** (`_buildWorkloadTab`)
   - Uses `Consumer<DashboardProvider>` to listen to provider state
   - Gets team: `provider.teams.firstWhere((t) => t.id == widget.teamId)`
   - Gets members: Maps `team.memberIds` to `UserModel` objects from `provider.allUsers`
   - Gets tasks: Filters `provider.tasks` where `task.assignedTo` matches team member IDs

2. **Data Filtering** (`_filterWorkloadTasks`)
   - Applies priority filter (if set)
   - Applies status filter (if set)
   - Applies project filter (if set)
   - Filters out closed tasks if `_workloadShowClosed == false`

3. **Search Filtering**
   - If search query exists, filters tasks by title/description containing query

4. **Date Range Calculation** (`_generateDates`)
   - Calculates days to show based on `_workloadView` ('7 days', '14 days', '30 days')
   - Generates list of `DateTime` objects for the date range

5. **Grid Rendering** (`_buildWorkloadGrid`)
   - **Left Sidebar**: Shows assignees (unassigned + team members) with total hours/capacity
   - **Main Grid**: Shows daily hours for each member across date columns
   - **Right Sidebar**: Shows task list (Unscheduled, No estimate, Overdue tabs)

6. **Hour Calculation** (`_calculateHoursForDate`)
   - For each date cell, calculates total hours from tasks assigned to that member
   - Uses task `estimatedHours` or `estimatedDays` based on `_workloadTimeEstimate` setting
   - Sums hours for all tasks assigned to the member on that date

7. **UI Updates**
   - When filters change → `setState()` → Rebuilds widget tree
   - When date range changes → `setState()` → Recalculates dates and rebuilds grid
   - When provider updates → `Consumer` automatically rebuilds

---

## ⚠️ **Current Limitation: NOT Real-Time**

### **How Data is Currently Loaded:**

```dart
// DashboardProvider.refreshTasks()
Future<void> refreshTasks() async {
  await _loadTasks();  // One-time fetch
  notifyListeners();
}

// TaskController.fetchTasks()
Future<List<TaskModel>> fetchTasks() => _service.fetchTasks();

// FirebaseService.fetchTasks()
Future<List<TaskModel>> fetchTasks() async {
  final snapshot = await _tasksCol.orderBy('dueDate').get(); // ← ONE-TIME FETCH
  // Process snapshot...
  return tasks;
}
```

### **What This Means:**
- ❌ **No automatic updates** when tasks change in Firebase
- ❌ **No real-time sync** between multiple users
- ✅ **Manual refresh** available via "Today" dropdown → "Refresh" button
- ✅ **Updates on navigation** (when you switch tabs and come back)

---

## 🔴 **What's Missing for Real-Time Updates**

### **Current Implementation:**
```dart
// FirebaseService.fetchTasks() - ONE-TIME FETCH
final snapshot = await _tasksCol.orderBy('dueDate').get();
```

### **What's Needed for Real-Time:**

1. **Replace `.get()` with `.snapshots()` Stream**
   ```dart
   // FirebaseService.fetchTasksStream()
   Stream<List<TaskModel>> fetchTasksStream() {
     return _tasksCol
       .orderBy('dueDate')
       .snapshots()  // ← STREAM instead of .get()
       .map((snapshot) => snapshot.docs
         .map((doc) => TaskModel.fromSnapshot(doc))
         .toList());
   }
   ```

2. **Set Up Stream Subscription in DashboardProvider**
   ```dart
   StreamSubscription<List<TaskModel>>? _tasksSubscription;
   
   void _setupTasksListener() {
     _tasksSubscription?.cancel();
     _tasksSubscription = _taskController.fetchTasksStream().listen(
       (tasks) {
         this.tasks = tasks;
         notifyListeners(); // ← Auto-update UI
       },
       onError: (error) {
         lastError = error.toString();
         notifyListeners();
       },
     );
   }
   ```

3. **Initialize in `initialize()` Method**
   ```dart
   Future<void> initialize() async {
     // ... existing code ...
     _setupTasksListener(); // ← Add this
   }
   ```

4. **Clean Up on Dispose**
   ```dart
   @override
   void dispose() {
     _tasksSubscription?.cancel();
     super.dispose();
   }
   ```

---

## 🎯 **Key Features & Interactions**

### **1. Date Range Navigation**
- **Left/Right Arrows**: Navigate previous/next period
- **"Today" Button**: Jump to current date
- **Dropdown**: Change view (7/14/30 days)

### **2. Filtering**
- **Priority Filter**: Filter by task priority
- **Status Filter**: Filter by task status
- **Project Filter**: Filter by project/template
- **Closed Tasks Toggle**: Show/hide completed tasks

### **3. Grouping**
- **Group By**: Assignee, Project, or Status
- Changes how tasks are organized in the grid

### **4. Time Estimates**
- **Hours/Days**: Toggle between hours and days display
- Affects how capacity is calculated (40h vs 5d)

### **5. Task Management**
- **+ Button**: Add new task for member on specific date
- **- Button**: Remove scheduled hours (TODO: not fully implemented)
- **Task Sidebar**: View unscheduled, no estimate, or overdue tasks

### **6. Search**
- **Search Icon**: Toggle search bar
- **Search Query**: Filter tasks by title/description

---

## 📊 **Hour Calculation Logic**

### **How Hours Are Calculated:**

```dart
int _calculateHoursForDate(String name, UserModel? member, DateTime date, List<TaskModel> tasks) {
  int total = 0;
  
  for (final task in tasks) {
    // Check if task is assigned to this member
    if (member != null && task.assignedTo != member.id) continue;
    if (member == null && task.assignedTo.isNotEmpty) continue;
    
    // Check if task falls on this date
    if (task.dueDate.year == date.year &&
        task.dueDate.month == date.month &&
        task.dueDate.day == date.day) {
      
      // Add hours based on estimate type
      if (_workloadTimeEstimate == 'Days') {
        total += task.estimatedDays * 8; // Convert days to hours
      } else {
        total += task.estimatedHours;
      }
    }
  }
  
  return total;
}
```

### **Capacity Check:**
- Default capacity: 40 hours (configurable in settings)
- Shows `totalHours/capacity` in member sidebar
- Highlights in red if `totalHours > capacity`

---

## 🔧 **Manual Refresh Mechanism**

### **Current Refresh Flow:**
1. User clicks "Today" dropdown → "Refresh" option
2. Calls `_refreshWorkload(provider)`
3. Calls `provider.refreshTasks()`
4. Fetches fresh data from Firebase
5. Updates UI via `notifyListeners()`
6. Shows success snackbar

### **When Refresh Happens:**
- ✅ Manual refresh button click
- ✅ When switching tabs and returning
- ✅ When app initializes
- ❌ NOT automatically when data changes in Firebase

---

## ✅ **Summary: Will It Work in Real-Time?**

### **Current State:**
- ❌ **NO** - Not real-time
- ✅ Works with manual refresh
- ✅ Updates when navigating away and back
- ✅ Updates when filters/search changes

### **To Make It Real-Time:**
1. Replace `.get()` with `.snapshots()` in `FirebaseService.fetchTasks()`
2. Add `StreamSubscription` in `DashboardProvider`
3. Listen to stream and update `tasks` list automatically
4. UI will auto-update via `Consumer` widget

### **Benefits of Real-Time:**
- ✅ Instant updates when tasks are created/updated/deleted
- ✅ Multiple users see changes immediately
- ✅ No need for manual refresh
- ✅ Better collaboration experience

---

## 🎨 **UI Components**

### **Main Sections:**
1. **Controls Bar**: Dropdowns, filters, search, settings
2. **Date Navigation**: Date range display with prev/next buttons
3. **Left Sidebar**: Assignee list with hours/capacity
4. **Main Grid**: Daily hours per member
5. **Right Sidebar**: Task list with tabs (Unscheduled, No estimate, Overdue)

### **Visual Indicators:**
- **Today**: Red vertical line on current date column
- **Weekends**: Light gray background
- **Hours**: Green pill-shaped badges showing "Xh"
- **Over Capacity**: Red text in member sidebar
- **Active Filters**: Highlighted filter buttons

---

## 🔍 **Code Locations**

- **Main Widget**: `lib/views/team/team_detail_page.dart` → `_buildWorkloadTab()`
- **Provider**: `lib/providers/dashboard_provider.dart` → `DashboardProvider`
- **Controller**: `lib/controllers/task_controller.dart` → `TaskController`
- **Service**: `lib/services/firebase_service.dart` → `FirebaseService.fetchTasks()`
- **State Management**: Uses `Provider` package with `Consumer` widget

---

## 📝 **Notes**

- The Workload page is **fully functional** but requires **manual refresh** for updates
- All filtering, searching, and date navigation works correctly
- Task assignment and hour calculation logic is complete
- Real-time updates would require implementing Firestore stream listeners
- The UI is responsive and handles empty states gracefully

