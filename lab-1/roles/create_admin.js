// мой главный
db = db.getSiblingDB("admin");
db.createUser({
  user: "adminSofia",
  pwd: "password123", 
  roles: [ { role: "root", db: "admin" } ]
});
print("Главный администратор adminSofia создан!");