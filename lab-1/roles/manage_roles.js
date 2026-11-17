db = db.getSiblingDB("edu_db1");

// Назначаем роль пользователю
db.grantRolesToUser("sofia_user1", ["productReader"]);
print("Роль productReader назначена пользователю sofia_user1");

// Изменяем набор операций у роли (Пункт 2.4)
db.updateRole("productReader", {
  privileges: [
    { resource: { db: "edu_db1", collection: "products" }, actions: ["find", "insert"] }
  ]
});
print("Права роли productReader обновлены :)");