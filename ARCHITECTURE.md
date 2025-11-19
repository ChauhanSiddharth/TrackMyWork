# TrackMyWork - Complete Architecture & Design Document

## Executive Summary

TrackMyWork is a comprehensive personal productivity and finance management platform that consolidates task management, idea tracking, financial oversight, secure note-keeping, and intelligent reminders into a single, secure application. The system enforces strict ownership-based access control, ensuring complete data privacy while providing administrators with system-level management capabilities.

---

## 1. System Architecture

### 1.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                       Client Layer                           │
│  ┌──────────────────────────────────────────────────────┐  │
│  │     Next.js Frontend (React)                         │  │
│  │  - SSR/CSR Rendering                                │  │
│  │  - JWT Token Management                             │  │
│  │  - Responsive UI Components                         │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
                    HTTPS/REST API
                            │
┌─────────────────────────────────────────────────────────────┐
│                      API Gateway Layer                       │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  FastAPI Application                                 │  │
│  │  - JWT Authentication Middleware                     │  │
│  │  - Rate Limiting                                     │  │
│  │  - CORS Configuration                                │  │
│  │  - Request Validation                                │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
            ┌───────────────┼───────────────┐
            │               │               │
┌───────────▼────┐  ┌──────▼──────┐  ┌────▼──────────┐
│  Service Layer │  │ Auth Service│  │ Crypto Service│
│                │  │             │  │               │
│ - Task Service │  │ - JWT Gen   │  │ - AES-256     │
│ - Idea Service │  │ - Refresh   │  │ - Encryption  │
│ - Finance Svc  │  │ - RBAC      │  │ - Decryption  │
│ - Notes Service│  │ - Ownership │  │               │
│ - Reminder Svc │  │   Validation│  │               │
│ - Search Svc   │  │             │  │               │
└───────────┬────┘  └──────┬──────┘  └───────────────┘
            │               │
            └───────────────┼───────────────┐
                            │               │
                    ┌───────▼────────┐  ┌──▼─────────────┐
                    │   PostgreSQL   │  │  Background    │
                    │   Database     │  │  Worker        │
                    │                │  │  (Celery/Redis)│
                    │  - Users       │  │                │
                    │  - Tasks       │  │  - Reminders   │
                    │  - Ideas       │  │  - Emails      │
                    │  - Finance     │  │  - Cleanup     │
                    │  - Notes       │  │                │
                    │  - Reminders   │  │                │
                    └────────────────┘  └────────────────┘
```

### 1.2 Technology Stack

#### Backend
- **Framework**: FastAPI (Python 3.11+)
- **ORM**: SQLAlchemy 2.0
- **Database**: PostgreSQL 15+
- **Authentication**: JWT (PyJWT)
- **Encryption**: cryptography (Fernet for AES-256)
- **Background Tasks**: Celery + Redis
- **Migrations**: Alembic
- **Validation**: Pydantic v2

#### Frontend
- **Framework**: Next.js 14+ (App Router)
- **Language**: TypeScript
- **UI Library**: React 18+
- **Styling**: Tailwind CSS
- **State Management**: Zustand / React Query
- **Forms**: React Hook Form + Zod
- **HTTP Client**: Axios with interceptors

#### Infrastructure
- **Cache**: Redis
- **Message Queue**: Redis/RabbitMQ
- **File Storage**: Local/S3-compatible
- **Container**: Docker + Docker Compose

---

## 2. Database Schema & ERD

### 2.1 Database Tables

#### Users Table
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'user', -- 'admin' or 'user'
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
```

#### Tasks Table
```sql
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'pending', -- pending, in_progress, completed, cancelled
    priority VARCHAR(50) NOT NULL DEFAULT 'medium', -- low, medium, high, urgent
    due_date TIMESTAMP,
    completed_at TIMESTAMP,
    tags TEXT[], -- PostgreSQL array for tags
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_priority ON tasks(priority);
CREATE INDEX idx_tasks_due_date ON tasks(due_date);
CREATE INDEX idx_tasks_tags ON tasks USING GIN(tags);
```

#### Ideas Table
```sql
CREATE TABLE ideas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    tags TEXT[],
    status VARCHAR(50) DEFAULT 'new', -- new, under_consideration, planned, archived
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ideas_user_id ON ideas(user_id);
CREATE INDEX idx_ideas_category ON ideas(category);
CREATE INDEX idx_ideas_tags ON ideas USING GIN(tags);
CREATE INDEX idx_ideas_status ON ideas(status);
```

#### Finance Transactions Table
```sql
CREATE TABLE finance_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    transaction_type VARCHAR(50) NOT NULL, -- income, expense, savings, investment
    amount DECIMAL(15, 2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'USD',
    category VARCHAR(100), -- groceries, utilities, salary, dividend, etc.
    description TEXT,
    transaction_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_finance_user_id ON finance_transactions(user_id);
CREATE INDEX idx_finance_type ON finance_transactions(transaction_type);
CREATE INDEX idx_finance_category ON finance_transactions(category);
CREATE INDEX idx_finance_date ON finance_transactions(transaction_date);
```

#### Secure Notes Table
```sql
CREATE TABLE secure_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    encrypted_content TEXT NOT NULL, -- AES-256 encrypted
    encryption_key_id VARCHAR(100), -- For key rotation
    tags TEXT[],
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_secure_notes_user_id ON secure_notes(user_id);
CREATE INDEX idx_secure_notes_tags ON secure_notes USING GIN(tags);
```

#### Reminders Table
```sql
CREATE TABLE reminders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    reminder_time TIMESTAMP NOT NULL,
    is_sent BOOLEAN DEFAULT FALSE,
    related_entity_type VARCHAR(50), -- task, idea, finance, note
    related_entity_id UUID,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_reminders_user_id ON reminders(user_id);
CREATE INDEX idx_reminders_time ON reminders(reminder_time);
CREATE INDEX idx_reminders_sent ON reminders(is_sent);
CREATE INDEX idx_reminders_entity ON reminders(related_entity_type, related_entity_id);
```

#### Refresh Tokens Table
```sql
CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    is_revoked BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_hash ON refresh_tokens(token_hash);
```

