# TrackMyWork - RBAC (Role-Based Access Control) Diagram

## Overview

TrackMyWork implements a strict ownership-based access control system with two user roles:
1. **Admin** - System management capabilities
2. **User** - Standard user with full control over owned data

---

## User Roles Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│                     TrackMyWork System                       │
└─────────────────────────────────────────────────────────────┘
                            │
                    ┌───────┴────────┐
                    │                │
            ┌───────▼──────┐  ┌──────▼──────┐
            │  Admin Role  │  │  User Role  │
            └──────────────┘  └─────────────┘
```

---

## Permission Matrix

### Legend
- ✅ = Full Access
- 🔒 = Own Data Only
- ⚠️ = Limited Access
- ❌ = No Access

### Resources & Permissions

| Resource          | Admin Create | Admin Read | Admin Update | Admin Delete | User Create | User Read | User Update | User Delete |
|-------------------|-------------|-----------|-------------|-------------|------------|----------|-----------|-----------|
| **Users**         | ❌          | ✅        | ⚠️ (1)      | ❌          | ❌         | 🔒       | 🔒        | ❌        |
| **Tasks**         | ❌          | ✅ (2)    | ❌          | ❌          | ✅         | 🔒       | 🔒        | 🔒        |
| **Ideas**         | ❌          | ✅ (2)    | ❌          | ❌          | ✅         | 🔒       | 🔒        | 🔒        |
| **Finance**       | ❌          | ✅ (2)    | ❌          | ❌          | ✅         | 🔒       | 🔒        | 🔒        |
| **Secure Notes**  | ❌          | ❌        | ❌          | ❌          | ✅         | 🔒       | 🔒        | 🔒        |
| **Reminders**     | ❌          | ✅ (2)    | ❌          | ❌          | ✅         | 🔒       | 🔒        | 🔒        |
| **System Config** | ⚠️ (3)      | ✅        | ⚠️ (3)      | ❌          | ❌         | ❌       | ❌        | ❌        |
| **Reports**       | ✅          | ✅        | N/A         | N/A         | 🔒       | 🔒       | N/A       | N/A       |

**Notes:**
1. Admin can only update user status (activate/deactivate), not personal data
2. Admin can read for system statistics/monitoring but NOT for data modification
3. Limited to system-level configurations, not user data

---

## Detailed Permission Rules

### Admin User Capabilities

```
┌──────────────────────────────────────────────────────────────┐
│                    Admin User (role: admin)                   │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ✅ CAN:                                                     │
│    • View all users list                                     │
│    • View system-wide statistics                            │
│    • Activate/deactivate user accounts                      │
│    • View aggregate reports across all users                │
│    • Manage system configurations                           │
│    • View their own tasks, ideas, finance, notes            │
│    • Full CRUD on their own data                            │
│                                                              │
│  ❌ CANNOT:                                                  │
│    • Access another user's secure notes (NEVER)             │
│    • Modify another user's tasks                            │
│    • Modify another user's ideas                            │
│    • Modify another user's finance records                  │
│    • Delete any user account                                │
│    • Change another user's password                         │
│    • Impersonate another user                               │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### Regular User Capabilities

```
┌──────────────────────────────────────────────────────────────┐
│                  Regular User (role: user)                    │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ✅ CAN:                                                     │
│    • Create their own records (all modules)                  │
│    • Read their own records (all modules)                    │
│    • Update their own records (all modules)                  │
│    • Delete their own records (all modules)                  │
│    • View their own profile                                  │
│    • Update their own profile                                │
│    • Change their own password                               │
│    • View their own dashboard                                │
│    • Search within their own data                            │
│                                                              │
│  ❌ CANNOT:                                                  │
│    • See other users' data (ANY module)                      │
│    • Modify other users' data                                │
│    • Access admin endpoints                                  │
│    • View system statistics                                  │
│    • Manage other users                                      │
│    • Delete their own account (must contact admin)           │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## Ownership Validation Flow

### API Request Flow with Ownership Check

```
┌─────────────────────────────────────────────────────────────────┐
│  1. Client Request                                              │
│     GET /api/v1/tasks/123                                       │
│     Authorization: Bearer <jwt_token>                           │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│  2. JWT Middleware                                              │
│     • Validate JWT token                                        │
│     • Extract user_id and role from token                       │
│     • Attach to request context                                 │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│  3. Route Handler                                               │
│     • Call service layer                                        │
│     • Pass current_user from context                            │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│  4. Service Layer (Ownership Validation)                        │
│                                                                 │
│     task = db.query(Task).filter(Task.id == 123).first()       │
│                                                                 │
│     if not task:                                                │
│         raise NotFoundError()                                   │
│                                                                 │
│     # OWNERSHIP CHECK                                           │
│     if task.user_id != current_user.id:                         │
│         if current_user.role == "admin":                        │
│             # Admin can view for stats, but not modify          │
│             if operation in ["update", "delete"]:               │
│                 raise ForbiddenError()                          │
│         else:                                                   │
│             # Regular user cannot access at all                 │
│             raise ForbiddenError()                              │
│                                                                 │
│     return task                                                 │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│  5. Response                                                    │
│     200 OK - Task data returned                                 │
│     or                                                          │
│     403 Forbidden - Ownership violation                         │
└─────────────────────────────────────────────────────────────────┘
```

---

## Secure Notes Special Rules

### Absolute Privacy for Secure Notes

```
┌─────────────────────────────────────────────────────────────┐
│             Secure Notes Access Rules                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Rule: ONLY the owner can access their secure notes        │
│                                                             │
│  ┌────────────┐                                            │
│  │   Admin    │  ──────X──────> Cannot Access              │
│  └────────────┘                                            │
│                                                             │
│  ┌────────────┐                                            │
│  │ Other User │  ──────X──────> Cannot Access              │
│  └────────────┘                                            │
│                                                             │
│  ┌────────────┐                                            │
│  │   Owner    │  ──────✅──────> Full Access               │
│  └────────────┘        (Encrypted/Decrypted)               │
│                                                             │
│  Implementation:                                            │
│  • Content is AES-256 encrypted at rest                     │
│  • Decryption only happens for owner                        │
│  • Admin endpoints explicitly exclude secure_notes         │
│  • Database RLS (if enabled) enforces this                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Database-Level Enforcement

