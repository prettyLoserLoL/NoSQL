import urllib.request
import time
import random
import concurrent.futures

BASE_URL = "http://localhost:8000/api/courses/"
POPULAR_IDS = [10, 20, 30, 42, 99, 105]

def send_request(course_id):
    start = time.time()
    try:
        req = urllib.request.urlopen(f"{BASE_URL}{course_id}")
        return req.getcode(), (time.time() - start) * 1000
    except Exception as e:
        return 500, (time.time() - start) * 1000

def run_load(duration_sec=60, workers=8):
    print(f"🚀 Запуск нагрузочного тестирования SofiaEdu на {duration_sec} секунд...")
    end_time = time.time() + duration_sec
    total_reqs = 0
    
    with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as executor:
        while time.time() < end_time:
            # 80% запросов идут на популярные курсы (Cache Hit), 20% - на случайные (Cache Miss)
            if random.random() < 0.8:
                c_id = random.choice(POPULAR_IDS)
            else:
                c_id = random.randint(1, 1000)
                
            executor.submit(send_request, c_id)
            total_reqs += 1
            time.sleep(0.01)

    print(f"✅ Нагрузка завершена! Отправлено ~{total_reqs} запросов.")

if __name__ == "__main__":
    run_load(duration_sec=60)