### 2.2 Entity Relationship Diagram

```
┌──────────────┐
│    Users     │
│──────────────│
│ id (PK)      │
│ email        │
│ username     │
│ password_hash│
│ role         │
│ is_active    │
│ created_at   │
│ updated_at   │
│ last_login   │
└──────┬───────┘
       │
       │ 1:N (owns)
       │
       ├─────────────────┬──────────────────┬──────────────────┬──────────────────┬─────────────────┐
       │                 │                  │                  │                  │                 │
┌──────▼───────┐  ┌──────▼───────┐  ┌──────▼──────────┐  ┌───▼──────────┐  ┌───▼─────────┐  ┌───▼──────────┐
│    Tasks     │  │    Ideas     │  │    Finance      │  │SecureNotes   │  │  Reminders  │  │RefreshTokens │
│──────────────│  │──────────────│  │  Transactions   │  │──────────────│  │─────────────│  │──────────────│
│ id (PK)      │  │ id (PK)      │  │──────────────   │  │ id (PK)      │  │ id (PK)     │  │ id (PK)      │
│ user_id (FK) │  │ user_id (FK) │  │ id (PK)         │  │ user_id (FK) │  │ user_id(FK) │  │ user_id (FK) │
│ title        │  │ title        │  │ user_id (FK)    │  │ title        │  │ title       │  │ token_hash   │
│ description  │  │ description  │  │ type            │  │ encrypted_   │  │ description │  │ expires_at   │
│ status       │  │ category     │  │ amount          │  │   content    │  │ reminder_   │  │ is_revoked   │
│ priority     │  │ tags         │  │ currency        │  │ encryption_  │  │   time      │  │ created_at   │
│ due_date     │  │ status       │  │ category        │  │   key_id     │  │ is_sent     │  └──────────────┘
│ completed_at │  │ created_at   │  │ description     │  │ tags         │  │ related_    │
│ tags         │  │ updated_at   │  │ transaction_    │  │ created_at   │  │   entity_   │
│ created_at   │  └──────────────┘  │   date          │  │ updated_at   │  │   type      │
│ updated_at   │                     │ created_at      │  └──────────────┘  │ related_    │
└──────────────┘                     │ updated_at      │                     │   entity_id │
                                     └─────────────────┘                     │ created_at  │
                                                                              │ updated_at  │
                                                                              └─────────────┘
```

---

## 3. API Endpoints Specification

### 3.1 Authentication Endpoints

```
POST   /api/v1/auth/register
POST   /api/v1/auth/login
POST   /api/v1/auth/refresh
POST   /api/v1/auth/logout
GET    /api/v1/auth/me
```

#### Details:

**POST /api/v1/auth/register**
```json
Request:
{
  "email": "user@example.com",
  "username": "johndoe",
  "password": "SecurePass123!"
}

Response: 201 Created
{
  "id": "uuid",
  "email": "user@example.com",
  "username": "johndoe",
  "role": "user",
  "created_at": "2025-11-19T10:00:00Z"
}
```

**POST /api/v1/auth/login**
```json
Request:
{
  "email": "user@example.com",
  "password": "SecurePass123!"
}

Response: 200 OK
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "token_type": "bearer",
  "expires_in": 3600,
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "username": "johndoe",
    "role": "user"
  }
}
```

### 3.2 Tasks Endpoints

```
GET    /api/v1/tasks              # List user's tasks (paginated, filtered)
POST   /api/v1/tasks              # Create new task
GET    /api/v1/tasks/{id}         # Get task by ID
PUT    /api/v1/tasks/{id}         # Update task
DELETE /api/v1/tasks/{id}         # Delete task
PATCH  /api/v1/tasks/{id}/status  # Update task status
GET    /api/v1/tasks/calendar     # Get tasks by date range
```

**GET /api/v1/tasks** (with query params)
```
Query Parameters:
- page: int = 1
- limit: int = 20
- status: str = None (pending, in_progress, completed, cancelled)
- priority: str = None (low, medium, high, urgent)
- due_date_from: date = None
- due_date_to: date = None
- tags: List[str] = None
- search: str = None

Response: 200 OK
{
  "items": [
    {
      "id": "uuid",
      "user_id": "uuid",
      "title": "Complete project proposal",
      "description": "Write detailed proposal...",
      "status": "in_progress",
      "priority": "high",
      "due_date": "2025-11-25T00:00:00Z",
      "completed_at": null,
      "tags": ["work", "urgent"],
      "created_at": "2025-11-19T10:00:00Z",
      "updated_at": "2025-11-19T10:00:00Z"
    }
  ],
  "total": 45,
  "page": 1,
  "limit": 20,
  "pages": 3
}
```

**POST /api/v1/tasks**
```json
Request:
{
  "title": "Complete project proposal",
  "description": "Write detailed proposal for Q1 2026",
  "status": "pending",
  "priority": "high",
  "due_date": "2025-11-25T00:00:00Z",
  "tags": ["work", "urgent"]
}

Response: 201 Created
{
  "id": "uuid",
  "user_id": "uuid",
  "title": "Complete project proposal",
  "description": "Write detailed proposal for Q1 2026",
  "status": "pending",
  "priority": "high",
  "due_date": "2025-11-25T00:00:00Z",
  "completed_at": null,
  "tags": ["work", "urgent"],
  "created_at": "2025-11-19T10:00:00Z",
  "updated_at": "2025-11-19T10:00:00Z"
}
```

### 3.3 Ideas Endpoints

```
GET    /api/v1/ideas              # List user's ideas
POST   /api/v1/ideas              # Create new idea
GET    /api/v1/ideas/{id}         # Get idea by ID
PUT    /api/v1/ideas/{id}         # Update idea
DELETE /api/v1/ideas/{id}         # Delete idea
```

### 3.4 Finance Endpoints

```
GET    /api/v1/finance/transactions           # List transactions (filtered, paginated)
POST   /api/v1/finance/transactions           # Create transaction
GET    /api/v1/finance/transactions/{id}      # Get transaction
PUT    /api/v1/finance/transactions/{id}      # Update transaction
DELETE /api/v1/finance/transactions/{id}      # Delete transaction
GET    /api/v1/finance/summary                # Get financial summary
GET    /api/v1/finance/reports/monthly        # Monthly report
GET    /api/v1/finance/reports/annual         # Annual report
GET    /api/v1/finance/categories             # Get spending by category
```

