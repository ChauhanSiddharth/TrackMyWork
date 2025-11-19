# TrackMyWork

> A comprehensive personal productivity and finance management application

**TrackMyWork** is a full-stack web application that consolidates task management, idea tracking, financial oversight, secure note-keeping, and intelligent reminders into a single, secure platform with strict ownership-based access control.

---

## 📋 Overview

TrackMyWork helps you manage your entire personal productivity and financial life in one place:

- ✅ **To-Do List Manager** - Track tasks with priorities, due dates, and status
- 💡 **Ideas Manager** - Capture and organize future project ideas
- 📊 **Finance Module** - Track income, expenses, savings, and investments
- 🔒 **Secure Notes** - Store sensitive credentials with AES-256 encryption
- 🔔 **Reminders** - Never miss important deadlines or events
- 🔍 **Global Search** - Find anything across all modules instantly
- 📱 **Dashboard** - Beautiful overview of all your recent activities

---

## 🚀 Quick Start

### Prerequisites

- Python 3.11+
- Node.js 18+
- PostgreSQL 15+
- Redis
- Docker & Docker Compose (optional, but recommended)

### Using Docker (Recommended)

```bash
# Clone the repository
git clone <repository-url>
cd TrackMyWork

# Create environment files (see IMPLEMENTATION_GUIDE.md for details)
cp backend/.env.example backend/.env
cp frontend/.env.local.example frontend/.env.local

# Start all services
docker-compose up -d

# Run database migrations
docker-compose exec backend alembic upgrade head

# Access the application
# Frontend: http://localhost:3000
# Backend API: http://localhost:8000
# API Docs: http://localhost:8000/docs
```

For detailed setup instructions, see [IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md).

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| **[ARCHITECTURE.md](./ARCHITECTURE.md)** | Complete system architecture, database schema, API specifications, and implementation roadmap |
| **[IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md)** | Step-by-step setup instructions and development workflow |
| **[RBAC_DIAGRAM.md](./RBAC_DIAGRAM.md)** | Role-based access control rules and permission matrix |
| **[TECH_STACK.md](./TECH_STACK.md)** | Technology stack analysis, comparisons, and recommendations |
| **[database-schema.sql](./database-schema.sql)** | Complete PostgreSQL database schema with indexes and constraints |
| **[docker-compose.yml](./docker-compose.yml)** | Docker Compose configuration for local development |

---

## 🏗️ Architecture

### High-Level Overview

```
┌─────────────┐
│   Next.js   │  Frontend (TypeScript + Tailwind CSS)
│  Frontend   │
└──────┬──────┘
       │ REST API
┌──────▼──────┐
│   FastAPI   │  Backend (Python + Pydantic)
│   Backend   │
└──────┬──────┘
       │
   ┌───┴────┬──────────┐
   │        │          │
┌──▼───┐ ┌─▼─────┐ ┌──▼─────┐
│ PG   │ │ Redis │ │ Celery │
│ SQL  │ │       │ │ Worker │
└──────┘ └───────┘ └────────┘
```

### Technology Stack

**Backend:**
- FastAPI (Python 3.11+)
- PostgreSQL 15+
- SQLAlchemy 2.0
- Celery + Redis (background tasks)
- JWT Authentication
- AES-256 Encryption

**Frontend:**
- Next.js 14 (App Router)
- TypeScript
- Tailwind CSS
- Zustand (state management)
- React Query (server state)
- React Hook Form + Zod

**Infrastructure:**
- Docker + Docker Compose
- Redis (cache + message broker)
- PostgreSQL (database)

For detailed technology analysis, see [TECH_STACK.md](./TECH_STACK.md).

---

## 🔑 Key Features

### 1. Task Management
- Create, edit, delete tasks
- Priority levels (low, medium, high, urgent)
- Status tracking (pending, in progress, completed, cancelled)
- Due dates with calendar view
- Tags for organization
- Completion tracking

### 2. Ideas Management
- Store future project ideas
- Categorization and tagging
- Status tracking (new, under consideration, planned, archived)
- Full-text search

### 3. Finance Tracking
- Track income, expenses, savings, and investments
- Category-based organization
- Monthly and annual reports
- Spending analysis by category
- Transaction search and filtering
- Financial summary dashboard

### 4. Secure Notes
- AES-256 encrypted storage
- Store sensitive credentials securely
- Only accessible by owner (even admins cannot access)
- Tag-based organization

### 5. Reminders
- Create reminders for tasks and events
- Background worker processes due reminders
- Notifications via email or in-app
- Link reminders to other entities (tasks, ideas, etc.)

