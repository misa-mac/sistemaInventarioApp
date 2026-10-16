const bcrypt = require('bcrypt');
const { sequelize, connectDB } = require('../database');
const Usuario = require('../src/models/Usuario');

async function seedUser() {
  const users = [
    { email: 'misa@gmail.com', password: '123456789', nombre_completo: 'Misael Admin', rol: 'admin' },
    { email: 'tecnico@itbm.edu.bo', password: '123456789', nombre_completo: 'Carlos Técnico', rol: 'tecnico' },
    { email: 'auditor@itbm.edu.bo', password: '123456789', nombre_completo: 'Ana Auditora', rol: 'auditor' },
    { email: 'auditor2@itbm.edu.bo', password: '123456789', nombre_completo: 'Luis Auditor Secundario', rol: 'auditor' }
  ];

  try {
    await connectDB();
    
    for (const u of users) {
      const hash = await bcrypt.hash(u.password, 10);
      const [user, created] = await Usuario.findOrCreate({
        where: { email: u.email },
        defaults: {
          email: u.email,
          password_hash: hash,
          nombre_completo: u.nombre_completo,
          rol: u.rol,
          activo: true
        }
      });

      if (!created) {
        user.password_hash = hash;
        user.rol = u.rol;
        user.activo = true;
        await user.save();
      }
      console.log(`✅ Usuario ${created ? 'creado' : 'actualizado'}: ${u.email} (${u.rol})`);
    }
  } catch (error) {
    console.error('❌ Error procesando el usuario:', error);
  } finally {
    await sequelize.close();
    console.log('Conexión cerrada.');
  }
}

seedUser();
