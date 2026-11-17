db = db.getSiblingDB("edu_db1");

// Роль только для чтения коллекции products
db.createRole({
  role: "productReader",
  privileges: [
    { resource: { db: "edu_db1", collection: "products" }, actions: ["find"] }
  ],
  roles: []
});

print("Роль productReader создана!");