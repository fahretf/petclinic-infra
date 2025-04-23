# Petclinic Infrastructure Deployment (DevOps Demo)

This repository demonstrates the containerized deployment, monitoring and logging of the Petclinic application using popular DevOps tools

> ⚠️ The frontend and backend application code were not developed by me. They are based on two Spring PetClinic repositories and used here for DevOps purposes.

---

## Tech stack:

- **Docker, Docker Compose**: Containerized frontend, backend, PostgreSQL, and monitoring services (Prometheus, Grafana, etc.)
- **NGINX**: Acts as a reverse proxy for secure routing and serves files.
- **Grafana, Loki, Promtail**: Self-hosted logging and alerting pipeline.
- **Prometheus, Node Exporter, cAdvisor**: System metrics and monitoring dashboard etc.
- **AWS EC2**: Deployed on a cloud virtual machine.
- **Gmail SMTP**: Configured alerting via Grafana email notifications that can send alerts to configurable email addresses!

---