**GET /api/v1/finance/summary**
```json
Query Parameters:
- from_date: date
- to_date: date

Response: 200 OK
{
  "period": {
    "from": "2025-01-01",
    "to": "2025-11-19"
  },
  "total_income": 85000.00,
  "total_expenses": 42500.50,
  "total_savings": 12000.00,
  "total_investments": 8500.00,
  "net_balance": 42000.50,
  "by_category": {
    "expenses": {
      "groceries": 5200.00,
      "utilities": 3100.00,
      "entertainment": 2800.00
    },
    "income": {
      "salary": 75000.00,
      "freelance": 10000.00
    }
  }
}
```

### 3.5 Secure Notes Endpoints

```
GET    /api/v1/notes              # List user's notes (titles only)
POST   /api/v1/notes              # Create encrypted note
GET    /api/v1/notes/{id}         # Get and decrypt note
PUT    /api/v1/notes/{id}         # Update note (re-encrypt)
DELETE /api/v1/notes/{id}         # Delete note
```

**POST /api/v1/notes**
```json
Request:
{
  "title": "AWS Credentials",
  "content": "Access Key: AKIA...\nSecret: ...",
  "tags": ["aws", "credentials"]
}

Response: 201 Created
{
  "id": "uuid",
  "user_id": "uuid",
  "title": "AWS Credentials",
  "tags": ["aws", "credentials"],
  "created_at": "2025-11-19T10:00:00Z",
  "updated_at": "2025-11-19T10:00:00Z"
  // Note: encrypted_content is NOT returned on creation
}
```

**GET /api/v1/notes/{id}**
```json
Response: 200 OK
{
  "id": "uuid",
  "user_id": "uuid",
  "title": "AWS Credentials",
  "content": "Access Key: AKIA...\nSecret: ...",  // Decrypted
  "tags": ["aws", "credentials"],
  "created_at": "2025-11-19T10:00:00Z",
  "updated_at": "2025-11-19T10:00:00Z"
}
```

### 3.6 Reminders Endpoints

```
GET    /api/v1/reminders          # List user's reminders
POST   /api/v1/reminders          # Create reminder
GET    /api/v1/reminders/{id}     # Get reminder
PUT    /api/v1/reminders/{id}     # Update reminder
DELETE /api/v1/reminders/{id}     # Delete reminder
GET    /api/v1/reminders/upcoming # Get upcoming reminders
```

### 3.7 Search Endpoint

```
GET    /api/v1/search             # Global search across modules
```

**GET /api/v1/search**
```json
Query Parameters:
- q: str (search query)
- modules: List[str] = ["tasks", "ideas", "notes", "finance"]
- limit: int = 50

Response: 200 OK
{
  "query": "project",
  "results": {
    "tasks": [
      {
        "id": "uuid",
        "type": "task",
        "title": "Complete project proposal",
        "snippet": "...detailed proposal for the project...",
        "created_at": "2025-11-19T10:00:00Z"
      }
    ],
    "ideas": [
      {
        "id": "uuid",
        "type": "idea",
        "title": "New project idea",
        "snippet": "...mobile app project...",
        "created_at": "2025-11-15T10:00:00Z"
      }
    ],
    "notes": [
      {
        "id": "uuid",
        "type": "note",
        "title": "Project credentials",
        "snippet": null,  // Secure notes don't show content in search
        "created_at": "2025-11-10T10:00:00Z"
      }
    ],
    "finance": []
  },
  "total_results": 3
}
```

### 3.8 Dashboard Endpoints

```
GET    /api/v1/dashboard          # Get dashboard data with all dashlets
GET    /api/v1/dashboard/config   # Get user's dashboard configuration
PUT    /api/v1/dashboard/config   # Update dashboard configuration
```

**GET /api/v1/dashboard**
```json
Response: 200 OK
{
  "dashlets": [
    {
      "type": "recent_tasks",
      "title": "Recent Tasks",
      "icon": "task",
      "data": [
        {
          "id": "uuid",
          "title": "Complete project proposal",
          "status": "in_progress",
          "created_at": "2025-11-19T10:00:00Z"
        }
        // ... up to 5 items
      ],
      "view_more_url": "/tasks"
    },
    {
      "type": "recent_expenses",
      "title": "Recent Expenses",
      "icon": "finance",
      "data": [
        {
          "id": "uuid",
          "description": "Grocery shopping",
          "amount": 125.50,
          "transaction_date": "2025-11-18"
        }
        // ... up to 5 items
      ],
      "view_more_url": "/finance"
    },
    {
      "type": "recent_ideas",
      "title": "Recent Ideas",
      "icon": "lightbulb",
      "data": [...],
      "view_more_url": "/ideas"
    },
    {
      "type": "upcoming_reminders",
      "title": "Upcoming Reminders",
      "icon": "bell",
      "data": [...],
      "view_more_url": "/reminders"
    }
  ],
  "stats": {
    "pending_tasks": 12,
    "overdue_tasks": 3,
    "upcoming_reminders": 5,
    "monthly_expenses": 3250.00
  }
}
```

### 3.9 Admin Endpoints

```
GET    /api/v1/admin/users        # List all users (admin only)
GET    /api/v1/admin/stats        # System-wide statistics
PUT    /api/v1/admin/users/{id}   # Update user (activate/deactivate)
GET    /api/v1/admin/reports      # Aggregate reports
```

---

## 4. RBAC & Ownership Rules

### 4.1 Role Definitions

**Admin User**
- Can view list of all users
- Can activate/deactivate user accounts
- Can view system-wide aggregate statistics
- **CANNOT** access individual user's secure notes
- **CANNOT** modify user data directly (tasks, ideas, finance, notes)
- Can access global reports (total users, system usage, etc.)

**Regular User**
- Can only CREATE, READ, UPDATE, DELETE their own records
- Cannot see any other user's data
- Cannot access admin endpoints
- Full CRUD on owned resources

### 4.2 Ownership Enforcement Rules

