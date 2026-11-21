# Monitoring Guide

Prometheus scrapes the Flask `/metrics` endpoint every five seconds. Grafana provisions its datasource and “DevSecOps Application Overview” dashboard automatically. Use the runtime URLs printed by `bash status.sh`, because conflicts may move Grafana or the application to the next free port. Confirm `UP` at Prometheus `/targets` before presenting charts.
