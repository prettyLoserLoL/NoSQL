db = db.getSiblingDB("edu_db1");
print("... Запуск нагрузки ...");
for (let i = 0; i < 100000; i++) {
    db.load_test.insertOne({ name: "Sofia", val: i, date: new Date() });
    if (i % 10000 === 0) print("Записано " + i + " документов");
}
print("Нагрузка завершена!");