**At Service Layer:**
```python
# Pseudo-code for ownership validation

def get_task(task_id: UUID, current_user: User) -> Task:
    task = db.query(Task).filter(Task.id == task_id).first()

    if not task:
        raise NotFoundError()

    # Ownership check
    if task.user_id != current_user.id and current_user.role != "admin":
        raise ForbiddenError("You don't have permission to access this resource")

    # Even admins cannot access secure notes
    return task

def delete_task(task_id: UUID, current_user: User) -> None:
    task = db.query(Task).filter(Task.id == task_id).first()

    if not task:
        raise NotFoundError()

    # Only owner can delete
    if task.user_id != current_user.id:
        raise ForbiddenError("You can only delete your own tasks")

    db.delete(task)
    db.commit()
```

**Database-Level Enforcement:**
```sql
-- Row Level Security (RLS) example for PostgreSQL

-- Enable RLS on tasks table
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own tasks
CREATE POLICY tasks_user_isolation ON tasks
    FOR ALL
    TO authenticated_user
    USING (user_id = current_user_id());

-- Similar policies for all user-owned tables
```

### 4.3 Permission Matrix

| Resource | Admin Read | Admin Write | Admin Delete | User Read (Own) | User Write (Own) | User Delete (Own) | User Read (Others) |
|----------|-----------|-------------|--------------|----------------|-----------------|------------------|-------------------|
| Tasks | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ |
| Ideas | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ |
| Finance | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ |
| Secure Notes | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ |
| Reminders | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ |
| Users | ✅ | ✅* | ❌ | ✅ (self) | ✅ (self) | ❌ | ❌ |

*Admin can only update user status (activate/deactivate), not personal data

---

## 5. Project Folder Structure

### 5.1 Backend Structure (FastAPI)

```
backend/
├── alembic/                      # Database migrations
│   ├── versions/
│   └── env.py
├── app/
│   ├── __init__.py
│   ├── main.py                   # FastAPI app initialization
│   ├── config.py                 # Configuration management
│   ├── dependencies.py           # Dependency injection
│   │
│   ├── api/                      # API routes
│   │   ├── __init__.py
│   │   ├── v1/
│   │   │   ├── __init__.py
│   │   │   ├── auth.py           # Authentication endpoints
│   │   │   ├── tasks.py          # Task endpoints
│   │   │   ├── ideas.py          # Idea endpoints
│   │   │   ├── finance.py        # Finance endpoints
│   │   │   ├── notes.py          # Secure notes endpoints
│   │   │   ├── reminders.py      # Reminder endpoints
│   │   │   ├── search.py         # Global search endpoint
│   │   │   ├── dashboard.py      # Dashboard endpoints
│   │   │   └── admin.py          # Admin endpoints
│   │
│   ├── core/                     # Core functionality
│   │   ├── __init__.py
│   │   ├── security.py           # JWT, password hashing
│   │   ├── encryption.py         # AES-256 encryption
│   │   ├── permissions.py        # RBAC utilities
│   │   └── pagination.py         # Pagination helpers
│   │
│   ├── db/                       # Database
│   │   ├── __init__.py
│   │   ├── session.py            # DB session management
│   │   └── base.py               # Base model
│   │
│   ├── models/                   # SQLAlchemy models
│   │   ├── __init__.py
│   │   ├── user.py
│   │   ├── task.py
│   │   ├── idea.py
│   │   ├── finance.py
│   │   ├── note.py
│   │   ├── reminder.py
│   │   └── refresh_token.py
│   │
│   ├── schemas/                  # Pydantic schemas
│   │   ├── __init__.py
│   │   ├── user.py
│   │   ├── task.py
│   │   ├── idea.py
│   │   ├── finance.py
│   │   ├── note.py
│   │   ├── reminder.py
│   │   ├── dashboard.py
│   │   └── common.py             # Common schemas (pagination, etc.)
│   │
│   ├── services/                 # Business logic
│   │   ├── __init__.py
│   │   ├── auth_service.py
│   │   ├── task_service.py
│   │   ├── idea_service.py
│   │   ├── finance_service.py
│   │   ├── note_service.py
│   │   ├── reminder_service.py
│   │   ├── search_service.py
│   │   └── dashboard_service.py
│   │
│   ├── workers/                  # Background tasks
│   │   ├── __init__.py
│   │   ├── celery_app.py         # Celery configuration
│   │   ├── tasks.py              # Celery tasks
│   │   └── reminder_worker.py    # Reminder processing
│   │
│   ├── middleware/               # Custom middleware
│   │   ├── __init__.py
│   │   ├── auth.py               # JWT middleware
│   │   ├── rate_limit.py         # Rate limiting
│   │   └── error_handler.py      # Global error handling
│   │
│   └── utils/                    # Utilities
│       ├── __init__.py
│       ├── logger.py
│       └── validators.py
│
├── tests/                        # Tests
│   ├── __init__.py
│   ├── conftest.py
│   ├── test_auth.py
│   ├── test_tasks.py
│   ├── test_finance.py
│   └── test_permissions.py
│
├── .env.example
├── .gitignore
├── alembic.ini
├── docker-compose.yml
├── Dockerfile
├── pyproject.toml               # Poetry dependencies
├── pytest.ini
└── README.md
```

### 5.2 Frontend Structure (Next.js)

