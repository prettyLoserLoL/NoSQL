const database = db.getSiblingDB("edu_db1");
let passed = true;

print("--- Проверка прав доступа для пользователя ---");

// 1. Пробуем прочитать разрешенную коллекцию (products)
try {
    const docs = database.products.find().toArray();
    print(`Чтение разрешено. Найдено документов: ${docs.length}`);
} catch (error) {
    print(`Не удалось прочитать разрешенную коллекцию: ${error.message}`);
    passed = false;
}

// 2. Пробуем прочитать ЗАПРЕЩЕННУЮ коллекцию (restricted_info)
print("\nПроверка попытки доступа к защищенной коллекции restricted_info:");
try {
    database.restricted_info.find().toArray();
    print("Доступ к запрещенной коллекции почему-то РАЗРЕШЕН.");
    passed = false;
} catch (error) {
    // Код ошибки 13 — это Unauthorized в MongoDB
    if (error.code === 13 || error.message.includes("not authorized")) {
        print(" Доступ запрещен (Unauthorized). Система безопасности работает.");
    } else {
        print(` Возникла непредвиденная ошибка: ${error.message}`);
        passed = false;
    }
}

if (!passed) {
    print("\nПроверка безопасности ПРОВАЛЕНА.");
    quit(1);
} else {
    print("\nВсе тесты безопасности пройдены успешно.");
}