# Automated Architecture Benchmark

**One Pipeline. Four Designs. Real Metrics.**

- [Automated Architecture Benchmark](#automated-architecture-benchmark)
  - [Project Overview](#project-overview)
  - [Benchmark Scenario](#benchmark-scenario)
  - [Architecture Overview](#architecture-overview)
    - [Baseline – Classic Architecture](#baseline--classic-architecture)
    - [Scale – Auto-Scaling Architecture](#scale--auto-scaling-architecture)
    - [Redis – Caching Architecture](#redis--caching-architecture)
    - [Kafka – Event-Driven Architecture](#kafka--event-driven-architecture)
  - [Key Findings](#key-findings)
  - [Automated Benchmarking Pipeline - GitHub Actions](#automated-benchmarking-pipeline---github-actions)
  - [Observability - Grafana Dashboard](#observability---grafana-dashboard)
  - [Tech Stack](#tech-stack)

---

## Project Overview

- [Project Website](https://benchmark.arguswatcher.net/)

An project to **automate deployment and load testing**, and **compare 4 cloud architecture patterns** under identical traffic conditions:

- **Baseline** – Single service
- **Scale** – Horizontal auto-scaling
- **Redis** – Caching layer added
- **Kafka** – Event-driven write path

This project benchmarks **performance**, **scalability**, and **operational trade-offs** using controlled load testing and real-time monitoring.

Each architecture is deployed using the **same workload** and tested under **identical traffic patterns** to ensure fair comparison.

---

## Benchmark Scenario

To ensure consistency, all architectures were tested with:

- **Traffic Pattern:** 1:1 Read/Write
- **Ramp Up:** 0 → 1000 requests/sec over 10 minutes
- **Sustain:** 1000 requests/sec for 5 minutes
- **Ramp Down:** 1 minute

- **Metrics Collected**
  - `Throughput (RPS)`
  - `p95 Response Time`
  - `HTTP Failure Rate`
  - `Application Scaling Behavior`
  - `Database CPU Utilization`

**Same workload. Same duration. Only the architecture changes.**

---

## Architecture Overview

### Baseline – Classic Architecture

Simple to implement but lacks scalability.

- [Note: Baseline](./docs/baseline/baseline.md)

![baseline](./app/html/img/diagram/baseline.gif)

### Scale – Auto-Scaling Architecture

Handles growth but increases direct database pressure.

- [Note: Scale](./docs/scale/scale.md)

![scale](./app/html/img/diagram/scale.gif)

### Redis – Caching Architecture

Improves read performance and reduces database load.

- [Note: Redis](./docs/redis/redis.md)

![redis](./app/html/img/diagram/redis.gif)

### Kafka – Event-Driven Architecture

Stabilizes database usage and improves write performance at the cost of higher complexity.

- [Note: Kafka](./docs/kafka/kafka.md)

![kafka](./app/html/img/diagram/kafka.gif)

---

## Key Findings

- **Technical Comparison**

| Architecture | RPS(Peak) | HTTP Failures | P95 Response Time | Task | Database CPU%             |
| ------------ | --------- | ------------- | ----------------- | ---- | ------------------------- |
| Baseline     | 320       | 34.6%         | 3000ms            | 1    | 19.2% (Backend Saturated) |
| Scale        | 1k        | ~0%           | 70ms              | 18   | 48.6%                     |
| Redis        | 1k        | ~0%           | 75ms              | 16   | 34.9%                     |
| Kafka        | 1k        | ~0%           | 25ms              | 10   | 15.8%                     |

> - **Highlights**
>   - `Baseline` **failed** under moderate load.
>   - `Auto-scaling` **eliminated** failures but **increased** database stress.
>   - `Redis` **reduced** read pressure.
>   - `Kafka` achieved the **most stable database behavior** under mixed traffic.

- **Business Insight**

| Architecture | Business Continuity | Database Overload Risk | Operational Cost | Operational Complexity |
| ------------ | ------------------- | ---------------------- | ---------------- | ---------------------- |
| Baseline     | ❌ Low              | 🔴 High                | 🟢 Low           | 🟢 Low                 |
| Scale        | 🟢 High             | 🟠 Medium–High         | 🟠 Medium        | 🟠 Medium              |
| Redis        | 🟢 High             | 🟡 Medium              | 🟠 Medium        | 🟠 Medium              |
| Kafka        | 🟢 Very High        | 🟢 Low                 | 🔴 Higher        | 🔴 High                |

---

## Automated Benchmarking Pipeline - GitHub Actions

A fully automated workflow ensures repeatable and consistent evaluation.

**Pipeline Steps:**

1. **Provision** infrastructure
2. **Deploy** selected architecture
3. Execute controlled **load testing**
4. **Capture** metrics and generate report
5. **Upload** results to Amazon S3
6. **Tear down** infrastructure

This eliminates manual setup and ensures fair comparison across architectures.

- GitHub Actions Workflows: `.github/workflows/`

---

## Observability - Grafana Dashboard

System behavior is monitored in real time using:

- Grafana dashboards
- Infrastructure metrics
- Database utilization tracking
- Scaling activity visualization

Metric Snapshot:
👉 [Full Metrics Dashboard Snapshot](https://simonangelfong.grafana.net/dashboard/snapshot/RyoJLicAercSDvhV4hlXTyShGWmparsq?orgId=1&from=2026-02-16T05:40:00.000Z&to=2026-02-16T06:20:00.000Z&timezone=browser&refresh=5s)
👉 [Load Testing Metrics Dashboard Snapshot](https://simonangelfong.grafana.net/dashboard/snapshot/b6BR7QaYAsKWGLrnGUj7PTscC3pNbpcK?orgId=1&from=2026-02-16T05:45:00.000Z&to=2026-02-16T06:20:00.000Z&timezone=browser&refresh=5s)

---

## Tech Stack

- Docker
- AWS ECS / RDS / ElastiCache / MSK
- GitHub Actions
- k6 Load Testing
- Grafana Monitoring
- Python / FastAPI (Backend API)