```
frontend/
├── public/
│   ├── icons/
│   └── images/
│
├── src/
│   ├── app/                      # Next.js App Router
│   │   ├── layout.tsx            # Root layout
│   │   ├── page.tsx              # Home/landing page
│   │   ├── (auth)/               # Auth route group
│   │   │   ├── login/
│   │   │   │   └── page.tsx
│   │   │   └── register/
│   │   │       └── page.tsx
│   │   ├── (dashboard)/          # Protected routes
│   │   │   ├── layout.tsx        # Dashboard layout
│   │   │   ├── dashboard/
│   │   │   │   └── page.tsx
│   │   │   ├── tasks/
│   │   │   │   ├── page.tsx
│   │   │   │   ├── [id]/
│   │   │   │   │   └── page.tsx
│   │   │   │   └── new/
│   │   │   │       └── page.tsx
│   │   │   ├── ideas/
│   │   │   │   └── page.tsx
│   │   │   ├── finance/
│   │   │   │   ├── page.tsx
│   │   │   │   └── reports/
│   │   │   │       └── page.tsx
│   │   │   ├── notes/
│   │   │   │   └── page.tsx
│   │   │   ├── reminders/
│   │   │   │   └── page.tsx
│   │   │   └── search/
│   │   │       └── page.tsx
│   │   └── admin/
│   │       └── page.tsx
│   │
│   ├── components/               # React components
│   │   ├── ui/                   # Base UI components
│   │   │   ├── Button.tsx
│   │   │   ├── Input.tsx
│   │   │   ├── Modal.tsx
│   │   │   ├── Card.tsx
│   │   │   └── Table.tsx
│   │   ├── layout/
│   │   │   ├── Header.tsx
│   │   │   ├── Sidebar.tsx
│   │   │   └── Footer.tsx
│   │   ├── dashboard/
│   │   │   ├── Dashlet.tsx
│   │   │   ├── StatsCard.tsx
│   │   │   └── RecentList.tsx
│   │   ├── tasks/
│   │   │   ├── TaskList.tsx
│   │   │   ├── TaskCard.tsx
│   │   │   ├── TaskForm.tsx
│   │   │   └── TaskCalendar.tsx
│   │   ├── finance/
│   │   │   ├── TransactionList.tsx
│   │   │   ├── TransactionForm.tsx
│   │   │   ├── FinanceSummary.tsx
│   │   │   └── CategoryChart.tsx
│   │   └── common/
│   │       ├── SearchBar.tsx
│   │       ├── Pagination.tsx
│   │       └── LoadingSpinner.tsx
│   │
│   ├── lib/                      # Utilities and configurations
│   │   ├── api/
│   │   │   ├── client.ts         # Axios instance
│   │   │   ├── auth.ts
│   │   │   ├── tasks.ts
│   │   │   ├── finance.ts
│   │   │   └── index.ts
│   │   ├── auth/
│   │   │   ├── session.ts
│   │   │   └── middleware.ts
│   │   └── utils/
│   │       ├── formatters.ts
│   │       └── validators.ts
│   │
│   ├── hooks/                    # Custom React hooks
│   │   ├── useAuth.ts
│   │   ├── useTasks.ts
│   │   ├── useFinance.ts
│   │   └── useSearch.ts
│   │
│   ├── stores/                   # State management (Zustand)
│   │   ├── authStore.ts
│   │   ├── taskStore.ts
│   │   └── uiStore.ts
│   │
│   ├── types/                    # TypeScript types
│   │   ├── auth.ts
│   │   ├── task.ts
│   │   ├── finance.ts
│   │   └── api.ts
│   │
│   └── styles/
│       └── globals.css           # Tailwind directives
│
├── .env.local.example
├── .gitignore
├── next.config.js
├── package.json
├── postcss.config.js
├── tailwind.config.js
├── tsconfig.json
└── README.md
```

---

## 6. Dashboard Design

### 6.1 Dashboard Layout

```
┌─────────────────────────────────────────────────────────────────┐
│  Header                                              [User Menu] │
├─────────────────────────────────────────────────────────────────┤
│ Sidebar │  Dashboard                                            │
│         │                                                        │
│ Tasks   │  ┌──────────────────────┬──────────────────────┐     │
│ Ideas   │  │  📊 Quick Stats       │  🔔 Alerts           │     │
│ Finance │  │                       │                       │     │
│ Notes   │  │  • Pending Tasks: 12  │  • 3 Overdue Tasks   │     │
│ Search  │  │  • This Month: $2.5K  │  • 5 Upcoming        │     │
│         │  │  • Ideas: 8           │    Reminders         │     │
│         │  └──────────────────────┴──────────────────────┘     │
│         │                                                        │
│         │  ┌────────────────────────────────────────────────┐  │
│         │  │  ✅ Recent Tasks              [View All]       │  │
│         │  ├────────────────────────────────────────────────┤  │
│         │  │  • Complete project proposal     [In Progress] │  │
│         │  │  • Review Q4 reports             [Pending]     │  │
│         │  │  • Team meeting prep             [High]        │  │
│         │  │  • Update documentation          [Pending]     │  │
│         │  │  • Code review PR #234           [Completed]   │  │
│         │  └────────────────────────────────────────────────┘  │
│         │                                                        │
│         │  ┌────────────────────┬──────────────────────────┐   │
│         │  │ 💰 Recent Expenses │  💡 Recent Ideas         │   │
│         │  │    [View All]      │     [View All]           │   │
│         │  ├────────────────────┼──────────────────────────┤   │
│         │  │ • Groceries $125   │  • Mobile app for        │   │
│         │  │ • Utilities $85    │    habit tracking        │   │
│         │  │ • Gas $45          │  • Chrome extension      │   │
│         │  │ • Dinner $60       │    for productivity      │   │
│         │  │ • Coffee $12       │  • API integration       │   │
│         │  └────────────────────┴──────────────────────────┘   │
│         │                                                        │
└─────────────────────────────────────────────────────────────────┘
```

### 6.2 Dashlet Specifications

Each dashlet follows this structure:

**Component Properties:**
- `title`: String
- `icon`: Icon component
- `data`: Array of recent items (max 5)
- `viewMoreUrl`: String
- `type`: Enum (recent_tasks, recent_expenses, recent_ideas, upcoming_reminders)

**Dashlet Types:**

1. **Recent Tasks Dashlet**
   - Shows last 5 tasks ordered by creation date
   - Displays: title, status badge, priority indicator
   - Color-coded by priority (red=urgent, orange=high, yellow=medium, green=low)

2. **Recent Expenses Dashlet**
   - Shows last 5 expense transactions
   - Displays: description, amount, category
   - Red text for expenses, green for income

3. **Recent Ideas Dashlet**
   - Shows last 5 ideas
   - Displays: title, category tag
   - Status badge (new, planned, archived)

4. **Upcoming Reminders Dashlet**
   - Shows next 5 upcoming reminders
   - Displays: title, time until reminder
   - Sorted by reminder_time ascending
   - Color coding: red (< 1 hour), orange (< 24 hours), default (> 24 hours)

