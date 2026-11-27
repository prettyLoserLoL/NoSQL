import urllib.request
import urllib.error
import json
import time
import statistics
import random

BASE_URL = "http://localhost:8000/api/patients"

def http_get(url):
    req = urllib.request.Request(url, method="GET")
    with urllib.request.urlopen(req, timeout=10) as resp:
        return resp.status, resp.read()

def http_delete(url):
    req = urllib.request.Request(url, method="DELETE")
    with urllib.request.urlopen(req, timeout=10) as resp:
        return resp.status, resp.read()

def http_post_json(url, payload):
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST"
    )
    with urllib.request.urlopen(req, timeout=10) as resp:
        return resp.status, resp.read()

def test_cache_hits(patient_id=17, n_requests=300):
    # Разогрев (Warm up)
    http_get(f"{BASE_URL}/{patient_id}/summary")
    
    latencies = []
    start_total = time.perf_counter()
    for _ in range(n_requests):
        t0 = time.perf_counter()
        http_get(f"{BASE_URL}/{patient_id}/summary")
        t1 = time.perf_counter()
        latencies.append((t1 - t0) * 1000)
    total_time = time.perf_counter() - start_total
    
    return {
        "name": "Redis Cache HIT (Hot Cache)",
        "requests": len(latencies),
        "total_time_s": total_time,
        "rps": len(latencies) / total_time,
        "avg_ms": statistics.mean(latencies),
        "p95_ms": statistics.quantiles(latencies, n=20)[18] if len(latencies) >= 20 else max(latencies),
        "min_ms": min(latencies),
        "max_ms": max(latencies)
    }

def test_cache_misses(patient_id=17, n_requests=50):
    latencies = []
    start_total = time.perf_counter()
    for _ in range(n_requests):
        # Удаляем ключ из Redis, чтобы принудительно заставить систему идти в PostgreSQL
        http_delete(f"{BASE_URL}/{patient_id}/cache")
        t0 = time.perf_counter()
        http_get(f"{BASE_URL}/{patient_id}/summary")
        t1 = time.perf_counter()
        latencies.append((t1 - t0) * 1000)
    total_time = time.perf_counter() - start_total
    
    return {
        "name": "PostgreSQL Direct / Cache MISS",
        "requests": len(latencies),
        "total_time_s": total_time,
        "rps": len(latencies) / total_time,
        "avg_ms": statistics.mean(latencies),
        "p95_ms": statistics.quantiles(latencies, n=20)[18] if len(latencies) >= 20 else max(latencies),
        "min_ms": min(latencies),
        "max_ms": max(latencies)
    }

def generate_grafana_traffic(n_requests=150):
    print("\n[3/3] Генерация смешанной активности для дашборда Grafana...")
    meds = ["Парацетамол", "Ибупрофен", "Морфин 1%", "Аспирин Кардио"]
    for i in range(n_requests):
        p_id = random.choice([15, 16, 17, 18, 19, 20])
        # 85% чтения
        http_get(f"{BASE_URL}/{p_id}/summary")
        # 15% записей (инвалидация)
        if i % 7 == 0:
            http_post_json(
                f"{BASE_URL}/{p_id}/prescriptions",
                {"medication_name": random.choice(meds), "dosage": "1 таб", "frequency": "1 р/д"}
            )
        time.sleep(0.03)

def main():
    print("=" * 68)
    print("ГБУЗ «ОКБ» — НАГРУЗОЧНОЕ ТЕСТИРОВАНИЕ REDIS CACHE-ASIDE")
    print("=" * 68)
    
    print("\n[1/3] Запуск теста Cache MISS (PostgreSQL DB Query)...")
    miss_res = test_cache_misses(patient_id=17, n_requests=50)
    
    print("[2/3] Запуск теста Cache HIT (Redis In-Memory Key)...")
    hit_res = test_cache_hits(patient_id=17, n_requests=300)
    
    print("\n" + "=" * 68)
    print(" РЕЗУЛЬТАТЫ СРАВНЕНИЯ ПРОИЗВОДИТЕЛЬНОСТИ")
    print("=" * 68)
    print(f"{'Метрика':<25} | {'Direct DB (MISS)':<18} | {'Redis (HIT)':<18}")
    print("-" * 68)
    print(f"{'Запросов (кол-во)':<25} | {miss_res['requests']:<18} | {hit_res['requests']:<18}")
    print(f"{'Пропускная способность':<25} | {miss_res['rps']:<12.2f} req/s | {hit_res['rps']:<12.2f} req/s")
    print(f"{'Средняя задержка (Avg)':<25} | {miss_res['avg_ms']:<15.2f} ms | {hit_res['avg_ms']:<15.2f} ms")
    print(f"{'p95 задержка':<25} | {miss_res['p95_ms']:<15.2f} ms | {hit_res['p95_ms']:<15.2f} ms")
    print(f"{'Мин / Макс задержка':<25} | {miss_res['min_ms']:.1f} / {miss_res['max_ms']:.1f} ms | {hit_res['min_ms']:.1f} / {hit_res['max_ms']:.1f} ms")
    print("-" * 68)
    speedup = miss_res['avg_ms'] / hit_res['avg_ms'] if hit_res['avg_ms'] > 0 else 0
    print(f" Ускорение обработки запроса (Speedup): в {speedup:.1f}x раз(а) быстрее с Redis!")
    print("=" * 68)
    
    generate_grafana_traffic(150)
    print("\n Тестирование завершено!")

if __name__ == "__main__":
    main()
