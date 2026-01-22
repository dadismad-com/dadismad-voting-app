# 🗳️ Voting App - Distributed Microservices Demo

A simple distributed voting application demonstrating microservices architecture with Docker. Vote between two options and see real-time results!

**Live Demo:** Cast votes and watch results update instantly across multiple services.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Step-by-Step Setup](#step-by-step-setup)
- [Accessing the Application](#accessing-the-application)
- [Common Commands](#common-commands)
- [Troubleshooting](#troubleshooting)
- [Technology Stack](#technology-stack)
- [Development](#development)
- [Deployment Options](#deployment-options)

---

## 🎯 Overview

This application demonstrates a microservices architecture with:
- **Vote Interface** - Cast your vote (Cats vs Dogs)
- **Result Interface** - See live voting results
- **Message Queue** - Asynchronous vote processing
- **Worker Service** - Background vote processor
- **Database** - Persistent vote storage

**Key Features:**
- ✅ Real-time result updates using WebSockets
- ✅ Polyglot architecture (Python, Node.js, .NET)
- ✅ Persistent data storage
- ✅ Automatic service recovery
- ✅ Health checks for all services

---

## 🚀 Quick Start

**TL;DR - Get running in 2 commands:**

```bash
# 1. Clone the repository
git clone https://github.com/dadismad-com/dadismad-voting-app.git
cd dadismad-voting-app

# 2. Start the application
docker compose up -d
```

**Access the app:**
- **Vote:** http://localhost:5002
- **Results:** http://localhost:5003

---

## 🏗️ Architecture

![Architecture Diagram](architecture.excalidraw.png)

### Data Flow

```
User → Vote App (Python) → Redis Queue → Worker (.NET) → PostgreSQL → Result App (Node.js) → User
```

### Services

| Service | Technology | Purpose | Port |
|---------|-----------|---------|------|
| **vote** | Python (Flask) | Voting interface | 5002 |
| **result** | Node.js (Express) | Results display | 5003 |
| **worker** | .NET Core | Vote processor | - |
| **redis** | Redis | Message queue | 6379 |
| **db** | PostgreSQL | Data persistence | 5432 |

---

## ✅ Prerequisites

### Required
- **Docker Desktop** (version 20.10 or higher)
  - [Download for Mac](https://docs.docker.com/desktop/install/mac-install/)
  - [Download for Windows](https://docs.docker.com/desktop/install/windows-install/)
  - [Download for Linux](https://docs.docker.com/desktop/install/linux-install/)
- **Docker Compose** (included with Docker Desktop)

### Optional
- **Git** - To clone the repository
- **kubectl** - If deploying to Kubernetes

### Verify Installation

```bash
# Check Docker version
docker --version
# Expected: Docker version 20.10.0 or higher

# Check Docker Compose version
docker compose version
# Expected: Docker Compose version v2.0.0 or higher

# Check Docker is running
docker ps
# Expected: List of running containers (or empty)
```

---

## 📖 Step-by-Step Setup

### Step 1: Clone the Repository

```bash
git clone https://github.com/dadismad-com/dadismad-voting-app.git
cd dadismad-voting-app
```

### Step 2: Start Docker Desktop

- Open Docker Desktop application
- Wait for Docker to be ready (green icon in system tray/menu bar)

### Step 3: Build and Start Services

```bash
# Build images and start all services in detached mode
docker compose up -d
```

**What happens:**
1. ✅ Docker builds 3 custom images (vote, result, worker)
2. ✅ Pulls Redis and PostgreSQL images
3. ✅ Creates network connections
4. ✅ Starts all 5 services
5. ✅ Runs health checks

**Expected output:**
```
✔ Network dadismad-voting-app_back-tier    Created
✔ Network dadismad-voting-app_front-tier   Created
✔ Container dadismad-voting-app-db-1       Started
✔ Container dadismad-voting-app-redis-1    Started
✔ Container dadismad-voting-app-vote-1     Started
✔ Container dadismad-voting-app-result-1   Started
✔ Container dadismad-voting-app-worker-1   Started
```

### Step 4: Verify Services are Running

```bash
# Check service status
docker compose ps
```

**Expected output:**
```
NAME                           STATUS
dadismad-voting-app-db-1       Up (healthy)
dadismad-voting-app-redis-1    Up (healthy)
dadismad-voting-app-result-1   Up
dadismad-voting-app-vote-1     Up (healthy)
dadismad-voting-app-worker-1   Up
```

### Step 5: Access the Application

- **Vote:** Open http://localhost:5002 in your browser
- **Results:** Open http://localhost:5003 in a new tab

**Test the app:**
1. Go to http://localhost:5002
2. Click on **Cats** or **Dogs**
3. Switch to http://localhost:5003
4. Watch the results update in real-time! ✨

---

## 🌐 Accessing the Application

### Vote Interface (Port 5002)
**URL:** http://localhost:5002

**Features:**
- Choose between two options (Cats vs Dogs by default)
- Change your vote anytime
- Cookie-based vote tracking
- Shows which option you selected

### Result Interface (Port 5003)
**URL:** http://localhost:5003

**Features:**
- Real-time vote percentages
- Live updates via WebSockets
- No page refresh needed
- Visual percentage bars

---

## 🛠️ Common Commands

### Basic Operations

```bash
# Start the application
docker compose up -d

# Stop the application
docker compose down

# Stop and remove all data (including votes)
docker compose down -v

# Rebuild and restart
docker compose up -d --build

# View logs from all services
docker compose logs -f

# View logs from a specific service
docker compose logs -f vote
docker compose logs -f result
docker compose logs -f worker
```

### Monitoring

```bash
# Check service status
docker compose ps

# Check resource usage
docker stats

# Inspect a specific service
docker compose logs vote --tail=50

# Follow logs in real-time
docker compose logs -f
```

### Debugging

```bash
# Restart a specific service
docker compose restart vote

# Execute command in running container
docker compose exec db psql -U postgres -c "SELECT * FROM votes;"

# Check Redis queue
docker compose exec redis redis-cli LLEN votes

# View worker processing
docker compose logs worker --tail=20 -f
```

### Data Management

```bash
# View current votes in database
docker compose exec db psql -U postgres -c "SELECT vote, COUNT(*) FROM votes GROUP BY vote;"

# Clear all votes (reset database)
docker compose down -v && docker compose up -d

# Backup database
docker compose exec db pg_dump -U postgres > backup.sql
```

---

## 🔧 Troubleshooting

### Issue: Port Already in Use

**Error:**
```
Error: ports are not available: exposing port TCP 0.0.0.0:5002 -> 0.0.0.0:0: listen tcp 0.0.0.0:5002: bind: address already in use
```

**Solution:**
```bash
# Find what's using the port
lsof -i :5002

# Kill the process (replace PID with actual process ID)
kill -9 PID

# Or change ports in docker-compose.yml
# Edit the ports section:
#   ports:
#     - "5004:80"  # Use different port
```

### Issue: Services Not Starting

**Error:** Container exits immediately or stays in "starting" state

**Solution:**
```bash
# Check logs for specific service
docker compose logs vote

# Common causes:
# 1. Dependency not ready - wait for health checks
# 2. Code error - check logs for error messages
# 3. Port conflict - change ports in docker-compose.yml

# Restart services
docker compose restart
```

### Issue: Docker Daemon Not Running

**Error:**
```
Cannot connect to the Docker daemon. Is the docker daemon running?
```

**Solution:**
- Open Docker Desktop application
- Wait for it to fully start
- Check Docker icon in system tray (should be green)

### Issue: Database Connection Errors

**Symptoms:** Worker or Result service can't connect to database

**Solution:**
```bash
# Check if database is healthy
docker compose ps db

# Restart database
docker compose restart db

# Check database logs
docker compose logs db
```

### Issue: Votes Not Appearing in Results

**Check:**
1. Worker service is running
2. Redis has votes queued
3. Database has connectivity

**Debug:**
```bash
# Check worker logs
docker compose logs worker

# Check Redis queue length
docker compose exec redis redis-cli LLEN votes

# Check database votes
docker compose exec db psql -U postgres -c "SELECT COUNT(*) FROM votes;"
```

### macOS Specific: Port 5000 Conflict

Port 5000 is used by macOS Control Center (AirPlay Receiver). This app uses ports 5002 and 5003 instead.

**If you need to use port 5000:**
- Disable AirPlay Receiver in System Settings → General → AirDrop & Handoff
- Or modify `docker-compose.yml` to use different ports

---

## 💻 Technology Stack

### Frontend Services

**Vote App (Python)**
- Framework: Flask
- Purpose: User voting interface
- Dependencies: Flask, Redis client, Gunicorn

**Result App (Node.js)**
- Framework: Express.js
- Real-time: Socket.io
- Purpose: Live results dashboard
- Dependencies: Express, Socket.io, PostgreSQL client

### Backend Services

**Worker (.NET)**
- Runtime: .NET 7
- Purpose: Process votes from queue to database
- Dependencies: Npgsql, StackExchange.Redis, Newtonsoft.Json

**Redis**
- Version: Alpine (lightweight)
- Purpose: Message queue for votes

**PostgreSQL**
- Version: 15 Alpine
- Purpose: Persistent vote storage

---

## 🔨 Development

### Running in Development Mode

The default `docker compose up` runs in development mode with:
- Hot reload enabled (file watching)
- Debug logging
- Volume mounts for live code updates
- Debug ports exposed

### Making Code Changes

**Vote App (Python):**
```bash
# Edit files in ./vote/
# Changes auto-reload (Flask debug mode)
```

**Result App (Node.js):**
```bash
# Edit files in ./result/
# Nodemon watches for changes and restarts
```

**Worker (.NET):**
```bash
# Edit files in ./worker/
# Rebuild required:
docker compose up -d --build worker
```

### Customizing Vote Options

Edit environment variables in `vote/app.py`:

```python
option_a = os.getenv('OPTION_A', "Cats")
option_b = os.getenv('OPTION_B', "Dogs")
```

Or set in `docker-compose.yml`:

```yaml
vote:
  environment:
    - OPTION_A=Pizza
    - OPTION_B=Tacos
```

### Running Tests

```bash
# Result service tests
cd result
docker compose -f docker-compose.test.yml up
```

---

## 🚀 Deployment Options

### Docker Swarm

```bash
# Initialize swarm
docker swarm init

# Deploy stack
docker stack deploy --compose-file docker-stack.yml vote

# Check services
docker stack services vote

# Remove stack
docker stack rm vote
```

### Kubernetes

```bash
# Deploy all services
kubectl create -f k8s-specifications/

# Check deployments
kubectl get deployments
kubectl get services
kubectl get pods

# Access services
# Vote: http://<node-ip>:31000
# Result: http://<node-ip>:31001

# Remove deployments
kubectl delete -f k8s-specifications/
```

### Production Considerations

Before deploying to production:

1. **Security**
   - [ ] Change default database passwords
   - [ ] Add authentication/authorization
   - [ ] Enable HTTPS/TLS
   - [ ] Implement rate limiting
   - [ ] Add input validation

2. **Scalability**
   - [ ] Scale worker instances
   - [ ] Add load balancer
   - [ ] Implement caching
   - [ ] Optimize database queries

3. **Monitoring**
   - [ ] Add logging aggregation
   - [ ] Set up health monitoring
   - [ ] Configure alerting
   - [ ] Add metrics collection

4. **Data**
   - [ ] Configure database backups
   - [ ] Set up disaster recovery
   - [ ] Implement data retention policy

---

## 📝 Notes

### Vote Persistence
- Each browser/client can vote once (tracked via cookies)
- Votes can be changed anytime
- Same voter_id updates existing vote instead of creating new one
- Data persists across container restarts (Docker volumes)

### Network Architecture
- **front-tier**: Vote and Result services communicate with users
- **back-tier**: Worker, Redis, and Database communicate internally
- Services isolated for security and performance

### Educational Purpose
This application is designed for learning microservices architecture. It demonstrates:
- Service communication patterns
- Message queue usage
- Database persistence
- Real-time updates
- Container orchestration

---

## 📚 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Code Review Report](CODE_REVIEW_REPORT.md)

---

## 🤝 Contributing

Issues and pull requests are welcome! Please check existing issues before creating new ones.

---

## 📄 License

See [LICENSE](LICENSE) file for details.

---

## 🆘 Need Help?

1. Check the [Troubleshooting](#troubleshooting) section
2. Review service logs: `docker compose logs`
3. Verify Docker is running: `docker ps`
4. Check [CODE_REVIEW_REPORT.md](CODE_REVIEW_REPORT.md) for known issues

---

**Made with ❤️ for learning Docker and microservices**

**Repository:** https://github.com/dadismad-com/dadismad-voting-app