### 6.3 Dashboard Configuration

Users can customize which dashlets to show via settings:

```json
{
  "dashboard_config": {
    "enabled_dashlets": ["recent_tasks", "recent_expenses", "recent_ideas", "upcoming_reminders"],
    "dashlet_order": [0, 1, 2, 3],
    "items_per_dashlet": 5
  }
}
```

---

## 7. Security Implementation

### 7.1 Authentication Flow

```
1. User Login
   ↓
2. Validate credentials (bcrypt password hash comparison)
   ↓
3. Generate JWT access token (15-60 min expiry)
   ↓
4. Generate refresh token (7-30 days expiry)
   ↓
5. Store refresh token hash in database
   ↓
6. Return both tokens to client
   ↓
7. Client stores tokens (httpOnly cookies or secure storage)

Token Refresh Flow:
1. Access token expires
   ↓
2. Client sends refresh token to /auth/refresh
   ↓
3. Validate refresh token (not revoked, not expired)
   ↓
4. Issue new access token
   ↓
5. Return new access token
```

### 7.2 Encryption Implementation

**For Secure Notes:**

```python
from cryptography.fernet import Fernet
import base64
import os

class EncryptionService:
    def __init__(self):
        # Use environment variable or key management service
        self.key = os.getenv("ENCRYPTION_KEY").encode()
        self.fernet = Fernet(self.key)

    def encrypt(self, plaintext: str) -> str:
        """Encrypt plaintext and return base64 encoded ciphertext"""
        encrypted = self.fernet.encrypt(plaintext.encode())
        return base64.b64encode(encrypted).decode()

    def decrypt(self, ciphertext: str) -> str:
        """Decrypt base64 encoded ciphertext"""
        decoded = base64.b64decode(ciphertext.encode())
        decrypted = self.fernet.decrypt(decoded)
        return decrypted.decode()
```

**Key Management:**
- Master key stored in environment variable or KMS
- Support for key rotation via `encryption_key_id` field
- Never log or expose encryption keys

### 7.3 Rate Limiting

```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

# Apply to sensitive endpoints
@app.post("/api/v1/auth/login")
@limiter.limit("5/minute")
async def login():
    ...

@app.post("/api/v1/auth/register")
@limiter.limit("3/hour")
async def register():
    ...
```

---

## 8. Background Workers & Reminders

### 8.1 Celery Configuration

```python
# workers/celery_app.py
from celery import Celery
from celery.schedules import crontab

celery_app = Celery(
    "trackmywork",
    broker="redis://localhost:6379/0",
    backend="redis://localhost:6379/0"
)

celery_app.conf.beat_schedule = {
    'check-reminders-every-minute': {
        'task': 'app.workers.tasks.process_due_reminders',
        'schedule': 60.0,  # Every 60 seconds
    },
}
```

### 8.2 Reminder Processing

```python
# workers/tasks.py
from app.workers.celery_app import celery_app
from datetime import datetime, timedelta
from app.db.session import get_db
from app.models.reminder import Reminder

@celery_app.task
def process_due_reminders():
    """Check and send due reminders"""
    db = next(get_db())

    now = datetime.utcnow()
    window_end = now + timedelta(minutes=1)

    # Find reminders due in the next minute
    due_reminders = db.query(Reminder).filter(
        Reminder.reminder_time <= window_end,
        Reminder.reminder_time > now,
        Reminder.is_sent == False
    ).all()

    for reminder in due_reminders:
        # Send notification (email, push, etc.)
        send_reminder_notification.delay(reminder.id)

        # Mark as sent
        reminder.is_sent = True
        db.commit()

@celery_app.task
def send_reminder_notification(reminder_id: str):
    """Send actual notification (email, push, etc.)"""
    # Implementation for sending notifications
    pass
```

---

## 9. Implementation Roadmap

### Phase 1: Foundation (Weeks 1-2)

**Week 1: Backend Setup**
- [ ] Initialize FastAPI project with Poetry
- [ ] Configure PostgreSQL database
- [ ] Set up Alembic for migrations
- [ ] Create base models (User, RefreshToken)
- [ ] Implement authentication system (JWT, password hashing)
- [ ] Create user registration and login endpoints
- [ ] Set up middleware (auth, error handling, CORS)
- [ ] Write unit tests for auth

**Week 2: Frontend Setup & Basic UI**
- [ ] Initialize Next.js 14 project with TypeScript
- [ ] Configure Tailwind CSS
- [ ] Create base UI components (Button, Input, Card, Modal)
- [ ] Implement auth pages (login, register)
- [ ] Set up Axios client with interceptors
- [ ] Implement JWT token management
- [ ] Create protected route wrapper
- [ ] Build basic dashboard layout

### Phase 2: Core Modules (Weeks 3-5)

**Week 3: Tasks Module**
- [ ] Create Task model and migrations
- [ ] Implement task CRUD endpoints
- [ ] Add filtering, pagination, sorting
- [ ] Create task service with ownership validation
- [ ] Build task UI components (list, form, card)
- [ ] Implement task calendar view
- [ ] Add task status/priority updates
- [ ] Write integration tests

**Week 4: Ideas & Finance Modules**
- [ ] Create Ideas model and endpoints
- [ ] Implement ideas CRUD with tagging
- [ ] Build ideas UI
- [ ] Create Finance Transaction model
- [ ] Implement finance CRUD endpoints
- [ ] Add financial summary calculations
- [ ] Build finance dashboard with charts
- [ ] Implement category-based filtering

**Week 5: Secure Notes & Encryption**
- [ ] Implement encryption service (AES-256)
- [ ] Create SecureNotes model
- [ ] Build notes CRUD endpoints with encryption/decryption
- [ ] Add key rotation support
- [ ] Build secure notes UI with warnings
- [ ] Implement copy-to-clipboard for credentials
- [ ] Test encryption/decryption flows

### Phase 3: Advanced Features (Weeks 6-7)

**Week 6: Reminders & Background Workers**
- [ ] Set up Redis
- [ ] Configure Celery
- [ ] Create Reminder model and endpoints
- [ ] Implement reminder worker task
- [ ] Build reminder UI
- [ ] Add notification system (email/in-app)
- [ ] Test reminder scheduling

