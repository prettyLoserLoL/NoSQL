const db1 = db.getSiblingDB("edu_db1");
const db2 = db.getSiblingDB("edu_db2");

// Удаляем роль
if (db1.getRole("productReader")) {
    db1.dropRole("productReader");
    print("Роль productReader удалена.");
}

// Удаляем пользователя
if (db1.getUser("sofia_user1")) {
    db1.dropUser("sofia_user1");
    print("Пользователь sofia_user1 удален.");
}

print("\nПроверка после удаления:");
print("Роль productReader:", db1.getRole("productReader"));
print("Пользователь sofia_user1:", db1.getUser("sofia_user1"));