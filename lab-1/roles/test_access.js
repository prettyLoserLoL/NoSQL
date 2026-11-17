db = db.getSiblingDB("edu_db1");
try {
    print("Пробуем прочитать коллекцию products:");
    let doc = db.products.findOne();
    print("успешный успех! Данные: " + JSON.stringify(doc));
} catch (e) {
    print("Потеря потерь: нет доступа к products!");
}

try {
    print("Пробуем прочитать секретную базу admin:");
    db.getSiblingDB("admin").system.users.find().toArray();
} catch (e) {
    print("ОТКАЗАНО В ДОСТУПЕ(ожидаемо): у пользователя нет прав на системную базу.");
}