**Week 7: Search & Dashboard**
- [ ] Implement global search service
- [ ] Create search endpoint with full-text search
- [ ] Build search UI with filtering
- [ ] Implement dashboard service
- [ ] Create dashlet components
- [ ] Add dashboard configuration
- [ ] Build stats calculations

### Phase 4: RBAC & Admin (Week 8)

- [ ] Implement permission decorators
- [ ] Add admin endpoints
- [ ] Create admin UI
- [ ] Implement user management
- [ ] Add system statistics
- [ ] Test all permission scenarios
- [ ] Document RBAC rules

### Phase 5: Polish & Deploy (Weeks 9-10)

**Week 9: Testing & Optimization**
- [ ] Write comprehensive test suite
- [ ] Add E2E tests (Playwright)
- [ ] Optimize database queries (indexing)
- [ ] Implement caching strategy
- [ ] Add API documentation (OpenAPI/Swagger)
- [ ] Performance testing
- [ ] Security audit

**Week 10: Deployment & Documentation**
- [ ] Create Docker images
- [ ] Set up Docker Compose
- [ ] Configure production environment
- [ ] Set up CI/CD pipeline
- [ ] Write user documentation
- [ ] Create deployment guide
- [ ] Launch!

---

## 10. Technical Stack Recommendations

### 10.1 Next.js vs React (SPA)

**Recommendation: Next.js 14 with App Router**

**Reasons:**
1. **SEO Benefits**: Server-side rendering for landing/marketing pages
2. **Performance**: Automatic code splitting, image optimization
3. **Developer Experience**: Built-in routing, API routes (if needed)
4. **Type Safety**: Excellent TypeScript support
5. **Modern Features**: React Server Components, streaming
6. **Production Ready**: Vercel's enterprise-grade hosting option

**When to use React SPA instead:**
- If app is 100% authenticated (no public pages)
- If you need maximum client-side control
- If deploying to static hosting only

For this project, **Next.js is recommended** because:
- Marketing/landing page can benefit from SSR
- Better initial load performance
- Future-proof for adding public features

### 10.2 State Management

**Recommendation: Zustand + React Query**

**Zustand** for:
- Global UI state (theme, sidebar open/closed)
- Auth state (user, tokens)
- Simple, minimal boilerplate

**React Query** for:
- Server state (tasks, finance, etc.)
- Automatic caching and refetching
- Optimistic updates
- Background synchronization

### 10.3 Database

**Recommendation: PostgreSQL 15+**

**Reasons:**
1. Excellent support for arrays (tags)
2. Full-text search capabilities (ts_vector)
3. JSON support for flexible fields
4. Row-Level Security (RLS)
5. Mature, production-proven
6. Great performance with proper indexing

### 10.4 ORM

**Recommendation: SQLAlchemy 2.0**

**Reasons:**
1. Mature, well-documented
2. Excellent async support
3. Type hints support
4. Flexible (Core + ORM)
5. Great migration tool (Alembic)

**Alternative: Prisma**
- Better TypeScript integration
- Excellent developer experience
- But less mature in Python ecosystem

### 10.5 Background Jobs

**Recommendation: Celery + Redis**

**Reasons:**
1. Industry standard
2. Robust task scheduling
3. Good monitoring tools (Flower)
4. Scalable

**Simpler Alternative: APScheduler**
- Good for smaller deployments
- Less infrastructure needed
- Easier to set up

---

## 11. Optional Enhancements

### 11.1 AI-Assisted Task Prioritization

**Implementation:**
```python
from openai import OpenAI

class TaskPrioritizer:
    def suggest_priority(self, task: Task, user_context: dict) -> str:
        """Use AI to suggest task priority based on context"""

        prompt = f"""
        Given the following task and user context, suggest a priority level.

        Task: {task.title}
        Description: {task.description}
        Due Date: {task.due_date}

        User Context:
        - Current pending tasks: {user_context['pending_tasks']}
        - Overdue tasks: {user_context['overdue_tasks']}
        - User's typical workflow: {user_context['patterns']}

        Suggest priority: low, medium, high, or urgent
        Provide brief reasoning.
        """

        # Call OpenAI API
        response = client.chat.completions.create(
            model="gpt-4",
            messages=[{"role": "user", "content": prompt}]
        )

        return response.choices[0].message.content
```

### 11.2 Smart Financial Categorization

**Implementation:**
```python
class FinanceCategorizer:
    def auto_categorize(self, description: str, amount: float) -> str:
        """Use ML to categorize transactions"""

        # Train on user's historical data
        # Use simple classifier or LLM

        categories = {
            "groceries": ["walmart", "safeway", "whole foods"],
            "utilities": ["electricity", "water", "gas", "internet"],
            "entertainment": ["netflix", "spotify", "movie", "concert"]
        }

        # Simple keyword matching or use ML model
        for category, keywords in categories.items():
            if any(kw in description.lower() for kw in keywords):
                return category

        return "uncategorized"
```

### 11.3 Analytics Dashboard

**Features:**
- Task completion trends (chart)
- Financial overview (monthly/yearly)
- Productivity metrics
- Time-to-completion for tasks
- Spending patterns visualization

**Implementation:**
```python
@router.get("/analytics/productivity")
async def get_productivity_analytics(
    period: str = "month",
    current_user: User = Depends(get_current_user)
):
    # Calculate metrics
    return {
        "task_completion_rate": 0.75,
        "average_completion_time": "2.5 days",
        "most_productive_day": "Tuesday",
        "tasks_by_priority": {...},
        "completion_trend": [...]
    }
```

### 11.4 Push Notifications

**Implementation using Firebase Cloud Messaging:**

```python
from firebase_admin import messaging

class NotificationService:
    def send_push_notification(self, user_id: str, title: str, body: str):
        # Get user's FCM token from database
        token = get_user_fcm_token(user_id)

        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body
            ),
            token=token
        )

        response = messaging.send(message)
        return response
```

### 11.5 Data Export/Import

**Features:**
- Export all user data to JSON/CSV
- Import from other apps (Todoist, Notion, etc.)
- Scheduled backups

### 11.6 Mobile App (React Native)

