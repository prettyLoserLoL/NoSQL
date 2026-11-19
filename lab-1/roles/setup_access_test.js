const database = db.getSiblingDB("edu_db1");

// Создаем документ в защищенной коллекции
database.restricted_info.updateOne(
    { _id: "secret_01" },
    { $setOnInsert: { message: "Данные только для администратора" } },
    { upsert: true }
);

print("Коллекция edu_db1.restricted_info подготовлена для теста безопасности.")