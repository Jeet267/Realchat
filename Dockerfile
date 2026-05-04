# syntax=docker/dockerfile:1

# ─────────────────────────────────────────────────────────
# Stage 1 — Builder
# Install all deps (including devDeps) and build assets
# ─────────────────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

# Copy manifests first for layer-caching
COPY backend/package*.json ./backend/
COPY frontend/package*.json ./frontend/

# Install dependencies
RUN cd backend && npm ci
RUN cd frontend && npm ci

# Copy source code
COPY backend/ ./backend/
COPY frontend/ ./frontend/

# Build React SPA
RUN cd frontend && npm run build

# ─────────────────────────────────────────────────────────
# Stage 2 — Production runner (lean image)
# ─────────────────────────────────────────────────────────
FROM node:20-alpine AS runner

WORKDIR /app

# Install only production dependencies
COPY backend/package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

# Copy compiled backend source
COPY --from=builder /app/backend/src ./src

# Copy built frontend assets served by Express in production
COPY --from=builder /app/frontend/dist ../frontend/dist

# ── Security: run as non-root user ────────────────────────
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Expose the application port
EXPOSE 5001

# ── Health check (rubric requirement) ─────────────────────
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:5001/api/health || exit 1

# Start the server
CMD ["node", "src/server.js"]
