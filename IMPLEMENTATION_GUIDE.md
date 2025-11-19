# TrackMyWork - Implementation Quick Start Guide

## Prerequisites

Before you begin, ensure you have:

- **Python 3.11+** installed
- **Node.js 18+** and npm/yarn
- **PostgreSQL 15+** installed and running
- **Redis** installed and running
- **Git** for version control
- **Docker & Docker Compose** (optional, but recommended)

---

## Setup Instructions

### Option 1: Docker Setup (Recommended)

#### 1. Clone the repository
```bash
git clone <repository-url>
cd TrackMyWork
```

#### 2. Create environment files

**Backend `.env`:**
```bash
# backend/.env
DATABASE_URL=postgresql://trackmywork:trackmywork123@db:5432/trackmywork
REDIS_URL=redis://redis:6379/0
SECRET_KEY=your-super-secret-jwt-key-change-this-in-production
ENCRYPTION_KEY=your-32-byte-encryption-key-base64-encoded
ACCESS_TOKEN_EXPIRE_MINUTES=60
REFRESH_TOKEN_EXPIRE_DAYS=7
ENVIRONMENT=development
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8000
```

**Frontend `.env.local`:**
```bash
# frontend/.env.local
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_APP_NAME=TrackMyWork
```

#### 3. Start all services
```bash
docker-compose up -d
```

This will start:
- PostgreSQL (port 5432)
- Redis (port 6379)
- Backend API (port 8000)
- Celery worker
- Celery beat (scheduler)
- Frontend (port 3000)

#### 4. Run database migrations
```bash
docker-compose exec backend alembic upgrade head
```

#### 5. Access the application
- Frontend: http://localhost:3000
- Backend API: http://localhost:8000
- API Docs: http://localhost:8000/docs

---

### Option 2: Manual Setup

#### Backend Setup

##### 1. Create virtual environment
```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

##### 2. Install dependencies
```bash
pip install poetry
poetry install
```

Or using pip:
```bash
pip install -r requirements.txt
```

##### 3. Set up environment variables
Create `backend/.env` file (see Docker setup above for template)

##### 4. Initialize database
```bash
# Create database
createdb trackmywork

# Run migrations
alembic upgrade head
```

##### 5. Start backend server
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

##### 6. Start Celery worker (in separate terminal)
```bash
celery -A app.workers.celery_app worker -l info
```

##### 7. Start Celery beat (in separate terminal)
```bash
celery -A app.workers.celery_app beat -l info
```

#### Frontend Setup

##### 1. Install dependencies
```bash
cd frontend
npm install
# or
yarn install
```

##### 2. Set up environment variables
Create `frontend/.env.local` (see Docker setup above)

##### 3. Start development server
```bash
npm run dev
# or
yarn dev
```

##### 4. Access frontend
http://localhost:3000

---

## Project Structure Creation

### Create Backend Structure

```bash
mkdir -p backend/{alembic/versions,app/{api/v1,core,db,models,schemas,services,workers,middleware,utils},tests}