### Row-Level Security (RLS) Example

```sql
-- Enable RLS on tasks table
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own tasks
CREATE POLICY tasks_user_isolation ON tasks
    FOR ALL
    TO authenticated_user
    USING (user_id = current_setting('app.user_id')::UUID);

-- Policy: Admins can SELECT (read) all tasks for reporting
CREATE POLICY tasks_admin_read ON tasks
    FOR SELECT
    TO admin_user
    USING (true);

-- But admins CANNOT UPDATE or DELETE
-- (no policy created, so default is deny)
```

---

## Endpoint Authorization Matrix

### Public Endpoints (No Auth Required)

```
POST   /api/v1/auth/register
POST   /api/v1/auth/login
GET    /api/v1/health         (optional)
```

### User Endpoints (Auth Required, Own Data Only)

```
GET    /api/v1/tasks          ← Filtered by user_id
POST   /api/v1/tasks          ← user_id = current_user.id
GET    /api/v1/tasks/{id}     ← Ownership check
PUT    /api/v1/tasks/{id}     ← Ownership check
DELETE /api/v1/tasks/{id}     ← Ownership check

(Same pattern for: ideas, finance, notes, reminders)
```

### Admin-Only Endpoints

```
GET    /api/v1/admin/users                ← Admin only
GET    /api/v1/admin/stats                ← Admin only
PUT    /api/v1/admin/users/{id}           ← Admin only (limited)
GET    /api/v1/admin/reports              ← Admin only
```

### Mixed Access (Based on Role)

```
GET    /api/v1/dashboard
  - User: Returns only their own data
  - Admin: Returns their own data + system stats
```

---

## Authorization Code Examples

### Dependency Injection Pattern

```python
# dependencies.py

from fastapi import Depends, HTTPException, status
from jose import jwt, JWTError

def get_current_user(token: str = Depends(oauth2_scheme)) -> User:
    """Extract and validate user from JWT token"""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        user_id = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    user = get_user_by_id(user_id)
    if user is None:
        raise credentials_exception

    return user

def require_admin(current_user: User = Depends(get_current_user)) -> User:
    """Ensure current user is admin"""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    return current_user

def require_active_user(current_user: User = Depends(get_current_user)) -> User:
    """Ensure user account is active"""
    if not current_user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Inactive account"
        )
    return current_user
```

### Using in Endpoints

```python
# api/v1/tasks.py

@router.get("/tasks")
async def list_tasks(
    current_user: User = Depends(require_active_user),
    db: Session = Depends(get_db)
):
    """List tasks - automatically filtered by user_id"""
    # Service layer handles ownership filtering
    return task_service.get_user_tasks(db, current_user.id)

@router.delete("/tasks/{task_id}")
async def delete_task(
    task_id: UUID,
    current_user: User = Depends(require_active_user),
    db: Session = Depends(get_db)
):
    """Delete task - ownership validated in service"""
    task_service.delete_task(db, task_id, current_user)
    return {"message": "Task deleted"}

@router.get("/admin/users", dependencies=[Depends(require_admin)])
async def list_all_users(db: Session = Depends(get_db)):
    """Admin only - list all users"""
    return admin_service.get_all_users(db)
```

### Service Layer Ownership Validation

