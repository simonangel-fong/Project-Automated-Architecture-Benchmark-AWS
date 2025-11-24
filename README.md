# Project-IOT-Mgnt-Telemetry-Cloud-Native

- [Solution: Baseline](./doc/baseline/baseline.md)

| Solution | Design                               | Tune                 |
| -------- | ------------------------------------ | -------------------- |
| Baseline | ECS(FastAPI){1 cpu}+RDS{4 cpu}       | NA                   |
| Tune-App | ECS(FastAPI){1 cpu}+RDS{4 cpu}       | pool+overflow+worker |
| Redis    | ECS(FastAPI){1 cpu}+Redis+RDS{4 cpu} | pool+overflow+worker |