# Create __init__.py files
touch backend/app/__init__.py
touch backend/app/api/__init__.py
touch backend/app/api/v1/__init__.py
touch backend/app/core/__init__.py
touch backend/app/db/__init__.py
touch backend/app/models/__init__.py
touch backend/app/schemas/__init__.py
touch backend/app/services/__init__.py
touch backend/app/workers/__init__.py
touch backend/app/middleware/__init__.py
touch backend/app/utils/__init__.py
touch backend/tests/__init__.py
```

### Create Frontend Structure

```bash
mkdir -p frontend/src/{app/{(auth)/{login,register},(dashboard)/{dashboard,tasks,ideas,finance,notes,reminders,search},admin},components/{ui,layout,dashboard,tasks,finance,common},lib/{api,auth,utils},hooks,stores,types,styles}
```

---

## Implementation Steps

Follow the implementation roadmap from ARCHITECTURE.md:

### Phase 1: Foundation (Week 1-2)

#### Week 1: Backend Foundation

1. **Create main FastAPI app**
   ```bash
   # backend/app/main.py
   ```

2. **Set up database connection**
   ```bash
   # backend/app/db/session.py
   # backend/app/db/base.py
   ```

3. **Create User model**
   ```bash
   # backend/app/models/user.py
   ```

4. **Implement authentication**
   ```bash
   # backend/app/core/security.py
   # backend/app/services/auth_service.py
   # backend/app/api/v1/auth.py
   ```

5. **Add middleware**
   ```bash
   # backend/app/middleware/auth.py
   # backend/app/middleware/error_handler.py
   ```

6. **Run initial migration**
   ```bash
   alembic revision --autogenerate -m "Initial user and auth tables"
   alembic upgrade head
   ```

#### Week 2: Frontend Foundation

1. **Set up Next.js app**
   ```bash
   # Already done with npx create-next-app@latest
   ```

2. **Create base UI components**
   ```bash
   # frontend/src/components/ui/Button.tsx
   # frontend/src/components/ui/Input.tsx
   # etc.
   ```

3. **Implement auth pages**
   ```bash
   # frontend/src/app/(auth)/login/page.tsx
   # frontend/src/app/(auth)/register/page.tsx
   ```

4. **Set up API client**
   ```bash
   # frontend/src/lib/api/client.ts
   # frontend/src/lib/api/auth.ts
   ```

5. **Create auth store**
   ```bash
   # frontend/src/stores/authStore.ts
   ```

---

## Testing

### Backend Tests

```bash
# Run all tests
cd backend
pytest

# Run with coverage
pytest --cov=app --cov-report=html

# Run specific test file
pytest tests/test_auth.py
```

### Frontend Tests

```bash
# Run all tests
cd frontend
npm test

# Run with coverage
npm test -- --coverage

# Run E2E tests
npm run test:e2e
```

---

## Development Workflow

### 1. Create a new feature

```bash
# Create feature branch
git checkout -b feature/task-module

# Make changes
# ... code ...

# Run tests
pytest  # backend
npm test  # frontend

# Commit changes
git add .
git commit -m "feat(tasks): implement task CRUD endpoints"

# Push to remote
git push origin feature/task-module
```

### 2. Database migration workflow

```bash
# After modifying models
cd backend

# Create migration
alembic revision --autogenerate -m "Add tasks table"

# Review migration file in alembic/versions/

# Apply migration
alembic upgrade head

# Rollback if needed
alembic downgrade -1
```

### 3. API development workflow

1. Define Pydantic schema in `schemas/`
2. Create SQLAlchemy model in `models/`
3. Implement service logic in `services/`
4. Create API endpoint in `api/v1/`
5. Write tests in `tests/`
6. Update API documentation

### 4. Frontend development workflow

1. Create TypeScript types in `types/`
2. Implement API client function in `lib/api/`
3. Create React components in `components/`
4. Build page in `app/`
5. Add tests

---

## Environment Configuration

### Development

```bash
# Backend
ENVIRONMENT=development
DEBUG=True
LOG_LEVEL=DEBUG

# Frontend
NEXT_PUBLIC_ENV=development
```

### Production

```bash
# Backend
ENVIRONMENT=production
DEBUG=False
LOG_LEVEL=INFO
SECRET_KEY=<strong-random-key>
DATABASE_URL=<production-db-url>
REDIS_URL=<production-redis-url>
ALLOWED_ORIGINS=https://yourdomain.com

