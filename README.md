# Automation Network Benchmark

This repository provides scripts to benchmark **automation task registration** on the Supra network.
Benchmarking behavior is determined by **rounds**, **burst size**, and **task expiration durations**.

---

## 🔹 Task Registration Scenarios

### 1. Single Round, Single Task

```bash
--total-rounds 1 --burst-size 1
expirations=(3600 4200 4500)
```

* **3 tasks** are registered.
* Expirations: **60 min (3600s), 70 min (4200s), 75 min (4500s)**.
* One task per expiration.

---

### 2. Two Rounds, Single Task per Round

```bash
--total-rounds 2 --burst-size 1
expirations=(3600 4200 4500)
```

* **2 sets of 3 tasks** are registered.
* Each round registers tasks with expirations: **60, 70, and 75 minutes**.
* **Total tasks = 6**.

---

### 3. Two Rounds, Bursts of 10

```bash
--total-rounds 2 --burst-size 10
expirations=(3600 4200 4500)
```

* **2 sets of 3 bursts** are triggered.
* Each burst contains **10 tasks** (all with the same expiration).
* Expirations: **60, 70, and 75 minutes**.
* **Total tasks = 60 (2 × 3 expirations × 10 tasks)**.

---

## ⚙️ Configure Stress Tests

### 1. Transfer Task Stress Test

* Script:

  ```bash
  scripts/register_tasks.sh
  ```
* Run with:

  ```bash
  --static-payload-file-path ../data/automation_task_payload.json
  ```

---

### 2. Limit Order Task Stress Test

* Script:

  ```bash
  scripts/register_tasks.sh
  ```
* To execute **on every block**:

  ```bash
  --static-payload-file-path ../data/automation_limit_order_task_payload_success.json
  ```
* To **skip execution** on each block:

  ```bash
  --static-payload-file-path ../data/automation_limit_order_task_payload_fail.json
  ```

---

## 🚀 Running Stress Tests

1. Reset the network:

   ```bash
   scripts/reset_parallel.sh
   ```
2. Register tasks:

   ```bash
   scripts/register_tasks.sh
   ```

---

## 📊 Analyse Cycle Transition Time

1. Place `metrics.log` and `analyse_transition_time.py` in the same folder.
2. Run:

   ```bash
   python3 analyse_transition_time.py
   ```

---