```python
# services/task_service.py

class TaskService:
    def delete_task(self, db: Session, task_id: UUID, current_user: User):
        """Delete task with ownership validation"""
        task = db.query(Task).filter(Task.id == task_id).first()

        if not task:
            raise HTTPException(
                status_code=404,
                detail="Task not found"
            )

        # OWNERSHIP CHECK
        if task.user_id != current_user.id:
            raise HTTPException(
                status_code=403,
                detail="You can only delete your own tasks"
            )

        db.delete(task)
        db.commit()

    def get_task_by_id(self, db: Session, task_id: UUID, current_user: User):
        """Get task with ownership validation"""
        task = db.query(Task).filter(Task.id == task_id).first()

        if not task:
            raise HTTPException(status_code=404, detail="Task not found")

        # Allow admin to read for stats, but not modify
        if task.user_id != current_user.id:
            if current_user.role != "admin":
                raise HTTPException(
                    status_code=403,
                    detail="Access denied"
                )
            # Admin can proceed to read only

        return task
```

---

## Security Best Practices

### 1. Never Trust Client Data
```python
# ❌ BAD - Client provides user_id
@router.post("/tasks")
def create_task(task_data: TaskCreate):
    task = Task(**task_data.dict())  # Contains user_id from client!
    db.add(task)

# ✅ GOOD - Server determines user_id
@router.post("/tasks")
def create_task(
    task_data: TaskCreate,
    current_user: User = Depends(get_current_user)
):
    task = Task(**task_data.dict(exclude={'user_id'}))
    task.user_id = current_user.id  # Set from authenticated user
    db.add(task)
```

### 2. Filter Queries by User
```python
# ❌ BAD - Returns all tasks
def get_tasks(db: Session):
    return db.query(Task).all()

# ✅ GOOD - Filters by user
def get_tasks(db: Session, user_id: UUID):
    return db.query(Task).filter(Task.user_id == user_id).all()
```

### 3. Validate on Every Operation
```python
# Always check ownership before:
# - UPDATE
# - DELETE
# - READ (if sensitive data)

def update_task(db: Session, task_id: UUID, current_user: User, data: dict):
    task = db.query(Task).filter(Task.id == task_id).first()

    if not task:
        raise NotFoundError()

    # CRITICAL: Ownership check
    if task.user_id != current_user.id:
        raise ForbiddenError()

    # Proceed with update
    for key, value in data.items():
        setattr(task, key, value)

    db.commit()
```

---

## Testing RBAC

### Test Cases Required

```python
# tests/test_permissions.py

def test_user_cannot_access_other_user_tasks():
    """Regular user cannot access another user's tasks"""
    # Create two users
    user1 = create_user("user1@example.com")
    user2 = create_user("user2@example.com")

    # User1 creates a task
    task = create_task(user1, "User1's task")

    # User2 tries to access it
    response = client.get(
        f"/api/v1/tasks/{task.id}",
        headers=get_auth_headers(user2)
    )

    assert response.status_code == 403  # Forbidden

def test_admin_can_view_but_not_modify_user_tasks():
    """Admin can view tasks but cannot modify"""
    admin = create_user("admin@example.com", role="admin")
    user = create_user("user@example.com")

    task = create_task(user, "User's task")

    # Admin can view
    response = client.get(
        f"/api/v1/tasks/{task.id}",
        headers=get_auth_headers(admin)
    )
    assert response.status_code == 200  # OK

    # Admin cannot modify
    response = client.put(
        f"/api/v1/tasks/{task.id}",
        json={"title": "Modified"},
        headers=get_auth_headers(admin)
    )
    assert response.status_code == 403  # Forbidden

def test_admin_cannot_access_secure_notes():
    """Admin has NO access to user's secure notes"""
    admin = create_user("admin@example.com", role="admin")
    user = create_user("user@example.com")

    note = create_secure_note(user, "Secret credentials")

    # Admin tries to read
    response = client.get(
        f"/api/v1/notes/{note.id}",
        headers=get_auth_headers(admin)
    )
    assert response.status_code == 403  # Forbidden
```

---

## Summary

### Key Principles

1. **Ownership First**: Every resource has an owner (user_id foreign key)
2. **Default Deny**: If not explicitly allowed, it's forbidden
3. **Validate Always**: Check ownership on every operation
4. **Trust Nothing**: Never trust client-provided user_id
5. **Absolute Privacy**: Secure notes are strictly user-only
6. **Admin Limited**: Admin can view for stats, never modify user data
7. **Enforce Everywhere**: Application layer, database layer, API layer

### Implementation Checklist

- [ ] JWT authentication middleware
- [ ] User role stored in JWT payload
- [ ] Ownership validation in all service methods
- [ ] Admin role checked for admin endpoints
- [ ] Secure notes explicitly excluded from admin access
- [ ] Database foreign keys enforce user_id
- [ ] Optional: Row-Level Security enabled
- [ ] Comprehensive permission tests
- [ ] API documentation includes permission requirements
- [ ] Error messages don't leak information

---

**This RBAC system ensures complete data privacy while allowing necessary administrative oversight.**