# Frontend
NEXT_PUBLIC_ENV=production
NEXT_PUBLIC_API_URL=https://api.yourdomain.com
```

---

## Deployment Checklist

### Pre-deployment

- [ ] All tests passing
- [ ] Environment variables configured
- [ ] Database migrations applied
- [ ] Security audit completed
- [ ] Performance testing done
- [ ] Documentation updated

### Backend Deployment

- [ ] Build Docker image
- [ ] Push to container registry
- [ ] Configure production database
- [ ] Set up Redis
- [ ] Deploy to hosting platform
- [ ] Run migrations
- [ ] Start Celery workers
- [ ] Configure monitoring

### Frontend Deployment

- [ ] Build Next.js app (`npm run build`)
- [ ] Test production build locally
- [ ] Deploy to Vercel/Netlify
- [ ] Configure environment variables
- [ ] Set up CDN
- [ ] Test deployment

---

## Troubleshooting

### Common Issues

#### Database connection fails
```bash
# Check PostgreSQL is running
pg_isready

# Check connection string
echo $DATABASE_URL

# Test connection
psql $DATABASE_URL
```

#### Redis connection fails
```bash
# Check Redis is running
redis-cli ping

# Should return: PONG
```

#### Migration conflicts
```bash
# Reset to specific revision
alembic downgrade <revision>

# Delete migration file and recreate
rm alembic/versions/<file>.py
alembic revision --autogenerate -m "New migration"
```

#### Frontend won't connect to backend
```bash
# Check CORS settings in backend
# Ensure NEXT_PUBLIC_API_URL is correct
# Check network tab in browser DevTools
```

---

## Monitoring & Logging

### View logs

```bash
# Backend logs (Docker)
docker-compose logs -f backend

# Celery logs
docker-compose logs -f celery

# Frontend logs
docker-compose logs -f frontend

# Database logs
docker-compose logs -f db
```

### Monitor Celery

```bash
# Install Flower
pip install flower

# Start Flower
celery -A app.workers.celery_app flower

# Access: http://localhost:5555
```

---

## Performance Optimization

### Backend

1. **Enable query logging** (development only)
   ```python
   # In main.py
   logging.getLogger('sqlalchemy.engine').setLevel(logging.INFO)
   ```

2. **Add database connection pooling**
   ```python
   # In db/session.py
   engine = create_engine(
       DATABASE_URL,
       pool_size=20,
       max_overflow=40
   )
   ```

3. **Enable caching**
   ```python
   # Use Redis for caching frequent queries
   ```

### Frontend

1. **Enable image optimization**
   ```javascript
   // next.config.js
   module.exports = {
     images: {
       domains: ['yourdomain.com'],
     },
   }
   ```

2. **Code splitting**
   ```javascript
   // Use dynamic imports
   const Component = dynamic(() => import('./Component'))
   ```

---

## Security Best Practices

1. **Never commit secrets**
   - Use `.env` files
   - Add `.env` to `.gitignore`

2. **Use strong passwords**
   - Minimum 8 characters
   - Mix of uppercase, lowercase, numbers, symbols

3. **Enable HTTPS in production**

4. **Regular security updates**
   ```bash
   # Backend
   poetry update

   # Frontend
   npm audit
   npm audit fix
   ```

5. **Rate limiting**
   - Already configured in middleware
   - Adjust limits as needed

---

## Next Steps

After completing the setup:

1. ✅ Read ARCHITECTURE.md thoroughly
2. ✅ Review database-schema.sql
3. ✅ Start with Phase 1 implementation
4. ✅ Create your first feature (User authentication)
5. ✅ Test thoroughly
6. ✅ Move to Phase 2 (Core modules)

---

## Resources

- **FastAPI Documentation**: https://fastapi.tiangolo.com/
- **Next.js Documentation**: https://nextjs.org/docs
- **PostgreSQL Documentation**: https://www.postgresql.org/docs/
- **SQLAlchemy Documentation**: https://docs.sqlalchemy.org/
- **Celery Documentation**: https://docs.celeryproject.org/

---

## Getting Help

If you encounter issues:

1. Check the troubleshooting section above
2. Review logs for error messages
3. Consult the documentation
4. Check GitHub issues
5. Ask in community forums

---

**Good luck with your implementation! 🚀**
