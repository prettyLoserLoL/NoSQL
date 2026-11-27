import os
import json
import time
import psycopg2
from psycopg2.extras import RealDictCursor
import redis
from fastapi import FastAPI, HTTPException, Response
from pydantic import BaseModel
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST

app = FastAPI(title="Sofia Hospital Inpatient Service (Cache-Aside)")

# Параметры подключения
PG_HOST = os.getenv("PG_HOST", "sofia-postgres")
PG_PORT = os.getenv("PG_PORT", "5432")
PG_DB = os.getenv("PG_DB", "sofia_hospital_db")
PG_USER = os.getenv("PG_USER", "sofia_doctor")
PG_PASS = os.getenv("PG_PASS", "SofiaHospital2026!")

REDIS_HOST = os.getenv("REDIS_HOST", "sofia-redis")
REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))
REDIS_PASSWORD = os.getenv("REDIS_PASSWORD", "SofiaRedis2026!")
CACHE_TTL = int(os.getenv("CACHE_TTL", "120"))

# Prometheus Метрики
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP Requests', ['endpoint', 'status'])
CACHE_HITS = Counter('cache_hits_total', 'Total Redis Cache Hits')
CACHE_MISSES = Counter('cache_misses_total', 'Total Redis Cache Misses')
REQUEST_LATENCY = Histogram('request_latency_seconds', 'Request latency in seconds', ['cache_status'])

def get_db():
    return psycopg2.connect(
        host=PG_HOST, port=PG_PORT, dbname=PG_DB, user=PG_USER, password=PG_PASS
    )

def get_redis():
    return redis.Redis(
        host=REDIS_HOST, port=REDIS_PORT, password=REDIS_PASSWORD, decode_responses=True, socket_timeout=1.0
    )

redis_client = get_redis()

class PrescriptionCreate(BaseModel):
    medication_name: str
    dosage: str
    frequency: str

@app.get("/metrics")
def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)

# 1. Получение сводной карты пациента (Cache-Aside)
@app.get("/api/patients/{patient_id}/summary")
def get_patient_summary(patient_id: int):
    start_time = time.time()
    cache_key = f"patient:{patient_id}:summary"
    
    # Шаг 1: Проверка в Redis
    try:
        cached = redis_client.get(cache_key)
        if cached:
            CACHE_HITS.inc()
            latency = time.time() - start_time
            REQUEST_LATENCY.labels(cache_status="hit").observe(latency)
            REQUEST_COUNT.labels(endpoint="/api/patients/summary", status="200").inc()
            return {
                "source": "cache",
                "latency_ms": round(latency * 1000, 2),
                "patient_summary": json.loads(cached)
            }
    except Exception as e:
        print(f"Redis unavailable, fallback to DB: {e}")

    # Шаг 2: Cache Miss -> Запрос к PostgreSQL
    CACHE_MISSES.inc()
    try:
        conn = get_db()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        # Эмуляция тяжелого аналитического запроса (20мс) по многотабличному стационару
        cur.execute("SELECT pg_sleep(0.02);")
        
        # Сборка профиля пациента со связями
        query = """
            SELECT 
                p.id, p.full_name, p.oms_policy, p.birth_date::text, p.blood_group, p.allergies,
                a.id as admission_id, a.diagnosis, a.admitted_at::text,
                d.name as department,
                doc.full_name as attending_doctor, doc.specialty as doctor_specialty
            FROM patients p
            LEFT JOIN admissions a ON a.patient_id = p.id
            LEFT JOIN departments d ON a.department_id = d.id
            LEFT JOIN doctors doc ON a.doctor_id = doc.id
            WHERE p.id = %s
        """
        cur.execute(query, (patient_id,))
        patient_base = cur.fetchone()

        if not patient_base:
            cur.close()
            conn.close()
            REQUEST_COUNT.labels(endpoint="/api/patients/summary", status="404").inc()
            raise HTTPException(status_code=404, detail="Patient not found")

        admission_id = patient_base["admission_id"]

        # Получаем процедуры
        cur.execute("SELECT name, status, scheduled_at::text FROM procedures WHERE admission_id = %s", (admission_id,))
        procedures = cur.fetchall()

        # Получаем назначения
        cur.execute("SELECT medication_name, dosage, frequency FROM prescriptions WHERE admission_id = %s", (admission_id,))
        prescriptions = cur.fetchall()

        cur.close()
        conn.close()

        summary_data = {
            "patient": patient_base,
            "procedures": procedures,
            "prescriptions": prescriptions
        }
    except Exception as e:
        REQUEST_COUNT.labels(endpoint="/api/patients/summary", status="500").inc()
        raise HTTPException(status_code=500, detail=str(e))

    # Шаг 3: Сохранение в Redis
    try:
        redis_client.setex(cache_key, CACHE_TTL, json.dumps(summary_data))
    except Exception as e:
        print(f"Failed to cache data: {e}")

    latency = time.time() - start_time
    REQUEST_LATENCY.labels(cache_status="miss").observe(latency)
    REQUEST_COUNT.labels(endpoint="/api/patients/summary", status="200").inc()

    return {
        "source": "database",
        "latency_ms": round(latency * 1000, 2),
        "patient_summary": summary_data
    }

# 2. Добавление назначения врачом (Демонстрация Write-Invalidate)
@app.post("/api/patients/{patient_id}/prescriptions")
def add_prescription(patient_id: int, item: PrescriptionCreate):
    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("SELECT id FROM admissions WHERE patient_id = %s ORDER BY admitted_at DESC LIMIT 1", (patient_id,))
    adm = cur.fetchone()
    if not adm:
        cur.close()
        conn.close()
        raise HTTPException(status_code=404, detail="Active admission not found")

    cur.execute(
        "INSERT INTO prescriptions (admission_id, medication_name, dosage, frequency) VALUES (%s, %s, %s, %s)",
        (adm["id"], item.medication_name, item.dosage, item.frequency)
    )
    conn.commit()
    cur.close()
    conn.close()

    # Инвалидация кэша
    cache_key = f"patient:{patient_id}:summary"
    try:
        redis_client.delete(cache_key)
    except Exception as e:
        print(f"Failed to invalidate cache: {e}")

    return {"status": "success", "message": f"Prescription added. Cache for patient {patient_id} invalidated."}

# 3. Ручной сброс кэша карты пациента
@app.delete("/api/patients/{patient_id}/cache")
def invalidate_cache(patient_id: int):
    cache_key = f"patient:{patient_id}:summary"
    redis_client.delete(cache_key)
    return {"message": f"Cache for patient {patient_id} explicitly cleared"}