### 6. Global Search
- Search across all modules (tasks, ideas, finance, notes)
- Full-text search with highlighting
- Filter by module type
- Fast results with indexing

### 7. Dashboard
- Configurable dashlets
- Recent tasks, expenses, ideas, and reminders
- Quick statistics
- Beautiful, responsive design

---

## 🔐 Security & RBAC

### User Roles

**Admin User:**
- View all users and system statistics
- Activate/deactivate accounts
- Access aggregate reports
- **Cannot** access user's secure notes
- **Cannot** modify user data

**Regular User:**
- Full CRUD on own records
- Complete data privacy
- No cross-user visibility

### Security Features

- ✅ JWT Authentication (access + refresh tokens)
- ✅ AES-256 Encryption for secure notes
- ✅ Ownership-based access control
- ✅ Rate limiting on sensitive endpoints
- ✅ Password hashing with bcrypt
- ✅ CORS protection
- ✅ Input validation with Pydantic

For complete RBAC documentation, see [RBAC_DIAGRAM.md](./RBAC_DIAGRAM.md).

---

## 🗄️ Database Schema

### Core Tables

- `users` - User accounts and authentication
- `tasks` - Task management
- `ideas` - Project ideas
- `finance_transactions` - Financial records
- `secure_notes` - Encrypted notes
- `reminders` - Scheduled reminders
- `refresh_tokens` - JWT refresh token management
- `dashboard_configs` - User dashboard preferences

### Key Features

- Full-text search indexes
- Array support for tags
- Ownership enforcement via foreign keys
- Automatic timestamp tracking
- Row-level security (optional)

See [database-schema.sql](./database-schema.sql) for complete schema.

---

## 🛣️ Implementation Roadmap

### Phase 1: Foundation (Weeks 1-2)
- ✅ Backend setup (FastAPI, PostgreSQL, Auth)
- ✅ Frontend setup (Next.js, TypeScript, Tailwind)
- ✅ Authentication system

### Phase 2: Core Modules (Weeks 3-5)
- ✅ Tasks module
- ✅ Ideas module
- ✅ Finance module
- ✅ Secure notes with encryption

### Phase 3: Advanced Features (Weeks 6-7)
- ✅ Reminders & background workers
- ✅ Global search
- ✅ Dashboard with dashlets

### Phase 4: RBAC & Admin (Week 8)
- ✅ Permission system
- ✅ Admin panel
- ✅ User management

### Phase 5: Polish & Deploy (Weeks 9-10)
- ✅ Testing & optimization
- ✅ Documentation
- ✅ Deployment

**Estimated Timeline:** 10 weeks for full MVP

See [ARCHITECTURE.md](./ARCHITECTURE.md) for detailed roadmap.

---

## 🧪 Testing

### Backend Tests

```bash
cd backend
pytest
pytest --cov=app --cov-report=html
```

### Frontend Tests

```bash
cd frontend
npm test
npm test -- --coverage
npm run test:e2e
```

---

## 📦 Deployment

### Recommended Deployment

| Component | Platform | Cost |
|-----------|----------|------|
| Frontend | Vercel | Free tier |
| Backend | Railway/Render | $7-20/mo |
| Database | Supabase/Neon | Free tier |
| Redis | Upstash | Free tier |
| **Total** | - | **$0-20/month** |

### Alternative: Self-Hosted

Use the included `docker-compose.yml` to deploy to any VPS (DigitalOcean, AWS, etc.)

For deployment instructions, see [IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md).

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📝 API Documentation

Once the backend is running, access the auto-generated API documentation at:

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

---

## 🔧 Development

### Backend Development

```bash
cd backend
python -m venv venv
source venv/bin/activate
poetry install
uvicorn app.main:app --reload
```

### Frontend Development

```bash
cd frontend
npm install
npm run dev
```

### Database Migrations

```bash
cd backend
alembic revision --autogenerate -m "Description"
alembic upgrade head
```

---

## 📊 Project Status

- [x] Architecture design
- [x] Database schema
- [x] API specification
- [x] RBAC design
- [x] Tech stack selection
- [ ] Backend implementation
- [ ] Frontend implementation
- [ ] Testing
- [ ] Deployment

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

Designed and architected by a Senior Full-Stack Architect

---

## 🙏 Acknowledgments

- FastAPI for the excellent framework
- Next.js team for the best React framework
- PostgreSQL community for the robust database
- All open-source contributors

---

## 📞 Support

For questions, issues, or feature requests, please open an issue on GitHub.

---

**Built with ❤️ using modern web technologies**
