// Работа с первой базой
db = db.getSiblingDB("edu_db1");
db.createUser({
  user: "sofia_user1",
  pwd: "user1pass",
  roles: ["readWrite"]
});
db.products.insertOne({ name: "Ноутбук", price: 50000 });

// Работа со второй базой
db = db.getSiblingDB("edu_db2");
db.createUser({
  user: "sofia_user2",
  pwd: "user2pass",
  roles: ["read"]
});
db.products.insertOne({ name: "Мышка", price: 1500 });

print("Учебные базы и пользователи созданы!");