**Shared Components:**
- Use same API
- Share TypeScript types
- React Native with Expo

### 11.7 Collaboration Features (Future)

**If expanding beyond single-user:**
- Shared tasks/projects
- Team finance tracking
- Collaborative ideas board
- Comments and mentions

---

## 12. Non-Functional Requirements

### 12.1 Performance Targets

- API response time: < 200ms (p95)
- Database query time: < 100ms (p95)
- Frontend initial load: < 2s
- Search results: < 500ms

### 12.2 Security Standards

- HTTPS only in production
- Password requirements: min 8 chars, 1 uppercase, 1 number, 1 special
- JWT expiry: 1 hour (access), 7 days (refresh)
- Rate limiting on all auth endpoints
- SQL injection prevention (parameterized queries)
- XSS prevention (sanitize inputs)
- CSRF protection (SameSite cookies)

### 12.3 Scalability Considerations

- Database connection pooling
- Redis caching for frequently accessed data
- CDN for static assets
- Horizontal scaling capability (stateless API)
- Database read replicas for analytics

### 12.4 Monitoring & Logging

**Logging:**
- Structured logging (JSON format)
- Log levels: DEBUG, INFO, WARNING, ERROR, CRITICAL
- Never log sensitive data (passwords, tokens, encrypted content)

**Monitoring:**
- Application metrics (Prometheus)
- Error tracking (Sentry)
- Performance monitoring (New Relic/DataDog)
- Uptime monitoring

**Metrics to Track:**
- Request count and latency
- Error rates
- Database query performance
- Worker task processing time
- Active users
- Storage usage

---

## 13. Development Guidelines

### 13.1 Code Style

**Backend (Python):**
- Follow PEP 8
- Use type hints
- Max line length: 100
- Use Black for formatting
- Use Ruff for linting

**Frontend (TypeScript):**
- Follow Airbnb style guide
- Use ESLint + Prettier
- Prefer functional components
- Use TypeScript strict mode

### 13.2 Git Workflow

```
main (production)
  ↑
develop (staging)
  ↑
feature/task-module
feature/finance-module
hotfix/auth-bug
```

**Commit Message Format:**
```
type(scope): subject

body

footer
```

Types: feat, fix, docs, style, refactor, test, chore

### 13.3 Testing Strategy

**Backend:**
- Unit tests: 80%+ coverage
- Integration tests for endpoints
- Test fixtures for database
- Mock external services

**Frontend:**
- Component tests (React Testing Library)
- Integration tests
- E2E tests (Playwright)

### 13.4 Documentation

**Must Have:**
- API documentation (auto-generated from OpenAPI)
- README with setup instructions
- Architecture documentation (this file)
- Database schema documentation
- Deployment guide

**Nice to Have:**
- User guide
- Video tutorials
- Contributing guidelines

---

## 14. Deployment Architecture

### 14.1 Development Environment

```yaml
# docker-compose.yml
version: '3.8'

services:
  db:
    image: postgres:15
    environment:
      POSTGRES_DB: trackmywork
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  backend:
    build: ./backend
    ports:
      - "8000:8000"
    environment:
      DATABASE_URL: postgresql://user:password@db:5432/trackmywork
      REDIS_URL: redis://redis:6379/0
    depends_on:
      - db
      - redis
    volumes:
      - ./backend:/app

  celery:
    build: ./backend
    command: celery -A app.workers.celery_app worker -l info
    environment:
      DATABASE_URL: postgresql://user:password@db:5432/trackmywork
      REDIS_URL: redis://redis:6379/0
    depends_on:
      - db
      - redis

  celery-beat:
    build: ./backend
    command: celery -A app.workers.celery_app beat -l info
    environment:
      DATABASE_URL: postgresql://user:password@db:5432/trackmywork
      REDIS_URL: redis://redis:6379/0
    depends_on:
      - db
      - redis

  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    environment:
      NEXT_PUBLIC_API_URL: http://localhost:8000
    volumes:
      - ./frontend:/app
      - /app/node_modules

volumes:
  postgres_data:
```

### 14.2 Production Deployment

**Options:**

1. **Cloud Platforms (Recommended for MVP):**
   - **Backend**: Railway, Render, or Fly.io
   - **Frontend**: Vercel or Netlify
   - **Database**: Managed PostgreSQL (Supabase, Neon, or provider)
   - **Redis**: Upstash or provider's managed Redis

2. **Container Orchestration (For Scale):**
   - Kubernetes (GKE, EKS, AKS)
   - Docker Swarm (simpler alternative)

3. **Serverless (Alternative):**
   - AWS Lambda + API Gateway (backend)
   - Vercel (frontend)
   - Aurora Serverless (database)

**Recommended for This Project:**
- Vercel (Frontend)
- Railway or Render (Backend + Workers)
- Supabase (PostgreSQL)
- Upstash (Redis)

Total cost: ~$20-50/month for MVP with moderate usage

---

## 15. Success Metrics

### 15.1 Technical KPIs

- API uptime: 99.9%
- Average response time: < 200ms
- Error rate: < 0.1%
- Test coverage: > 80%
- Zero critical security vulnerabilities

### 15.2 User-Focused Metrics

- Daily active users
- Task completion rate
- Average session duration
- Feature adoption rates
- User retention (week 1, month 1, month 3)

---

## Conclusion

This architecture provides a comprehensive, production-ready foundation for TrackMyWork. The modular design allows for incremental development while maintaining scalability and security. The strict ownership model ensures user privacy, while the admin role provides necessary system oversight.

**Key Strengths:**
✅ Clear separation of concerns
✅ Comprehensive RBAC implementation
✅ Strong security (encryption, JWT, ownership validation)
✅ Scalable architecture
✅ Modern tech stack
✅ Detailed implementation roadmap

**Next Steps:**
1. Review and approve this architecture
2. Set up development environment
3. Begin Phase 1 implementation
4. Iterate based on feedback

**Estimated Timeline:** 10 weeks for full MVP
**Team Size:** 1-2 developers (full-stack)
**Total Effort:** ~400-500 hours

---

*Document Version: 1.0*
*Last Updated: 2025-11-19*
*Author: Senior Full-Stack Architect*
