// Update with your config settings.

/**
 * @type { Object.<string, import("knex").Knex.Config> }
 */
module.exports = {
  development: {
    client: 'pg',
    connection: {
      host: '127.0.0.1',
      port: 5432,
      user: 'postgres',
      password: '5077379300', // pgAdmin'e girerken kullandığın şifre
      database: 'myteammate' // Ekran görüntüsündeki isimle birebir aynı olmalı
    },
    migrations: {
      directory: './src/database/migrations'
    }
  }
};