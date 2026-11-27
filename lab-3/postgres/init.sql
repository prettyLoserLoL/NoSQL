-- 1. Справочник отделений
CREATE TABLE IF NOT EXISTS departments (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL
);

INSERT INTO departments (name) VALUES 
('Хирургическое отделение'),
('Кардиологическое отделение'),
('Терапевтическое отделение'),
('Отделение анестезиологии и реанимации');

-- 2. Справочник врачей
CREATE TABLE IF NOT EXISTS doctors (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(200) NOT NULL,
    specialty VARCHAR(100) NOT NULL,
    department_id INT REFERENCES departments(id)
);

INSERT INTO doctors (full_name, specialty, department_id) VALUES
('Хирургов Иван Иванович', 'Хирург самой высшей категории', 1),
('Кадиологиева Елена Еленовна', 'Кардиолог от бога', 2),
('Терапевтов Егор Егорович', 'Терапевт обыкновенный', 3),
('Человеков Дмитрий Альбертович', 'Анестезиолог-реаниматолог', 4);

-- 3. Пациенты стационара
CREATE TABLE IF NOT EXISTS patients (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(200) NOT NULL,
    oms_policy VARCHAR(16) UNIQUE NOT NULL,
    birth_date DATE NOT NULL,
    blood_group VARCHAR(10) NOT NULL,
    allergies TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Генерация 500 пациентов
INSERT INTO patients (full_name, oms_policy, birth_date, blood_group, allergies)
SELECT 
    'Пациент №' || i,
    LPAD(i::text, 16, '0'),
    DATE '1950-01-01' + (i * 45 % 25000)::integer,
    (ARRAY['O(I) Rh+', 'A(II) Rh+', 'B(III) Rh+', 'AB(IV) Rh+', 'O(I) Rh-', 'A(II) Rh-'])[1 + (i % 6)],
    CASE 
        WHEN i % 5 = 0 THEN 'Пенициллин, Новокаин'
        WHEN i % 7 = 0 THEN 'Аспирин'
        ELSE 'Не отягощен'
    END
FROM generate_series(1, 500) AS i;

-- 4. Активные госпитализации
CREATE TABLE IF NOT EXISTS admissions (
    id SERIAL PRIMARY KEY,
    patient_id INT REFERENCES patients(id) ON DELETE CASCADE,
    department_id INT REFERENCES departments(id),
    doctor_id INT REFERENCES doctors(id),
    admitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    diagnosis VARCHAR(255) NOT NULL
);

INSERT INTO admissions (patient_id, department_id, doctor_id, diagnosis)
SELECT 
    i,
    1 + (i % 4),
    1 + (i % 4),
    (ARRAY['Острая нехватка чипсеков', 'Зубодробительная болезнь сердца', 'Это вообще непонятно что', 'Пубертат'])[1 + (i % 4)]
FROM generate_series(1, 500) AS i;

-- 5. Процедуры и операции
CREATE TABLE IF NOT EXISTS procedures (
    id SERIAL PRIMARY KEY,
    admission_id INT REFERENCES admissions(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    scheduled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'Назначено'
);

INSERT INTO procedures (admission_id, name, status)
SELECT 
    i,
    (ARRAY['Просмотр тиктока', 'Уколы в попу', 'Поменьше думанья', 'Глаженье кошечек'])[1 + (i % 4)],
    'Выполнено'
FROM generate_series(1, 500) AS i;

-- 6. Лекарственные назначения
CREATE TABLE IF NOT EXISTS prescriptions (
    id SERIAL PRIMARY KEY,
    admission_id INT REFERENCES admissions(id) ON DELETE CASCADE,
    medication_name VARCHAR(150) NOT NULL,
    dosage VARCHAR(100) NOT NULL,
    frequency VARCHAR(100) NOT NULL
);

INSERT INTO prescriptions (admission_id, medication_name, dosage, frequency)
SELECT 
    i,
    (ARRAY['Аскорбинки', 'Чипсеки', 'Активированный уголь', 'Подорожник'])[1 + (i % 4)],
    '1.0 г',
    '2 раза в сутки'
FROM generate_series(1, 500) AS i;
